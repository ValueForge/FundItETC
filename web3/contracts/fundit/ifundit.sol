// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFundIt {
    uint256 MAX_DURATION = 180 days;
    
    struct Campaign {
        address payable owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donors;
        uint256[] donations;
        bool active;
    }

    function createCampaign(
        string calldata _title,
        string calldata _description,
        uint256 _target,
        uint256 _duration,
        string calldata _image
    ) external;

    function donateToCampaign(uint256 _id) external payable;

    function getCampaignDonors(uint256 _id) external view returns (address[] memory, uint256[] memory);

    function getActiveCampaigns() external view returns (Campaign[] memory);

    function getEndedCampaigns() external view returns (Campaign[] memory);

    function endCampaign(uint256 _id) external;
}
