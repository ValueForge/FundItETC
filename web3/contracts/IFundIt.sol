// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

interface IFundIt {
    struct Campaign {
    uint256 id;
    address payable owner;
    string title;
    string description;
    uint256 creationDate;
    uint256 target;
    string image;
    uint256 endDate;
    bool active;
    uint256 totalDonations;
    mapping(address => uint256) donations;
    address[] donorAddresses; // Array to store all donor addresses
    }

    function getCampaign(uint256 _id) external view returns (Campaign memory);

    function donateToCampaign(uint256 _id) external payable;

    function donate(uint256 _campaignId, uint256 _amount) public internal virtual;

    function getNumberOfCampaigns() external view returns (uint256);

    function getCampaignDonations(uint256 _campaignId) public view returns (address[] memory, uint256[] memory);

    function endCampaign(uint256 _id) external;

    function withdraw(uint256 _id, uint256 _amount) external;

    function pause() external;
    
    function unpause() external;
}