// const hre = require('hardhat');

//async function deployContracts() {
  const [deployer] = await hre.ethers.getSigners();

  console.log('deployContracts: Deploying contracts with the account:', deployer.address);

  // Deploy FundItStorage.sol
  const FundItStorage = await hre.ethers.getContractFactory('FundItStorage');
  const fundItStorage = await FundItStorage.deploy();
  await fundItStorage.deployed();

  console.log('deployContracts: FundItStorage deployed to:', fundItStorage.address);

  // Deploy FundIt.sol (Implementation)
  const FundIt = await hre.ethers.getContractFactory('FundIt');
  const fundIt = await FundIt.deploy();
  await fundIt.deployed();

  console.log('deployContracts: FundIt (Implementation) deployed to:', fundIt.address);

  // Deploy FundItDeployer.sol (ProxyAdmin)
  const FundItDeployer = await hre.ethers.getContractFactory('FundItDeployer');
  const fundItDeployer = await FundItDeployer.deploy();
  await fundItDeployer.deployed();

  console.log('deployContracts: FundItDeployer (ProxyAdmin) deployed to:', fundItDeployer.address);

  // Deploy FundItProxy.sol (Proxy)
  const initPayload = fundIt.interface.encodeFunctionData("initialize", [fundItStorage.address]);
  const FundItProxy = await hre.ethers.getContractFactory('FundItProxy');
  const fundItProxy = await FundItProxy.deploy(fundIt.address, fundItDeployer.address, initPayload);
  await fundItProxy.deployed();

  console.log('deployContracts: FundItProxy (Proxy) deployed to:', fundItProxy.address);

  return {fundItStorage, fundIt, fundItDeployer, fundItProxy};

deployContracts()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

module.exports = {
  deployContracts,
};
