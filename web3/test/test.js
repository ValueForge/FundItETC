// Import required modules
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { deployContracts } = require("../scripts/deploy");
const { BigNumber } = ethers;
const { BN, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const ProxyAdmin = require('@openzeppelin/contracts/build/contracts/ProxyAdmin.json');
const ProxyAdminABI = require("@openzeppelin/contracts/build/contracts/ProxyAdmin.json").abi;

// Define contract variables
let FundItDeployerFactory, FundItFactory, FundItStorageFactory, FundItProxyFactory, IFundItFactory;
let fundItDeployer, fundIt, fundItStorage, fundItProxy, iFundIt;
let owner, addr1, addr2;
let contracts;

// Define campaign constants
const TITLE = "Test Campaign";
const DESCRIPTION = "This is a test campaign";
const TARGET = ethers.utils.parseEther("1");
const DURATION = 30
const IMAGE = "test_image";
const OVERRIDE = { gasLimit: 100000 };

/**
 * @title FundIt Test Suite
 * @dev Comprehensive test suite for the FundIt, FundItStorage, FundItProxy, and FundItDeployer contracts.
 */

describe("Deployment", async function () {
  contracts = await deployContracts();
  console.log(ethers.getSigners());
  [owner, addr1, addr2] = ethers.getSigners();

  /**
  * @dev Test case to check that the contracts are deployed correctly.
   */
  it("Should deploy correctly", async function () {
    expect(await contracts.fundIt.address).to.exist;
    expect(await contracts.fundItStorage.address).to.exist;
    expect(await contracts.fundItProxy.address).to.exist;
    expect(await contracts.fundItDeployer.address).to.exist;
  });

  it("Should deploy all contracts without errors", async function () {
    expect(await contracts.fundItStorage).to.be.ok;
    expect(await contracts.fundIt).to.be.ok;
    expect(await contracts.fundItDeployer).to.be.ok;
    expect(await contracts.fundItProxy).to.be.ok;

  /**
   * @dev Test case to check that the contracts are initialized correctly.
   */
  it("Should initialize all contracts correctly", async function () {
    // Checks for the initialization of each contract
    expect(await contracts.fundItStorage.getNumberOfCampaigns()).to.equal(0);
    expect(await contracts.fundItStorage.owner).to.equal(contracts.fundItProxy.address);
    expect(await contracts.fundIt.owner).to.equal(contracts.fundItProxy.address);
    expect(await contracts.fundItDeployer.owner).to.equal(ethers.getSigners(0));
    expect(await contracts.fundIt._storage).to.equal(contracts.fundItStorage.address);
  });
});
});

/**
 * @title FundIt Contract Tests
 * @dev Test suite for the FundIt contract.
 */
describe("FundIt", function () {
  
  it("Should create a new campaign struct", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE);
    const campaign = await contracts.fundItStorage.getCampaign(0);
    expect(campaign.title).to.equal(TITLE);
    expect(campaign.description).to.equal(DESCRIPTION);
    expect(campaign.target).to.equal(TARGET);
    expect(campaign.duration).to.equal(DURATION);
    expect(campaign.image).to.equal(IMAGE);
  });

  it("Should not allow a campaign to be created with a target of 0", async function () {
    await expect(contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, 0, DURATION, IMAGE)).to.be.revertedWith("Target must be greater than 0");
  });

  it("Should not allow a campaign to be created with a duration of 0", async function () {
    await expect(contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 0, IMAGE)).to.be.revertedWith("Duration must be greater than 0");
  });

  it("Should not allow a campaign to be created with a duration greater than 180 days", async function () {
    await expect(contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 181, IMAGE)).to.be.revertedWith("Duration must be less than 180 days");
  });

  it("Should donate to a campaign", async function () {
    await contracts.fundIt.connect(addr2).donateToCampaign(0, { value: ethers.utils.parseEther("0.5") });
    const campaign = await contracts.fundItStorage.getCampaign(0);
    expect(campaign.amountRaised).to.equal(ethers.utils.parseEther("0.5"));
  });

  it("Should not allow donations to a non-existent campaign", async function () {
    await expect(contracts.fundIt.connect(addr2).donateToCampaign(100, { value: ethers.utils.parseEther("0.5") })).to.be.revertedWith("Campaign does not exist");
  });

  it("Should not allow donations to a campaign that has ended", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 0, IMAGE);
    await expect(contacts.fundIt.connect(addr2).donateToCampaign(1, { value: ethers.utils.parseEther("0.5") })).to.be.revertedWith("Campaign has ended");
  });

  it("Should not allow donations to a campaign that has reached its target", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, ethers.utils.parseEther("0.5"), 30, IMAGE);
    await contracts.fundIt.connect(addr2).donateToCampaign(2, { value: ethers.utils.parseEther("0.5") });
    await expect(contacts.fundIt.connect(addr2).donateToCampaign(2, { value: ethers.utils.parseEther("0.5") })).to.be.revertedWith("Campaign has reached its target");
  });

  it("Should not allow donations of 0", async function () {
    await expect(contracts.fundIt.connect(addr2).donateToCampaign(0, { value: 0 })).to.be.revertedWith("Donation must be greater than 0");
  });

  it("Should allow the owner to end the campaign", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 30, IMAGE);
    await contracts.fundIt.connect(addr2).donateToCampaign(3, { value: ethers.utils.parseEther("0.5") });
    await contracts.fundIt.connect(addr1).endCampaign(3);
    const campaign = await contracts.fundItStorage.getCampaign(3);
    expect(campaign.ended).to.equal(true);
  });

  it("Should not allow a non-owner to end the campaign", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 30, IMAGE);
    await contracts.fundIt.connect(addr2).donateToCampaign(4, { value: ethers.utils.parseEther("0.5") });
    await expect(contracts.fundIt.connect(addr2).endCampaign(4)).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not allow a campaign to be ended if it has already ended", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 0, IMAGE);
    await contracts.fundIt.connect(addr2).donateToCampaign(5, { value: ethers.utils.parseEther("0.5") });
    await contracts.fundIt.connect(addr1).endCampaign(5);
    await expect(contracts.fundIt.connect(addr1).endCampaign(5)).to.be.revertedWith("Campaign has ended");
  });

  it("Should allow the campaign creator to withdraw funds from the campaign", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 0, IMAGE);
    await contracts.fundIt.connect(addr2).donateToCampaign(6, { value: ethers.utils.parseEther("0.5") });
    await contracts.fundIt.connect(addr1).endCampaign(6);
    await contracts.fundIt.connect(addr1).withdrawFunds(6);
    const campaign = await contracts.fundItStorage.getCampaign(6);
    expect(campaign.amountRaised).to.equal(0);
  });

  it("Should not allow a non-owner to withdraw funds from the campaign", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 0, IMAGE);
    await contracts.fundIt.connect(addr2).donateToCampaign(7, { value: ethers.utils.parseEther("0.5") });
    await contracts.fundIt.connect(addr1).endCampaign(7);
    await expect(contracts.fundIt.connect(addr2).withdrawFunds(7)).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not allow the campaign creator to withdraw funds from the campaign if it has not ended", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 30, IMAGE);
    await contracts.fundIt.connect(addr2).donateToCampaign(8, { value: ethers.utils.parseEther("0.5") });
    await expect(contracts.fundIt.connect(addr1).withdrawFunds(8)).to.be.revertedWith("Campaign has not ended");
  });

  it("Should not allow the campaign creator to withdraw funds from the campaign if it has already been withdrawn", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, 0, IMAGE);
    await contracts.fundIt.connect(addr2).donateToCampaign(9, { value: ethers.utils.parseEther("0.5") });
    await contracts.fundIt.connect(addr1).endCampaign(9);
    await contracts.fundIt.connect(addr1).withdrawFunds(9);
    await expect(contracts.fundIt.connect(addr1).withdrawFunds(9)).to.be.revertedWith("Funds have already been withdrawn");
  });

  it("Should allow the contract owner to pause contract execution", async function () {
    await contracts.fundIt.connect(addr1).pause();
    expect(await contracts.fundIt.paused()).to.equal(true);
  });

  it("Should not allow a non-owner to pause contract execution", async function () {
    await expect(contracts.fundIt.connect(addr2).pause()).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should allow the contract owner to unpause contract execution", async function () {
    await contracts.fundIt.connect(addr1).pause();
    await contracts.fundIt.connect(addr1).unpause();
    expect(await contracts.fundIt.paused()).to.equal(false);
  });

  it("Should not allow a non-owner to unpause contract execution", async function () {
    await contracts.fundIt.connect(addr1).pause();
    await expect(contracts.fundIt.connect(addr2).unpause()).to.be.revertedWith("Ownable: caller is not the owner");
  });
});

