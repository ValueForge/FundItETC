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
      expect(await ifundit.numberOfCampaigns()).to.equal(1);
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

    // Add more tests for deployment as needed
  });
})