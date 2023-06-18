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
 * The contract is pausable and upgradable. 
 */
contract FundIt is IFundIt, Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 maxDuration = 15552000;

    uint256 _campaignId;

    FundItStorage private _storage;

    event CampaignCreated(uint256 indexed campaignId, address indexed campaignCreator);

    event TargetReached(uint256 indexed campaignId, address indexed msgSender, uint256 msgValue);

    event DonationMade(uint256 indexed campaignId, address indexed msgSender, uint256 msgValue);

    event CampaignEnded(uint256 indexed campaignId, address indexed campaignCreator);

    event Withdrawn(uint256 indexed campaignId, address indexed campaignCreator, uint256 msgValue);

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
        string calldata _title,
        string calldata _description,
        uint256 _targetFunding,
        uint256 _duration,
        string calldata _imageURL
    ) external nonReentrant whenNotPaused {
        require(bytes(_title).length > 0, "Title is required");
        require(bytes(_description).length > 0, "Description is required");
        require(_targetFunding > 0, "Target must be greater than 0");
        require(_duration > 0, "Campaign duration must be greater than 0");
        require(_duration.mul(24 * 60 * 60) <= maxDuration, "Campaign duration exceeds maximum limit");

        _campaignId = this.getNumberOfCampaigns();
        address payable _campaignCreator = payable(msg.sender);
        uint256 _endDate = block.timestamp.add(_duration.mul(24 * 60 * 60));

        // Create the campaign struct
        IFundIt.Campaign memory newCampaign = IFundIt.Campaign({
            campaignId: _campaignId,
            campaignCreator: _campaignCreator,
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

        emit CampaignCreated(_campaignId, _campaignCreator);
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
     * @dev Function to get the total number of campaigns.
     * @return The total number of campaigns.
     */
    function getNumberOfCampaigns() external view virtual returns (uint256) {
        uint256 numberOfCampaigns = _storage.campaignCount();
        return numberOfCampaigns;
    }

    /**
     * @dev Allows a user to donate to a campaign.
     * Requires that the campaign is active and has not ended.
     * If the donation msg.value is greater than or equal to the target funding, the campaign is ended.
     * Emits a TargetReached event if the target funding is reached.
     * Emits a DonationMade event.
     */
    function donateToCampaign(uint256 _id) external payable nonReentrant whenNotPaused campaignExists(_id) {
        require(msg.value > 0, "Donation msg.value must be greater than 0");

        Campaign memory campaign = _storage.campaignGetter(_id);

        require(campaign.active, "Campaign is not active");
        require(campaign.endDate > block.timestamp, "Campaign has ended");

        address payable msgSender = payable(msg.sender);
        uint256 msgValue = msg.value;

        if (campaign.amountRaised.add(msg.value) >= campaign.targetFunding) {
            campaign.active = false;
            emit TargetReached(_id, msgSender, msgValue);
        }

        _storage.recordDonation(_id, msg.sender, msg.value);

        emit DonationMade(_id, msgSender, msgValue);
    }

    /// @dev Fallback function that does not accept Ether.
    receive() external payable {
        revert("FundIt does not accept direct payments");
    }

    /**
     * @dev Allows a campaign creator to end a campaign early. Sets active in Campaign struct to false.
     * Requires that the campaign is active.
     * Emits a CampaignEnded event.
     */
    function endCampaign(uint256 _id) external nonReentrant whenNotPaused campaignExists(_id) {
        Campaign memory campaign = _storage.campaignGetter(_id);

        require(campaign.campaignCreator == msg.sender, "Only the campaign owner can end the campaign manually");
        require(campaign.active, "Campaign is already ended");

        campaign.active = false;
        _storage.updateCampaign(_id, campaign);

        address payable msgSender = payable(msg.sender);

        emit CampaignEnded(_id, msgSender);
    }

    /**
     * @dev Allows the campaign creator to withdraw funds from the campaign.
     * @param _id The ID of the campaign to withdraw funds from.
     * @param _amount The msg.value of funds to withdraw.
     * Requires that the campaign is not active.
     * Requires that the campaign campaignCreator_campaignCreator is the message sender.
     * Requires that the msg.value to withdraw is less than or equal to the msg.value raised minus the msg.value previously withdrawn.
     * Emits a Withdrawn event.
     */
    function withdraw(uint256 _id, uint256 _amount) external nonReentrant whenNotPaused campaignExists(_id) {
        require(_amount > 0, "Withdrawal msg.value must be greater than 0");

        Campaign memory campaign = _storage.campaignGetter(_id);

        require(campaign.campaignCreator == msg.sender, "Only the campaign owner can withdraw funds");
        require(campaign.active == false, "Campaign is still active");
        require(campaign.amountRaised.sub(campaign.amountWithdrawn) >= _amount, "Insufficient funds in the campaign");

        payable(msg.sender).transfer(_amount);
        campaign.amountWithdrawn = campaign.amountWithdrawn.add(_amount);
        _storage.updateCampaign(_id, campaign);

        emit Withdrawn(_id, campaign.campaignCreator, _amount);
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