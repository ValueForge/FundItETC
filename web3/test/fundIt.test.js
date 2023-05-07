const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = ethers;

describe("FundIt", function () {
  let FundIt, fundIt, FundItProxy, fundItProxy, owner, addr1, addr2, addrs;

  const TITLE = "Test Campaign";
  const DESCRIPTION = "A test campaign for donations";
  const TARGET = ethers.utils.parseEther("1");
  const DURATION = 7;
  const IMAGE = "https://example.com/image.jpg";
  const OVERRIDE = { gasLimit: 10000000 };

  beforeEach(async function () {
    // Deploy FundIt contract
    FundIt = await ethers.getContractFactory("FundIt");
    fundIt = await FundIt.deploy();
    await fundIt.deployed();

    // Deploy FundItProxy contract
    FundItProxy = await ethers.getContractFactory("FundItProxy");
    fundItProxy = await FundItProxy.deploy(fundIt.address, owner.address, [], OVERRIDE);
    await fundItProxy.deployed();

    // Get signers
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // Initialize the FundIt contract through the proxy
    const initializeData = fundIt.interface.encodeFunctionData("initialize", [fundIt.address]);
    await fundItProxy.connect(owner).upgradeToAndCall(fundIt.address, initializeData, OVERRIDE);

    // Attach the proxy contract to the FundIt instance
    fundIt = await ethers.getContractAt("FundIt", fundItProxy.address);
  });

  describe("Create Campaign", function () {
    it("Should create a new campaign", async function () {
      await fundIt.connect(owner).createCampaign(TITLE, DESCRIPTION, TARGET, DURATION, IMAGE, OVERRIDE);

      const campaign = await fundIt.campaigns(0);
      expect(campaign.owner).to.equal(owner.address);
      expect(campaign.title).to.equal(TITLE);
      expect(campaign.description).to.equal(DESCRIPTION);
      expect(campaign.target).to.equal(TARGET);
      expect(campaign.deadline).to.be.closeTo(BigNumber.from(Date.now()).add(DURATION * 24 * 60 * 60), 120);
      expect(campaign.image).to.equal(IMAGE);
      expect(campaign.active).to.be.true;
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
