// Import required libraries
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { BigNumber } = ethers;
const { BN, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const ProxyAdmin = require('@openzeppelin/contracts/build/contracts/ProxyAdmin.json');
const ProxyAdminABI = require("@openzeppelin/contracts/build/contracts/ProxyAdmin.json").abi;
const { deployContracts } = require('../scripts/deploy');

// Define contract variables
let FundItDeployerFactory, FundItFactory, FundItStorageFactory, FundItProxyFactory, IFundItFactory;
let fundItDeployer, fundIt, fundItStorage, fundItProxy, iFundIt;
let owner, addr1, addr2;

// Define campaign constants
const TITLE = "Test Campaign";
const DESCRIPTION = "This is a test campaign";
const TARGET = ethers.utils.parseEther("1");
const DURATION = 30
const IMAGE = "test_image";
const OVERRIDE = { gasLimit: 100000 };

// Define deployment test suite
describe("Deployment", function () {
  it("Should deploy all contracts without errors", async function () {
    const contracts = await deployContracts();
    const [owner] = await ethers.getSigners();
    
    expect(contracts.fundItStorage).to.be.ok;
    expect(contracts.fundIt).to.be.ok;
    expect(contracts.fundItDeployer).to.be.ok;
    expect(contracts.fundItProxy).to.be.ok;
  });

  it("Should set the correct owner for the contracts", async function () {
    const contracts = await deployContracts();
    const [owner] = await ethers.getSigners();

    expect(await contracts.fundIt.owner()).to.equal(owner.address);
    expect(await contracts.fundItDeployer.owner()).to.equal(owner.address);
    expect(await contracts.fundItStorage.owner()).to.equal(owner.address);
    expect(await contracts.fundItProxy.owner()).to.equal(owner.address);
  });
});