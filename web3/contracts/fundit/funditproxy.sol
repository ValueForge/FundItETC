// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract FundItProxy is TransparentUpgradeableProxy, Ownable {
    constructor(address _implementation, address _admin) TransparentUpgradeableProxy(_implementation, _admin, "") {
    }
}
