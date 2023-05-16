// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "./IFundIt.sol";

/**
 * @title FundItStorage
 * @dev This contract stores all the campaigns for the FundIt platform.
 */
contract FundItStorage {

    // Mapping from campaign ID to Campaign struct
    mapping(uint256 => IFundIt.Campaign) private campaigns;

    // Total number of campaigns
    uint256 private numberOfCampaigns = 0;

    /**
     * @dev Function to get a specific campaign.
     * @param _id The ID of the campaign to retrieve.
     * @return A Campaign struct representing the specified campaign.
     */
    function getCampaign(uint256 _id) external view returns (IFundIt.Campaign memory) {
        require(_id < numberOfCampaigns, "Campaign does not exist");
        return campaigns[_id];
    }

    /**
     * @dev Function to get the total number of campaigns.
     * @return The total number of campaigns.
     */
    function getNumberOfCampaigns() external view returns (uint256) {
        return numberOfCampaigns;
    }

    /**
     * @dev Internal function to add a new campaign. This can only be used by this contract.
     * @param _campaign The Campaign struct to store.
     */
    function _addCampaign(IFundIt.Campaign memory _campaign) internal {
        campaigns[numberOfCampaigns] = _campaign;
        numberOfCampaigns++;
    }
}
