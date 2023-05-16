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

    FundItStorage private _storage;

    event CampaignCreated(uint256 indexed campaignId, address indexed owner);
    event DonationMade(uint256 indexed campaignId, address indexed donor, uint256 amount);
    event CampaignEnded(uint256 indexed campaignId, address indexed owner);
    event Withdrawn(uint256 indexed campaignId, address indexed owner, uint256 amount);

    /// @dev Modifier to check if a campaign exists.
    modifier campaignExists(uint256 _id) {
        require(_id < _storage.getNumberOfCampaigns(), "Campaign does not exist");
        _;
    }

    /// @dev Initializes the contract with the address of the storage contract.
    function initialize(address _storageAddress) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

        _storage = FundItStorage(_storageAddress);
    }

    /**
     * @dev Creates a new campaign.
     * Emits a CampaignCreated event.
     */
    function createCampaign(
        string calldata _title,
        string calldata _description,
        uint256 _target,
        uint256 _duration,
        string calldata _image
    ) external override nonReentrant whenNotPaused {
        require(bytes(_title).length > 0, "Title is required");
        require(bytes(_description).length > 0, "Description is required");
        require(_target > 0, "Target amount must be greater than 0");
        require(_duration > 0, "Campaign duration must be greater than 0");
        require(_duration.mul(24 * 60 * 60) <= maxDuration, "Campaign duration exceeds maximum limit");

        uint256 newCampaignId = _storage.createCampaign(
            payable(msg.sender), 
            _title, 
            _description, 
            _target, 
            block.timestamp.add(_duration.mul(24 * 60 * 60)), 
            _image
        );

        emit CampaignCreated(newCampaignId, msg.sender);
    }

    /**
     * @dev Allows a user to donate to a campaign.
     * Emits a DonationMade event.
     */
    function donateToCampaign(uint256 _id) external payable override nonReentrant whenNotPaused campaignExists(_id) {
        require(msg.value > 0, "Donation amount must be greater than 0");

        Campaign memory campaign = _storage.getCampaign(_id);

        require(campaign.active, "Campaign is not active");
        require(campaign.deadline > block.timestamp, "Campaign has ended");

        _storage.recordDonation(_id, msg.sender, msg.value);

        emit DonationMade(_id, msg.sender, msg.value);
    }

    /// @dev Fallback function that does not accept Ether.
    receive() external payable {
        revert("FundIt does not accept direct payments");
    }

    /// @dev Returns the list of donors for a specific campaign.
    function getCampaignDonors(uint256 _id) external view override campaignExists(_id) returns (address[] memory, uint256[] memory) {
        return _storage.getCampaignDonors(_id);
    }

    /**
     * @dev Ends a campaign.
     * Emits a CampaignEnded event.
     */
    function endCampaign(uint256 _id) external override nonReentrant whenNotPaused campaignExists(_id) {
        Campaign memory campaign = _storage.getCampaign(_id);

        require(campaign.owner == msg.sender, "Only the campaign owner can end the campaign");
        require(campaign.active, "Campaign is already ended");

        _storage.endCampaign(_id);

        emit CampaignEnded(_id, msg.sender);
    }

    /**
     * @dev Allows the campaign owner to withdraw funds from the campaign.
     * Emits a Withdrawn event.
     */
    function withdraw(uint256 _id, uint256 _amount) external nonReentrant whenNotPaused campaignExists(_id) {
        require(_amount > 0, "Withdrawal amount must be greater than 0");

        Campaign memory campaign = _storage.getCampaign(_id);

        require(campaign.owner == msg.sender, "Only the campaign owner can withdraw funds");
        require(campaign.active == false, "Campaign is still active");
        require(campaign.raised >= _amount, "Insufficient funds in the campaign");

        _storage.withdraw(_id, _amount);
        payable(msg.sender).transfer(_amount);

        emit Withdrawn(_id, msg.sender, _amount);
    }

    /// @dev Returns the details of a specific campaign.
    function getCampaign(uint256 _id) external view campaignExists(_id) returns (Campaign memory) {
        return _storage.getCampaign(_id);
    }

    /// @dev Returns the total number of campaigns.
    function getNumberOfCampaigns() external view returns (uint256) {
        return _storage.getNumberOfCampaigns();
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