// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract FundItProxy is TransparentUpgradeableProxy {
    event ImplementationUpdated(address indexed newImplementation);

    constructor(
        address _logic,
        address _admin,
        address _storage
    ) TransparentUpgradeableProxy(_logic, _admin, abi.encodePacked(_storage)) {
    }
}