/**
   * @title FundItStorage Contract Tests
   * @dev Test suite for the FundItStorage contract.
   */
  describe("FundItStorage", function () {
    // Add tests for the FundItStorage contract
  it("Should add a new campaign to the campaigns array", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE);
    const campaign = await contracts.fundItStorage.getCampaign(0);
    expect(campaign.title).to.equal(TITLE);
    expect(campaign.description).to.equal(DESCRIPTION);
    expect(campaign.target).to.equal(TARGET);
    expect(campaign.duration).to.equal(DURATION);
    expect(campaign.image).to.equal(IMAGE);
  });

  it("Should keep a count of the number of campaigns", async function () {
    await contracts.fundIt.connect(addr1).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE);
    expect(await contracts.fundItStorage.getNumberOfCampaigns()).to.equal(1);
  });

  it("Should update the campaign struct when a donation is made", async function () {
    await contracts.fundIt.connect(addr2).donateToCampaign(0, { value: ethers.utils.parseEther("0.5") });
    const campaign = await contracts.fundItStorage.getCampaign(0);
    expect(campaign.amountRaised).to.equal(ethers.utils.parseEther("0.5"));
  });

  it("Should add a new donation to the donations array", async function () {
    await contracts.fundIt.connect(addr2).donateToCampaign(0, { value: ethers.utils.parseEther("0.5") });
    const donation = await contracts.fundItStorage.getDonation(0);
    expect(donation.campaignId).to.equal(0);
    expect(donation.donor).to.equal(addr2.address);
    expect(donation.amount).to.equal(ethers.utils.parseEther("0.5"));
  });

  /**
   * @title FundItProxy Contract Tests
   * @dev Test suite for the FundItProxy contract.
   */
  describe("FundItProxy", function () {
    // Add tests for the FundItProxy contract
    it("Should allow the owner to upgrade the contract", async function () {
      const FundItV2 = await ethers.getContractFactory("FundItV2");
      const fundItV2 = await FundItV2.deploy();
      await fundItV2.deployed();
      await contracts.fundItProxy.upgradeTo(fundItV2.address);
      expect(await contracts.fundItProxy.implementation()).to.equal(fundItV2.address);
    });

    it("Should not allow a non-owner to upgrade the contract", async function () {
      const FundItV2 = await ethers.getContractFactory("FundItV2");
      const fundItV2 = await FundItV2.deploy();
      await fundItV2.deployed();
      await expect(contracts.fundItProxy.connect(addr2).upgradeTo(fundItV2.address)).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  /**
   * @title FundItDeployer Contract Tests
   * @dev Test suite for the FundItDeployer contract.
   */
  describe("FundItDeployer", function () {
    // Add tests for the FundItDeployer contract
    it("Should deploy a new FundIt contract", async function () {
      const FundItFactory = await ethers.getContractFactory("FundIt");
      const fundIt = await FundItFactory.deploy(contracts.fundItStorage.address);
      await fundIt.deployed();
      expect(fundIt.address).to.exist;
    });
  });

  // Add more tests as needed
});
