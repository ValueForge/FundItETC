// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ifundit.sol";


contract FundItProxy {
    address private _implementation;
    address private _admin;

    constructor (address implementation_, address admin_) {
        _implementation = implementation_;
        _admin = admin_;
    }

    fallback() external payable {
        address implementation = _implementation;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), implementation, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    function upgradeTo(address newImplementation) external {
        require(msg.sender == _admin, "Only admin can upgrade");
        _implementation = newImplementation;
    }
}
