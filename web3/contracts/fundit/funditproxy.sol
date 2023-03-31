// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FundItProxy is TransparentUpgradeableProxy, OwnableUpgradeable {
    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) {
        __Ownable_init();
    }

    function upgradeTo(address newImplementation) external onlyOwner {
        _upgradeTo(newImplementation);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable onlyOwner {
        _upgradeToAndCall(newImplementation, data);
    }
}
