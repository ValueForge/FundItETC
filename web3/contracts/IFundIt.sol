// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

interface IFundIt {
    struct Campaign {
    uint256 campaignId;
    address payable campaignOwner;
    string title;
    string description;
    uint256 creationDate;
    uint256 target;
    string imageURL;
    uint256 endDate;
    bool active;
    uint256 amountRaised;
    uint256 numberOfDonations;
    address[] donorAddresses; // Array to store all donor addresses
    uint256[] donorAmounts; // Array to store all donor amounts
    }

    function initialize(address _storageAddress) external;

    function createCampaign(
        address payable _campaignOwner,
        string calldata _title,
        string calldata _description,
        uint256 _target,
        uint256 _duration,
        string calldata _imageURL
    ) external;

    function getCampaign(uint256 _id) external returns (Campaign memory);

    function deconstructCampaign(Campaign memory) external returns (uint256, address, string memory, string memory, uint256, uint256, string memory, uint256, bool, uint256, uint256, address[] memory, uint256[] memory);

    function getNumberOfCampaigns() external view returns (uint256);

    function donateToCampaign(uint256 _id) external payable;

    function getCampaignDonors(uint256 _id) external view returns (address[] memory, uint256[] memory);

    function endCampaign(uint256 _id) external;

    function withdraw(uint256 _id, uint256 _amount) external;

    function pause() external;
    
    function unpause() external;
}