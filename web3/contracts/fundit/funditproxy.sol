// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFundIt.sol";


contract FundItProxy is Ownable, IFundIt {
    address private _implementation;

    event ImplementationUpdated(address indexed newImplementation);

    constructor(address implementation_) {
        _implementation = implementation_;
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

    function upgradeTo(address newImplementation) external onlyOwner {
        require(newImplementation != address(0), "New implementation address cannot be zero");
        _implementation = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }
}
