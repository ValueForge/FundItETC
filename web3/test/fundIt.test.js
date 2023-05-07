const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = ethers;

describe("FundIt", function () {
  let FundItFactory, fundIt, FundItStorageFactory, fundItStorage, FundItProxyFactory, fundItProxy;

  beforeEach(async function () {
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

  describe("Create Campaign", function () {
    it("Should create a new campaign", async function () {
      const tx = await fundIt.createCampaign("Test Campaign", "This is a test campaign", ethers.utils.parseEther("1"), 30, "test_image");
      await tx.wait();

      const campaign = await fundIt.campaigns(0);

      expect(campaign.owner).to.equal(await ethers.provider.getSigner(0).getAddress());
      expect(campaign.title).to.equal("Test Campaign");
      expect(campaign.description).to.equal("This is a test campaign");
      expect(campaign.target).to.equal(ethers.utils.parseEther("1"));
      expect(campaign.deadline).to.equal((await ethers.provider.getBlock("latest")).timestamp + 30 * 24 * 60 * 60);
      expect(campaign.image).to.equal("test_image");
      expect(campaign.active).to.equal(true);
    });
  });

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

  describe("Withdraw Funds", function () {
    beforeEach(async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
      await fundIt.connect(addr1).donateToCampaign(0, { value: TARGET });
    });

    it("Should allow the campaign owner to withdraw funds after the deadline", async function () {
      // Fast-forward to the deadline
      await ethers.provider.send("evm_increaseTime", [DURATION * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine");

      const initialBalance = await owner.getBalance();
      await fundIt.connect(owner).withdrawFunds(0);

      const campaign = await fundIt.campaigns(0);
      expect(campaign.active).to.be.false;

      const finalBalance = await owner.getBalance();
      expect(finalBalance).to.be.gt(initialBalance);
    });
  });

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

  describe("Get Ended Campaigns", function () {
    beforeEach(async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);
      await fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);

      // Fast-forward to the deadline
      await ethers.provider.send("evm_increaseTime", [DURATION * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine");
    });

    it("Should return all ended campaigns", async function () {
      const endedCampaigns = await fundIt.getEndedCampaigns();
      expect(endedCampaigns.length).to.equal(2);
    });
  });
});
