const { expect } = require("chai");
const { loadFixture } = require("hardhat-toolkit");

describe("FundIt", function () {
  let FundIt, fundIt, FundItProxy, fundItProxy, FundItStorage, fundItStorage, IFundIt, ifundit, owner, addr1, addr2;

  async function funditFixture() {
    FundItStorage = await ethers.getContractFactory("FundItStorage");
    FundIt = await ethers.getContractFactory("FundIt");
    FundItProxy = await ethers.getContractFactory("FundItProxy");

    [owner, addr1, addr2] = await ethers.getSigners();

    fundItStorage = await FundItStorage.deploy();
    await fundItStorage.deployed();
    fundIt = await FundIt.deploy(fundItStorage.address);
    await fundIt.deployed();

    // Deploy proxy
    fundItProxy = await FundItProxy.deploy(fundIt.address, owner.address, []);
    await fundItProxy.deployed();

    // Attach FundIt contract to the proxy
    fundIt = FundIt.attach(fundItProxy.address);

    // Set up initial state
    await fundIt.connect(owner).pause();
    await fundIt.connect(owner).unpause();
    await fundIt.connect(owner).createCampaign("Test Campaign", "A test campaign for donations", ethers.utils.parseEther("1"), 7, "https://example.com/image.jpg");
    await fundIt.connect(addr1).donateToCampaign(0, { value: ethers.utils.parseEther("0.1") });
  }

  before(async () => {
    await funditFixture();
    IFundIt = await ethers.getContractFactory("IFundIt");
    ifundit = await ethers.getContractAt("IFundIt", fundIt.address);
  });

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();
    const fixture = await loadFixture(funditFixture);
    fundIt = fixture.fundIt;
    fundItProxy = fixture.fundItProxy;
    fundItStorage = fixture.fundItStorage;
  });
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
      .withArgs(0, addr1.address); // Check if the event is emitted with correct arguments

    // Retrieve the campaign data
    const campaign = await fundIt.connect(addr1).campaigns(0);

    // Check if the campaign data is correct
    expect(campaign.owner).to.equal(addr1.address);
    expect(campaign.title).to.equal(title);
    expect(campaign.description).to.equal(description);
    expect(campaign.target).to.equal(target);
    expect(campaign.image).to.equal(image);
    expect(campaign.active).to.be.true;
  });

  describe("Donations", function () {
    beforeEach(async function () {
      // Create a new campaign before each test
      await fundIt.connect(owner).createCampaign("Test Campaign", "A test campaign for donations", ethers.utils.parseEther("1"), 7, "https://example.com/image.jpg");
    });
  
    it("Should donate to a campaign successfully", async function () {
      // Donate to the campaign
      await fundIt.connect(donor1).donateToCampaign(0, { value: ethers.utils.parseEther("0.1") });
  
      // Check the amount collected
      const campaign = await fundIt.campaigns(0);
      expect(campaign.amountCollected).to.equal(ethers.utils.parseEther("0.1"));
  
      // Check the donors and donations arrays
      const [donors, donations] = await fundIt.getCampaignDonors(0);
      expect(donors[0]).to.equal(donor1.address);
      expect(donations[0]).to.equal(ethers.utils.parseEther("0.1"));
    });
  
    it("Should fail to donate to a non-existent campaign", async function () {
      // Try to donate to a non-existent campaign
      await expect(fundIt.connect(donor1).donateToCampaign(1, { value: ethers.utils.parseEther("0.1") }))
        .to.be.revertedWith("Campaign does not exist");
    });
  
    it("Should fail to donate to an inactive campaign", async function () {
      // End the campaign
      await fundIt.connect(owner).endCampaign(0);
  
      // Try to donate to an inactive campaign
      await expect(fundIt.connect(donor1).donateToCampaign(0, { value: ethers.utils.parseEther("0.1") }))
        .to.be.revertedWith("Campaign is not active");
    });
  
    it("Should fail to donate to a campaign after the deadline", async function () {
      // Set the deadline to the past
      const deadline = (await ethers.provider.getBlock()).timestamp - 1000;
      await fundIt.setCampaignDeadline(0, deadline);
  
      // Try to donate to a campaign after the deadline
      await expect(fundIt.connect(donor1).donateToCampaign(0, { value: ethers.utils.parseEther("0.1") }))
        .to.be.revertedWith("Campaign has ended");
    });
  
    it("Should fail to donate with zero amount", async function () {
      // Try to donate with zero amount
      await expect(fundIt.connect(donor1).donateToCampaign(0, { value: 0 }))
        .to.be.revertedWith("Donation amount must be greater than 0");
    });
  });
})});