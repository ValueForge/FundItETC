// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./IFundIt.sol";

contract FundItStorage {
    mapping(uint256 => IFundIt.Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;
}
