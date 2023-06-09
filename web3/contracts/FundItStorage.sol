// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "./IFundIt.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


/**
 * @title FundItStorage
 * @dev This contract stores all the campaigns for the FundIt platform.
 */
contract FundItStorage is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // Mapping from campaign ID to Campaign struct
    mapping(uint256 => IFundIt.Campaign) public campaigns;

    // Total number of campaigns
    uint256 public campaignCount = 0;

    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @dev External function to add a new campaign.
     * @param _newCampaign The Campaign struct to store.
     */
    function addCampaign(IFundIt.Campaign memory _newCampaign) external {
        campaigns[campaignCount] = _newCampaign;
        campaignCount++;
    }

    /**
     * @dev External function to count the number of campaigns
     * @return The number of campaigns
     */
    function getNumberOfCampaigns() external view returns (uint256) {
        return campaignCount;
    }

    /**
     * External function to update a campaign.
     * @param _campaignId The ID of the campaign to update.
     */
    function updateCampaign(uint256 _campaignId, IFundIt.Campaign memory _updatedCampaign) external {
        campaigns[_campaignId] = _updatedCampaign;
    }

    /**
     * External function to get a campaign struct.
     * @param _campaignId The ID of the campaign to get.
     */
    function campaignGetter(uint256 _campaignId) external view returns (IFundIt.Campaign memory) {
        return campaigns[_campaignId];
    }

    /**
     * @dev External function to record a donation.
     * @param _campaignId The ID of the campaign to record the donation for.
     * @param _donor The address of the donor.
     * @param _amount The amount of the donation.
     */
    function recordDonation(uint256 _campaignId, address _donor, uint256 _amount) external {
        campaigns[_campaignId].donorAddresses.push(_donor);
        campaigns[_campaignId].donorAmounts.push(_amount);
        campaigns[_campaignId].amountRaised = campaigns[_campaignId].amountRaised.add(_amount);
    }
}