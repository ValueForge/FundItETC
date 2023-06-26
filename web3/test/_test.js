const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FundIt", function () {
  let FundIt, fundIt, owner, addr1, addr2;

  beforeEach(async () => {
    FundIt = await ethers.getContractFactory("FundIt");
    [owner, addr1, addr2, _] = await ethers.getSigners();
    fundIt = await FundIt.deploy();
    await fundIt.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await fundIt.owner()).to.equal(owner.address);
    });
  });

  describe("Campaigns", function () {
    it("Should create a new campaign", async function () {
      await fundIt.connect(addr1).createCampaign("Test Campaign", "This is a test campaign", ethers.utils.parseEther("1"), 7, "http://test.com");
      expect(await fundIt.getNumberOfCampaigns()).to.equal(1);
    });

    it("Should allow donations to a campaign", async function () {
      await fundIt.connect(addr1).createCampaign("Test Campaign", "This is a test campaign", ethers.utils.parseEther("1"), 7, "http://test.com");
      await fundIt.connect(addr2).donateToCampaign(0, { value: ethers.utils.parseEther("0.5") });
      const campaign = await fundIt.getCampaign(0);
      expect(campaign.amountRaised).to.equal(ethers.utils.parseEther("0.5"));
    });

    it("Should not allow donations to a non-existent campaign", async function () {
      await expect(fundIt.connect(addr2).donateToCampaign(0, { value: ethers.utils.parseEther("0.5") })).to.be.revertedWith("Campaign does not exist");
    });

    // Add more tests as needed for your specific contract
  });
});
