// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FundItProxy is TransparentUpgradeableProxy, OwnableUpgradeable {
    event ImplementationUpdated(address indexed newImplementation);

    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {
    }
}
