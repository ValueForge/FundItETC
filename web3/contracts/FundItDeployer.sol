// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./FundIt.sol";

/// @custom:security-contact app.valueforge@gmail.com

// The FundItDeployer contract
contract FundItDeployer is OwnableUpgradeable {
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public proxy;
    FundIt public fundIt;
    FundItStorage public _storage;

    constructor() {
        proxyAdmin = new ProxyAdmin();
        fundIt = new FundIt();
        _storage = new FundItStorage();

        // Create the proxy contract and link it to the logic contract
        proxy = new TransparentUpgradeableProxy(
            address(fundIt),
            address(proxyAdmin),
            abi.encodePacked(_storage)  // This parameter can be used to initialize the FundIt contract, if needed
        );
    }
}
