const { expect } = require("chai");
const { ethers } = require("hardhat");

// Test suite for the FundIt contract
describe("FundIt", function () {
  let FundIt, fundIt, FundItProxy, fundItProxy, FundItStorage, fundItStorage, owner, addr1, addr2;

// Set up the contract instances before each test
beforeEach(async () => {
  // Get contract factories
  FundItStorage = await ethers.getContractFactory("FundItStorage");
  FundIt = await ethers.getContractFactory("FundIt");
  FundItProxy = await ethers.getContractFactory("FundItProxy");

  // Get signers (accounts)
  [owner, addr1, addr2] = await ethers.getSigners();

  // Deploy and initialize FundItStorage contract
  fundItStorage = await FundItStorage.deploy();
  await fundItStorage.deployed();

  // Deploy FundIt contract
  fundIt = await FundIt.deploy();
  await fundIt.deployed();
  await fundIt.initialize(fundItStorage.address);

  // Deploy FundItProxy contract with the FundIt contract address, owner address, and an empty data array as constructor arguments
  fundItProxy = await FundItProxy.deploy(fundIt.address, owner.address, []);
  await fundItProxy.deployed();

  // Attach the FundIt contract instance to the FundItProxy contract address
  fundIt = FundIt.attach(fundItProxy.address);

  // Initialize the FundIt contract with the FundItStorage address
  await fundIt.connect(owner).initialize(fundItStorage.address);

  // Unpause the contract to allow the creation of a campaign
  await fundIt.connect(owner).unpause();

  // Create a test campaign using the owner account
  await fundIt.connect(owner).createCampaign("Test Campaign", "A test campaign for donations", ethers.utils.parseEther("1"), 7, "https://example.com/image.jpg");

  // Make a donation to the test campaign using addr1 account
  await fundIt.connect(addr1).donateToCampaign(0, { value: ethers.utils.parseEther("0.1") });
});

  // Test deployment of contracts and initialization
  describe("Deployment", function () {
    it("Should deploy and set owner for FundIt contract", async function () {
      expect(await fundIt.owner()).to.equal(owner.address);
    });

    it("Should deploy and set owner for FundItProxy contract", async function () {
      expect(await fundItProxy.owner()).to.equal(owner.address);
    });

    it("Should set the implementation address in FundItProxy contract", async function () {
      expect(await fundItProxy.implementation()).to.equal(fundIt.address);
    });

    it("Should initialize the FundIt contract with correct initial state", async function () {
      expect(await fundIt.numberOfCampaigns()).to.equal(1);
    });

    it("Should initialize the FundItStorage contract with correct initial state", async function () {
      expect(await fundItStorage.numberOfCampaigns()).to.equal(1);
    });

    it("Should pause and unpause the FundIt contract", async function () {
      // Pause the contract
      await fundIt.pause();
      expect(await fundIt.paused()).to.be.true;

      // Unpause the contract
      await fundIt.unpause();
      expect(await fundIt.paused()).to.be.false;
    });
  });

  // Test campaign creation
  describe("Create campaign", function () {
    it("Should create a new campaign and emit event", async function () {
      // Prepare campaign data
      const title = "Test Campaign";
      const description = "This is a test campaign";
      const target = ethers.utils.parseEther("1");
      const duration = 7;
      const image = "https://example.com/image.jpg";

      // Create a new campaign
      await expect(
        fundIt.connect(addr1).createCampaign(title, description, target, duration, image)
      )
        .to.emit(fundIt, "CampaignCreated")
        .withArgs(1, addr1.address); // Check if the event is emitted with correct arguments

      // Retrieve the campaign data
      const campaign = await fundIt.connect(addr1).campaigns(1);

      // Check if the campaign data is correct
      expect(campaign.owner).to.equal(addr1.address);
      expect(campaign.title).to.equal(title);
      expect(campaign.description).to.equal(description);
      expect(campaign.target).to.equal(target);
      expect(campaign.image).to.equal(image);
      expect(campaign.active).to.be.true;
    });
    
    // Test donations to campaigns
    describe("Donations", function () {
      beforeEach(async function () {
        // Create a new campaign before each test
        await fundIt.connect(owner).createCampaign("Test Campaign", "A test campaign for donations", ethers.utils.parseEther("1"), 7, "https://example.com/image.jpg");
      });
    
      it("Should donate to a campaign successfully", async function () {
        // Donate to the campaign
        await fundIt.connect(addr1).donateToCampaign(1, { value: ethers.utils.parseEther("0.1") });
    
        // Check the amount collected
        const campaign = await fundIt.campaigns(1);
        expect(campaign.amountCollected).to.equal(ethers.utils.parseEther("0.1"));
    
        // Check the donors and donations arrays
        const [donors, donations] = await fundIt.getCampaignDonors(1);
        expect(donors[0]).to.equal(addr1.address);
        expect(donations[0]).to.equal(ethers.utils.parseEther("0.1"));
      });
    
      it("Should fail to donate to a non-existent campaign", async function () {
        // Try to donate to a non-existent campaign
        await expect(fundIt.connect(addr1).donateToCampaign(2, { value: ethers.utils.parseEther("0.1") }))
          .to.be.revertedWith("Campaign does not exist");
      });
    
      it("Should fail to donate to an inactive campaign", async function () {
        // End the campaign
        await fundIt.connect(owner).endCampaign(1);
    
        // Try to donate to an inactive campaign
        await expect(fundIt.connect(addr1).donateToCampaign(1, { value: ethers.utils.parseEther("0.1") }))
          .to.be.revertedWith("Campaign is not active");
      });
    
      it("Should fail to donate to a campaign after the deadline", async function () {
        // Set the deadline to the past
        const deadline = (await ethers.provider.getBlock()).timestamp - 1000;
        await fundIt.setCampaignDeadline(1, deadline);
    
        // Try to donate to a campaign after the deadline
        await expect(fundIt.connect(addr1).donateToCampaign(1, { value: ethers.utils.parseEther("0.1") }))
          .to.be.revertedWith("Campaign has ended");
      });
    
      it("Should fail to donate with zero amount", async function () {
        // Try to donate with zero amount
        await expect(fundIt.connect(addr1).donateToCampaign(1, { value: 0 }))
          .to.be.revertedWith("Donation amount must be greater than 0");
      });
    });
  });
});
