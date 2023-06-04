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
        address payable _owner,
        string calldata _title,
        string calldata _description,
        uint256 _target,
        uint256 _duration,
        string calldata _image
    ) external nonReentrant whenNotPaused {
        require(bytes(_title).length > 0, "Title is required");
        require(bytes(_description).length > 0, "Description is required");
        require(_target > 0, "Target amount must be greater than 0");
        require(_duration > 0, "Campaign duration must be greater than 0");
        require(_duration.mul(24 * 60 * 60) <= maxDuration, "Campaign duration exceeds maximum limit");

        _campaignId = this.getNumberOfCampaigns();
        uint256 _endDate = block.timestamp.add(_duration.mul(24 * 60 * 60));

        // Create the campaign struct
       IFundIt.Campaign memory newCampaign = IFundIt.Campaign({
            campaignId: _campaignId,
            owner: _owner,
            title: _title,
            description: _description,
            creationDate: block.timestamp,
            target: _target,
            endDate: _endDate,
            image: _image,
            active: true,
            totalDonations: 0,
            numberOfDonations: 0,
            donorAddresses: new address[](0),
            donorAmounts: new uint256[](0)
        });

       _storage.addCampaign(newCampaign);

       emit CampaignCreated(this.getNumberOfCampaigns() - 1, _owner);
    }

       /**
     * @dev Function to get a specific campaign.
     * @param _id The ID of the campaign to retrieve.
     */
    function getCampaign(uint256 _id) external view virtual returns (
        uint256 campaignId,
        address payable owner,
        string memory title,
        string memory description,
        uint256 creationDate,
        uint256 target,
        string memory image,
        uint256 endDate,
        bool active,
        uint256 totalDonations,
        uint256 numberOfDonations,
        address[] memory donorAddresses,
        uint256[] memory donorAmounts) {

        require(_id <this.getNumberOfCampaigns(), "Campaign does not exist");  
        
        Campaign memory campaign = _storage.campaigns(_id);

        _campaignId = campaign.campaignId;
        _owner = campaign.owner;
        _title = campaign.title;
        _description = campaign.description;
        _creationDate = campaign.creationDate;
        _target = campaign.target;
        _image = campaign.image;
        _endDate = campaign.endDate;
        _active = campaign.active;
        _totalDonations = campaign.totalDonations;
        _numberOfDonations = campaign.numberOfDonations;
        _donorAddresses[] = campaign.donorAddresses;
        _donorAmounts[] = campaign.donorAmounts;

        return (_campaignId, _owner, _title, _description, _creationDate, _target, _image, _endDate, _active, _totalDonations, _numberOfDonations, _donorAddresses[], _donorAmounts[]);
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
     * Emits a DonationMade event.
     */
    function donateToCampaign(uint256 _id) external payable nonReentrant whenNotPaused campaignExists(_id) {
        require(msg.value > 0, "Donation amount must be greater than 0");

        Campaign memory campaign = this.getCampaign(_id);

        require(campaign.active, "Campaign is not active");
        require(campaign.endDate > block.timestamp, "Campaign has ended");

        // campaign.donorAddresses.push(msg.sender);
        // campaign.donorAmounts.push(msg.value);
        // campaign.totalDonations = campaign.totalDonations.add(msg.value);
        _storage.recordDonation(_id, msg.sender, msg.value);

        emit DonationMade(_id, msg.sender, msg.value);
    }

    /// @dev Fallback function that does not accept Ether.
    receive() external payable {
        revert("FundIt does not accept direct payments");
    }

    /** @dev Returns the array of donors and an areray of amounts for a specific campaign.
     * @param _id The ID of the campaign to retrieve the donors for.
     */
    function getCampaignDonors(uint256 _id) external view campaignExists(_id) returns (address[] memory, uint256[] memory) {
        Campaign storage campaign = _storage.campaigns[_id];
        uint256[] memory amounts = new uint256[](campaign.donorAddresses.length);

        for (uint i = 0; i < campaign.donorAddresses.length; i++) {
            amounts[i] = campaign.donations[campaign.donorAddresses[i]];
        }

        return (campaign.donorAddresses, amounts);
    }

    /**
     * @dev Allows a campaign owner to end a campaign early. Sets active in Campaign struct to false.
     * Emits a CampaignEnded event.
     */
    function endCampaign(uint256 _id) external nonReentrant whenNotPaused campaignExists(_id) {
        Campaign memory campaign = _storage.getCampaign(_id);

        require(campaign.owner == msg.sender, "Only the campaign owner can end the campaign");
        require(campaign.active, "Campaign is already ended");

        _storage.campaigns[_id].active = false;

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
        require(campaign.totalDonations >= _amount, "Insufficient funds in the campaign");

        payable(msg.sender).transfer(_amount);

        emit Withdrawn(_id, msg.sender, _amount);
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