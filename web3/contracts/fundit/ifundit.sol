// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

interface IFundIt {
    struct Campaign {
        address payable owner;
        string title;
        string description;
        uint256 target;
        uint256 duration;
        string image;
        uint256 totalDonations;
        address[] donorAddresses;
        uint256[] donationAmounts;
        bool active;
    }

    function createCampaign(    
        address payable _owner,
        string calldata _title,
        string calldata _description,
        uint256 _target,
        uint256 _duration,
        string calldata _image
    ) external;

    function getCampaign(uint256 _id) external view returns (Campaign memory);

    function getNumberOfCampaigns() external view returns (uint256);

    function donateToCampaign(uint256 _id) external payable;

    function getCampaignDonors(uint256 _id) external view returns (address[] memory, uint256[] memory);

    function endCampaign(uint256 _id) external;

    function withdraw(uint256 _id, uint256 _amount) external;
}