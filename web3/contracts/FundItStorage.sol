// SPDX-License-Identifier: MPL-2.0 license
pragma solidity 0.8.9;

import "./IFundIt.sol";

/**
 * @title FundItStorage
 * @dev This contract stores all the campaigns for the FundIt platform.
 */
abstract contract FundItStorage {

    // Mapping from campaign ID to Campaign struct
    mapping(uint256 => IFundIt.Campaign) private campaigns;

    // Total number of campaigns
    uint256 public numberOfCampaigns = 0;

    /**
     * @dev Internal function to add a new campaign. This can only be used by this contract.
     * @param _campaign The Campaign struct to store.
     */
    function _addCampaign(IFundIt.Campaign memory _campaign) public virtual {
        campaigns[numberOfCampaigns] = _campaign;
        numberOfCampaigns++;
    }
}
