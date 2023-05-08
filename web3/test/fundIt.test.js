const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = ethers;

describe("FundItDeployer", function () {
  let FundItDeployerFactory, fundItDeployer, fundIt;
  let owner, addr1, addr2;
  const TITLE = "Test Campaign";
  const DESCRIPTION = "This is a test campaign";
  const TARGET = ethers.utils.parseEther("1");
  const DURATION = (30 * 24 * 60 * 60); // 30 days
  const IMAGE = "test_image";
  const OVERRIDE = { gasLimit: 2000000 };

  // Deploy and set up contracts before each test
  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const ProxyAdmin = await ethers.getContractFactory("@openzeppelin/contracts/proxy/transparent/ProxyAdmin");
    const TransparentUpgradeableProxy = await ethers.getContractFactory("@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy");
    
    FundItDeployerFactory = await ethers.getContractFactory("FundItDeployer");
    fundItDeployer = await FundItDeployerFactory.deploy();
    await fundItDeployer.deployed();

    // Get the deployed FundIt contract through the FundItDeployer contract
    const fundItAddress = await fundItDeployer.proxy();
    fundIt = await ethers.getContractAt("FundIt", fundItAddress);
  
    FundItFactory = await ethers.getContractFactory("FundIt");
    FundItStorageFactory = await ethers.getContractFactory("FundItStorage");
    FundItProxyFactory = await ethers.getContractFactory("FundItProxy");

    fundItStorage = await FundItStorageFactory.deploy();
    await fundItStorage.deployed();

    fundIt = await FundItFactory.deploy();
    await fundIt.deployed();

    const initPayload = fundIt.interface.encodeFunctionData("initialize", [fundItStorage.address]);
    fundItProxy = await FundItProxyFactory.deploy(fundIt.address, fundItStorage.address, initPayload);
    await fundItProxy.deployed();

    // Create a new instance of the FundIt contract using the proxy's address
    fundIt = FundItFactory.attach(fundItProxy.address);
  });

  // Test proper deployment of all contracts
  describe("Deployment", function () {
    it("Should deploy FundItStorage with the correct initial state", async function () {
      expect(await fundItStorage.numberOfCampaigns()).to.equal(0);
    });

    it("Should deploy FundItProxy with the correct initial state", async function () {
      const proxyAdmin = new ethers.Contract(fundItStorage.address, ProxyAdmin.abi, owner);
      expect(await proxyAdmin.getProxyAdmin(fundItProxy.address)).to.equal(fundItStorage.address);
      expect(await proxyAdmin.getProxyImplementation(fundItProxy.address)).to.equal(fundIt.address);
    });
  });

  // Test proper error handling
  describe("Error Handling", function () {
    beforeEach(async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
    });

    it("Should revert when donating to a non-existent campaign", async function () {
      const donationAmount = ethers.utils.parseEther("0.1");
      await expect(fundIt.connect(addr1).donateToCampaign(1, { value: donationAmount })).to.be.revertedWith("Campaign does not exist");
    });

    it("Should revert when withdrawing funds before the deadline", async function () {
      await expect(fundIt.connect(owner).withdrawFunds(0)).to.be.revertedWith("Cannot withdraw funds before the deadline");
    });

    it("Should revert when ending a campaign that has collected funds", async function () {
      await fundIt.connect(addr1).donateToCampaign(0, { value: TARGET });
      await expect(fundIt.connect(owner).endCampaign(0)).to.be.revertedWith("Cannot end a campaign that has collected funds");
    });

    it("Should revert when trying to withdraw funds from a non-existent campaign", async function () {
      await expect(fundIt.connect(owner).withdrawFunds(1)).to.be.revertedWith("Campaign does not exist");
    });

    it("Should revert when a non-owner tries to end a campaign", async function () {
      await expect(fundIt.connect(addr1).endCampaign(0)).to.be.revertedWith("Only the campaign owner can end the campaign");
    });
      
    it("Should revert when a non-owner tries to withdraw funds from a campaign", async function () {
      // Fast-forward to the deadline
      await ethers.provider.send("evm_increaseTime", [DURATION]);
      await ethers.provider.send("evm_mine");
      
      await expect(fundIt.connect(addr1).withdrawFunds(0)).to.be.revertedWith("Only the campaign owner can withdraw funds");
    });
  });

  // Test createCampaign function
  describe("Create Campaign", function () {
    it("Should create a new campaign", async function () {
      const tx = await fundIt.createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE);
      await tx.wait();
      const campaign = await fundIt.campaigns(0);

      expect(campaign.owner).to.equal(await ethers.provider.getSigner(0).getAddress());
      expect(campaign.title).to.equal(TITLE);
      expect(campaign.description).to.equal(DESCRIPTION);
      expect(campaign.target).to.equal(TARGET);
      expect(campaign.deadline).to.equal((await ethers.provider.getBlock("latest")).timestamp + DURATION);
      expect(campaign.image).to.equal(IMAGE);
      expect(campaign.active).to.equal(true);
    });
  });

  // Test donateToCampaign function
  describe("Donate to Campaign", function () {
    beforeEach(async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
    });

    it("Should allow users to make donations to the campaign", async function () {
      const donationAmount = ethers.utils.parseEther("0.1");
      await fundIt.connect(addr1).donateToCampaign(0, { value: donationAmount });
          
      const campaign = await fundIt.campaigns(0);
      expect(campaign.amountCollected).to.equal(donationAmount);
          
      const [donors, donations] = await fundIt.getCampaignDonors(0);
      expect(donors[0]).to.equal(addr1.address);
      expect(donations[0]).to.equal(donationAmount);
    });
  });

  // Test withdrawFunds function
  describe("Withdraw Funds", function () {
    beforeEach(async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
      await fundIt.connect(addr1).donateToCampaign(0, { value: TARGET });
    });

    it("Should allow the campaign owner to withdraw funds after the deadline", async function () {
      // Fast-forward to the deadline
      await ethers.provider.send("evm_increaseTime", [DURATION]);
      await ethers.provider.send("evm_mine");
          
      const initialBalance = await owner.getBalance();
      await fundIt.connect(owner).withdrawFunds(0);
          
      const campaign = await fundIt.campaigns(0);
      expect(campaign.active).to.be.false;
          
      const finalBalance = await owner.getBalance();
      expect(finalBalance).to.be.gt(initialBalance);
    });
  });

  // Test endCampaign function
  describe("End Campaign", function () {
    beforeEach(async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
    });
        
    it("Should allow the campaign owner to end the campaign if no funds were collected", async function () {
      await fundIt.connect(owner).endCampaign(0);
      const campaign = await fundIt.campaigns(0);
      expect(campaign.active).to.be.false;
    });
  });

  // Test getActiveCampaigns function
  describe("Get Active Campaigns", function () {
    beforeEach(async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
      await fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
    });

    it("Should return all active campaigns", async function () {
      const activeCampaigns = await fundIt.getActiveCampaigns();
      expect(activeCampaigns.length).to.equal(2);
    });
  });

  // Test getEndedCampaigns function
  describe("Get Ended Campaigns", function () {
    beforeEach(async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
      await fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
      // Fast-forward to the deadline
      await ethers.provider.send("evm_increaseTime", [DURATION]);
      await ethers.provider.send("evm_mine");
    });

    it("Should return all ended campaigns", async function () {
      const endedCampaigns = await fundIt.getEndedCampaigns();
      expect(endedCampaigns.length).to.equal(2);
    });
  });

  // Test getCampaignDonors function
  describe("Get Campaign Donors", function () {
    beforeEach(async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
      await fundIt.connect(addr1).donateToCampaign(0, { value: ethers.utils.parseEther("0.1") });
      await fundIt.connect(addr2).donateToCampaign(0, { value: ethers.utils.parseEther("0.2") });
    });

    it("Should return all donors and their donations for a campaign", async function () {
      const [donors, donations] = await fundIt.getCampaignDonors(0);
      expect(donors.length).to.equal(2);
      expect(donors[0]).to.equal(addr1.address);
      expect(donors[1]).to.equal(addr2.address);
      expect(donations[0]).to.equal(ethers.utils.parseEther("0.1"));
      expect(donations[1]).to.equal(ethers.utils.parseEther("0.2"));
    });
  });
});
