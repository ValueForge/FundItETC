// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "./IFundIt.sol";

contract FundItStorage {
    mapping(uint256 => IFundIt.Campaign) private campaigns;
    uint256 private numberOfCampaigns = 0;

    function getCampaign(uint256 _id) external view returns (IFundIt.Campaign memory) {
        return campaigns[_id];
    }

    function getNumberOfCampaigns() external view returns (uint256) {
        return numberOfCampaigns;
    }
}
