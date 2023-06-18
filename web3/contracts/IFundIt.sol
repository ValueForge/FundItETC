// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

interface IFundIt {
    struct Campaign {
    uint256 campaignId;
    address payable campaignCreator;
    string title;
    string description;
    uint256 creationDate;
    uint256 targetFunding;
    string imageURL;
    uint256 endDate;
    bool active;
    uint256 amountRaised;
    uint256 amountWithdrawn;
    uint256 donorCount;
    address[] donorAddresses; // Array to store all donor addresses
    uint256[] donorAmounts; // Array to store all donor amounts
    }

    function initialize(address _storageAddress) external;

    function createCampaign(
        string calldata _title,
        string calldata _description,
        uint256 _targetFunding,
        uint256 _duration,
        string calldata _imageURL
    ) external;

    function getCampaign(uint256 _id) external returns (Campaign memory);

    function getNumberOfCampaigns() external returns (uint256);

    function donateToCampaign(uint256 _id) external payable;

    function endCampaign(uint256 _id) external;

    function withdraw(uint256 _id, uint256 _amount) external;

    function pause() external;
    
    function unpause() external;
}