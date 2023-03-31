// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract FundItStorage {
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

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;
}
