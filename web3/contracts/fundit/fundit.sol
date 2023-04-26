// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "./IFundIt.sol";
import "./FundItStorage.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/// @custom:security-contact app.valueforge@gmail.com

// The FundIt contract inherits from IFundIt, FundItStorage, PausableUpgradeable,
// OwnableUpgradeable, Initializable, ReentrancyGuardUpgradeable contracts
// and uses SafeMathUpgradeable library
contract FundIt is IFundIt, FundItStorage, PausableUpgradeable, OwnableUpgradeable, Initializable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor {
        _disableInitializers();
    }
    
    // Variable declaration to cap campaign duration at 180 days
    uint256 maxDuration = 15552000;

    // Event emitted when a new campaign is created
    event CampaignCreated(uint256 indexed campaignId, address indexed owner);

    // Event emitted when a donation is made to a campaign
    event DonationMade(uint256 indexed campaignId, address indexed donor, uint256 amount);

    // Event emitted when a campaign is ended by its owner
    event CampaignEnded(uint256 indexed campaignId, address indexed owner);

    // Event emitted when a campaign owner withdraws funds
    event Withdrawn(uint256 indexed campaignId, address indexed owner, uint256 amount); 

    // Modifier to check if a campaign with the given ID exists
    modifier campaignExists(uint256 _id) {
        require(_id < numberOfCampaigns, "Campaign does not exist");
        _;
        }

    // Function to initialize contract state
    function initialize() initializer internal {
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
    }
    
    // Function to create a new campaign
    function createCampaign(
        string calldata _title,
        string calldata _description,
        uint256 _target,
        uint256 _duration,
        string calldata _image
        ) external override nonReentrant {
            
             // Validation checks
            require(bytes(_title).length > 0, "Title is required");
            require(bytes(_description).length > 0, "Description is required");
            require(_target > 0, "Target amount must be greater than 0");
            require(_duration > 0, "Campaign duration must be greater than 0");
            require(_duration <= maxDuration, "Campaign duration exceeds maximum limit");

            // Create a new campaign and store it in the campaigns mapping
            Campaign storage campaign = campaigns[numberOfCampaigns];
            campaign.owner = payable(msg.sender);
            campaign.title = _title;
            campaign.description = _description;
            campaign.target = _target;
            campaign.deadline = block.timestamp.add(_duration.mul(24 * 60 * 60));
            campaign.image = _image;
            campaign.active = true;
            
            // Emit the CampaignCreated event
            emit CampaignCreated(numberOfCampaigns, msg.sender);
            
            // Increment the numberOfCampaigns counter
            numberOfCampaigns++;
    }

    // Function to process donations to a campaign
    function donateToCampaign(uint256 _id) external payable override nonReentrant campaignExists(_id) {
        // Validation checks
        require(msg.value > 0, "Donation amount must be greater than 0");

        Campaign storage campaign = campaigns[_id];

        require(campaign.active, "Campaign is not active");
        require(campaign.deadline > block.timestamp, "Campaign has ended");

        // Update the campaign's donors and donations arrays
        campaign.donors.push(msg.sender);
        campaign.donations.push(msg.value);

        // Update the campaign's amountCollected
        campaign.amountCollected = campaign.amountCollected.add(msg.value);

        // Emit the DonationMade event
        emit DonationMade(_id, msg.sender, msg.value);
    }

    // Function to receive and revert direct payments to contract
    receive() external payable {
        revert("FundIt does not accept direct payments");
    }

    // Function to list donors to a campaign
    function getCampaignDonors(uint256 _id)
    external view override campaignExists(_id)
    returns (address[] memory, uint256[] memory) {
        Campaign storage campaign = campaigns[_id];

        return (campaign.donors, campaign.donations);
    }

    // Function to list active campaigns
    function getActiveCampaigns() external view override returns (Campaign[] memory) {
        uint256 activeCampaignsCount = 0;

        // Count active campaigns
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            if (campaign.active && campaign.deadline > block.timestamp) {
                activeCampaignsCount++;
            }
        }

        // Create a new dynamic array to store active campaigns
        Campaign[] memory activeCampaigns = new Campaign[](activeCampaignsCount);
        uint256 activeIndex = 0;

        // Iterate through all campaigns and populate the activeCampaigns array
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            if (campaign.active && campaign.deadline > block.timestamp) {
                activeCampaigns[activeIndex] = campaign;
                activeIndex++;
            }
        }

        return activeCampaigns;
    }

    // Function to list ended campaigns
    function getEndedCampaigns() external view override returns (Campaign[] memory) {
        uint256 endedCampaignsCount = 0;

        // Count ended campaigns
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            if (!campaign.active || campaign.deadline <= block.timestamp) {
                endedCampaignsCount++;
            }
        }

        // Create a new dynamic array to store ended campaigns
        Campaign[] memory endedCampaigns = new Campaign[](endedCampaignsCount);
        uint256 endedIndex = 0;

        // Iterate through all campaigns and populate the endedCampaigns array
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            if (!campaign.active || campaign.deadline <= block.timestamp) {
                endedCampaigns[endedIndex] = campaign;
                endedIndex++;
            }
        }

        return endedCampaigns;
    }

    // Function to end a campaign
    function endCampaign(uint256 _id) external override nonReentrant campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];

        // Validation check
        require(campaign.active, "Campaign is not active");
        require(campaign.owner == msg.sender, "You are not the campaign owner");
        require(campaign.amountCollected == 0, "The collected funds have not been withdrawn yet!");

        // Set the campaign as inactive
        campaign.active = false;

        // Emit the CampaignEnded event
        emit CampaignEnded(_id, msg.sender);
    }

    // Function to withdraw funds donated to campaign owner (ends campaign)
    function withdrawFunds(uint256 _id) external override nonReentrant {
        Campaign storage campaign = campaigns[_id];

        // Validation checks -- Uncomment to activate
        require(campaign.owner == msg.sender, "Only the campaign owner can withdraw funds");
        // require(campaign.amountCollected >= campaign.target, "Funds can only be withdrawn if the campaign reached its target");
        // require(block.timestamp >= campaign.deadline, "Funds can only be withdrawn after the deadline");
        // require(campaign.active, "The campaign must be active");
        
        // Prepare withdrwal amount
        uint256 amount = campaign.amountCollected;
        
        // Send donated funds to campaign owner
        (bool success, ) = campaign.owner.call{value: amount}("");
        require(success, "Withdrawal failed");

        // Set the campaign as inactive
        campaign.amountCollected = 0;
        campaign.active = false;
        
        // Emit the Withdrawn and CampaignEnded events
        emit Withdrawn(_id, msg.sender, amount);
        emit CampaignEnded(_id, msg.sender);
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}