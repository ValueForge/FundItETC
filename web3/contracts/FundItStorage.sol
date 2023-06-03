// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "./IFundIt.sol";

/**
 * @title FundItStorage
 * @dev This contract stores all the campaigns for the FundIt platform.
 */
contract FundItStorage {

    // Mapping from campaign ID to Campaign struct, donorAddresses, and donationAmounts
    mapping(uint256 => IFundIt.Campaign) public campaigns;

    // mapping(uint256 => address[]) public donations;

    // Total number of campaigns
    uint256 public numberOfCampaigns = 0;

    /**
     * @dev External function to add a new campaign.\
     * @param _campaign The Campaign struct to store.
     */
    function addCampaign(IFundIt.Campaign memory _campaign) external {
        campaigns[numberOfCampaigns] = _campaign;
        numberOfCampaigns++;
    }

    /**
     * @dev Exrernal function to get a campaign.
     * @param _campaignId The ID of the campaign to get.
     */
    // function getCampaign(uint256 _campaignId) external view returns (IFundIt.Campaign memory) {
    //    return campaigns[_campaignId];
    // }

    /**
     * @dev External function to get the total number of campaigns.
     * @return The total number of campaigns.
     */
    // function getNumberOfCampaigns() external view returns (uint256) {
    //    return numberOfCampaigns;
    // }

    /**
     * @dev Exrernal function to record a donation.
     * @param _campaignId The ID of the campaign to record the donation for.
     * @param _donor The address of the donor.
     * @param _amount The amount of the donation.
     */
    function recordDonation(
        uint256 _campaignId,
        address _donor,
        uint256 _amount
    ) external {
        campaigns[_campaignId].donorAddresses.push(_donor);
        campaigns[_campaignId].donorAmounts.push(_amount);
        campaigns[_campaignId].totalDonations = campaigns[_campaignId].totalDonations.sum(_amount);
    }
}