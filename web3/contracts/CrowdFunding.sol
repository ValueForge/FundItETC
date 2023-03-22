// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;


contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donors;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public compaigns;

    uint256 public numberofCampaigns = 0;

    //Function create new campaign
    function createCampaign(
        address _owner, 
        string memory _title, 
        string memory _description, 
        uint26 _target, 
        uint256 _deadline, 
        string memory _image) public returns(uint256) {
        
        //Set index for new campaign in Campaign
        Campaign storage campaign = campaigns[numberofCampaigns];
       
        //Test for vaild input data
        require(campaigns.deadline > block.timestamp, "ERROR: Deadline must be in the future.");
        
        //Fill new campaign data array
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        //Increment campaign index
        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    //Function to process donating to a campaign
    function donateToCampaign (uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donors = msg.sender;
        campaign.donations = amount;

        (bool, sent) = payable(campaign.owner).call{value.amount}("");

        if (sent) {
            campaign.amountColleted = campaign.amountCollected + amount;
        }
    }


    //Function to list donors to a campaign
    function getDonors (uint256 _id,) view public returns (address[] memory, uint256[] memory) {
        
        Campaign storage campaign = campaigns[_id];

        return (campaign.donors, campaign.donations);
    }

    //Function to list campaigns
    function getCampaigns() view public returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            allCampaigns[i] = campaigns[i];
        }

        return allCampaigns;
    }
}