/** @type import('hardhat/config').HardhatUserConfig */
require('@openzeppelin/hardhat-upgrades');
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomiclabs/hardhat-web3");

module.exports = {
  solidity: {
    version: '0.8.9',
    defaultNetwork: 'mordor',
    networks: {
      hardhat: {},
      mordor: {
        url: 'https://geth-mordor.etc-network.info',
        accounts: [`0x${process.env.PRIVATE_KEY}`] 
      },
      classic: {
        url: 'https://etc.rivet.link',
        accounts: [`0x${process.env.PRIVATE_KEY}`]
      }
    },
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
