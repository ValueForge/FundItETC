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
    address public fundIt;
    FundItStorage public _storage;

    constructor() {
        proxyAdmin = new ProxyAdmin();
        _storage = new FundItStorage();
        _storage.initialize();

        fundIt = address(new FundIt());

        proxy = new TransparentUpgradeableProxy(
            fundIt,
            address(proxyAdmin),
            abi.encodeWithSignature("initialize(address)", address(_storage))
        );
    }
}
