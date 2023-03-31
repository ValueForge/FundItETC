// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ifundit.sol";
import "./funditstorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FundIt is IFundIt, FundItStorage, Ownable {
    event CampaignCreated(uint256 indexed campaignId, address indexed owner, string title, uint256 target);
    event CampaignDonation(uint256 indexed campaignId, address indexed donor, uint256 amount);
    event CampaignEnded(uint256 indexed campaignId, address indexed owner);

    modifier campaignExists(uint256 _id) {
        require(_id < numberOfCampaigns, "Campaign does not exist");
        _;
    }

    // Function to create a new campaign
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _duration,
        string memory _image
    ) external override onlyOwner {
        require(bytes(_title).length > 0, "Title is required");
        require(bytes(_description).length > 0, "Description is required");
        require(_target > 0, "Target amount must be greater than 0");
        require(_duration > 0, "Campaign duration must be greater than 0");

        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = payable(msg.sender);
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = block.timestamp + _duration;
        campaign.image = _image;
        campaign.active = true;

        emit CampaignCreated(numberOfCampaigns, msg.sender, _title, _target);
        numberOfCampaigns++;
    }

    // Function to process donations to a campaign
    function donateToCampaign(uint256 _id) external payable override campaignExists(_id) {
        require(msg.value > 0, "Donation amount must be greater than 0");

        Campaign storage campaign = campaigns[_id];

        require(campaign.active, "Campaign is not active");
        require(campaign.deadline > block.timestamp, "Campaign has ended");
    
        campaign.owner.transfer(msg.value);
    
        campaign.donors.push(msg.sender);
        campaign.donations.push(msg.value);
    
        campaign.amountCollected += msg.value;

        emit CampaignDonation(_id, msg.sender, msg.value);
    }

    // Function to list donors to a campaign
    function getCampaignDonors(uint256 _id) external override returns (address[] memory, uint256[] memory) {
        Campaign storage campaign = campaigns[_id];

        return (campaign.donors, campaign.donations);
    }

    // Function to list active campaigns
    function getActiveCampaigns() external override returns (Campaign[] memory) {
        Campaign[] memory activeCampaigns = new Campaign[](numberOfCampaigns);
        uint256 activeCampaignsCount = 0;

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            if (campaign.active && campaign.deadline > block.timestamp) {
                activeCampaigns[activeCampaignsCount] = campaign;
                activeCampaignsCount++;
            }
        }

        return activeCampaigns;
    }

    // Function to list ended campaigns
    function getEndedCampaigns() external override returns (Campaign[] memory) {
        Campaign[] memory endedCampaigns = new Campaign[](numberOfCampaigns);
        uint256 endedCampaignsCount = 0;

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            if (!campaign.active || campaign.deadline <= block.timestamp) {
                endedCampaigns[endedCampaignsCount] = campaign;
                endedCampaignsCount++;
            }
        }

        return endedCampaigns;
    }

    // Function to end a campaign
    function endCampaign(uint256 _id) external override campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];

        require(campaign.active, "Campaign is not active");
        require(campaign.owner == msg.sender, "You are not the campaign owner");

        campaign.active = false;

        emit CampaignEnded(_id, msg.sender);
    }
}