// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract FundItProxy is TransparentUpgradeableProxy {
    event ImplementationUpdated(address indexed newImplementation);

    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {
    }
}
