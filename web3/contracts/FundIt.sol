// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "./IFundIt.sol";
import "./FundItStorage.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/// @custom:security-contact app.valueforge@gmail.com
/**
 * @title FundIt Contract
 * @dev This contract enables users to create, manage, and donate to crowdfunding campaigns.
 * It uses a separate storage contract for storing the state of campaigns.
 */
contract FundIt is IFundIt, Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 maxDuration = 15552000;

    uint256 _campaignId;

    FundItStorage private _storage;

    event CampaignCreated(uint256 indexed campaignId, address indexed owner);

    event TargetReached(uint256 indexed campaignId, address indexed donor, uint256 amount);

    event DonationMade(uint256 indexed campaignId, address indexed donor, uint256 amount);

    event CampaignEnded(uint256 indexed campaignId, address indexed owner);

    event Withdrawn(uint256 indexed campaignId, address indexed owner, uint256 amount);

    /// @dev Modifier to check if a campaign exists.
    modifier campaignExists(uint256 _id) {
        require(_id < this.getNumberOfCampaigns(), "Campaign does not exist");
        _;
    }

    /// @dev Initializes the contract with the address of the storage contract.
    function initialize(address _storageAddress) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _storage = FundItStorage(_storageAddress);
    }

    /**
     * @dev Creates a new campaign.
     * Emits a CampaignCreated event.
     */
    function createCampaign(
        address payable _campaignOwner,
        string calldata _title,
        string calldata _description,
        uint256 _targetFunding,
        uint256 _duration,
        string calldata _imageURL
    ) external nonReentrant whenNotPaused {
        require(bytes(_title).length > 0, "Title is required");
        require(bytes(_description).length > 0, "Description is required");
        require(_targetFunding > 0, "Target amount must be greater than 0");
        require(_duration > 0, "Campaign duration must be greater than 0");
        require(_duration.mul(24 * 60 * 60) <= maxDuration, "Campaign duration exceeds maximum limit");

        _campaignId = this.getNumberOfCampaigns();
        uint256 _endDate = block.timestamp.add(_duration.mul(24 * 60 * 60));

        // Create the campaign struct
       IFundIt.Campaign memory newCampaign = IFundIt.Campaign({
            campaignId: _campaignId,
            owner: _campaignOwner,
            title: _title,
            description: _description,
            creationDate: block.timestamp,
            targetFunding: _targetFunding,
            endDate: _endDate,
            imageURL: _imageURL,
            active: true,
            amountRaised: 0,
            amountWithdrawn: 0,
            donorCount: 0,
            donorAddresses: new address[](0),
            donorAmounts: new uint256[](0)
        });

       _storage.addCampaign(newCampaign);

       emit CampaignCreated("A campaign numbered ", this.getNumberOfCampaigns() - 1, " has been created by ", _campaignOwner, ".");
    }

    /**
     * @dev Function to get a specific campaign.
     * @param _id The ID of the campaign to retrieve.
     * @return The Campaign struct.
     */
    function getCampaign(uint256 _id) external virtual campaignExists(_id) returns (Campaign memory) { 
        Campaign memory _campaign =  _storage.campaignGetter(_id);

        return (_campaign);
    }

    /**
     * @dev Function to deconstruct a campaign struct.
     * @param _campaign The Campaign struct to deconstruct.
     * @return The deconstructed Campaign struct.
     */
    function deconstructCampaign(Campaign memory _campaign) external returns (uint256, address, string memory, string memory, uint256, uint256, string memory, uint256, bool, uint256, uint256, address[] memory, uint256[] memory){
        _campaignId = _campaign.campaignId;
        address payable _campaignOwner = _campaign.owner;
        string memory _title = _campaign.title;
        string memory _description = _campaign.description;
        uint256 _creationDate = _campaign.creationDate;
        uint256 _targetFunding = _campaign.targetFunding;
        string memory _imageURL = _campaign.imageURL;
        uint256 _endDate = _campaign.endDate;
        bool _active = _campaign.active;
        uint256 _amountRaised = _campaign.amountRaised;
        uint256 _amountWithdrawn = _campaign.amountWithdrawn;
        uint256 _donorCount = _campaign.donorCount;
        address[] memory _donorAddresses = _campaign.donorAddresses;
        uint256[] memory _donorAmounts = _campaign.donorAmounts;
        return (_campaignId, _campaignOwner, _title, _description, _creationDate, _targetFunding, _imageURL, _endDate, _active, _amountRaised, _amountWithdrawn, _donorCount, _donorAddresses[], _donorAmounts[]);
    }  

    /**
     * @dev Function to get the total number of campaigns.
     * @return The total number of campaigns.
     */
    function getNumberOfCampaigns() external view virtual returns (uint256) {
        return _storage.numberOfCampaigns;
    }

    /**
     * @dev Allows a user to donate to a campaign.
     * Requires that the campaign is active and has not ended.
     * If the donation amount is greater than or equal to the target funding, the campaign is ended.
     * Emits a TargetReached event if the target funding is reached.
     * Emits a DonationMade event.
     */
    function donateToCampaign(uint256 _id) external payable nonReentrant whenNotPaused campaignExists(_id) {
        require(msg.value > 0, "Donation amount must be greater than 0");

        Campaign memory campaign = this.getCampaign(_id);

        require(campaign.active, "Campaign is not active");
        require(campaign.endDate > block.timestamp, "Campaign has ended");

        if (campaign.amountRaised.add(msg.value) >= campaign.targetFunding) {
            campaign.active = false;
            emit TargetReached("Campaign number ", _id, " reached its funding target when ", msg.sender, " donated ", msg.value, " ETC.");
        }

        _storage.recordDonation(_id, msg.sender, msg.value);

        emit DonationMade("Campaign number ", _id, " has received a donation from ", msg.sender, "of ", msg.value, "ETC.");
    }

    /// @dev Fallback function that does not accept Ether.
    receive() external payable {
        revert("FundIt does not accept direct payments");
    }

    /**
     * @dev Allows a campaign owner to end a campaign early. Sets active in Campaign struct to false.
     * Requires that the campaign is active.
     * Emits a CampaignEnded event.
     */
    function endCampaign(uint256 _id) external nonReentrant whenNotPaused campaignExists(_id) {
        Campaign memory campaign = _storage.getCampaign(_id);

        require(campaign.campaignOwner == msg.sender, "Only the campaign owner can end the campaign manually");
        require(campaign.active, "Campaign is already ended");

        campaign.active = false;
        _storage.updateCampaign(_id, campaign);

        emit CampaignEnded("Campaign number ", _id, "has been ended by ", msg.sender, ".");
    }

    /**
     * @dev Allows the campaign owner to withdraw funds from the campaign.
     * @param _id The ID of the campaign to withdraw funds from.
     * @param _amount The amount of funds to withdraw.
     * Requires that the campaign is not active.
     * Requires that the campaign owner is the message sender.
     * Requires that the amount to withdraw is less than or equal to the amount raised minus the amount previously withdrawn.
     * Emits a Withdrawn event.
     */
    function withdraw(uint256 _id, uint256 _amount) external nonReentrant whenNotPaused campaignExists(_id) {
        require(_amount > 0, "Withdrawal amount must be greater than 0");

        Campaign memory campaign = _storage.getCampaign(_id);

        require(campaign.owner == msg.sender, "Only the campaign owner can withdraw funds");
        require(campaign.active == false, "Campaign is still active");
        require(campaign.amountRaised.sub(campaign.amountWithdrawn) >= _amount, "Insufficient funds in the campaign");

        payable(msg.sender).transfer(_amount);
        campaign.amountWithdrawn = campaign.amountWithdrawn.add(_amount);
        _storage.updateCampaign(_id, campaign);

        emit Withdrawn("Campaign number ", _id, ", owned by ", msg.sender, " has withdrawn ", _amount, " ETC.");
    }

    /// @dev Pauses the contract, preventing any actions.
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract, allowing actions to be taken.
    function unpause() external onlyOwner {
        _unpause();
    }
}