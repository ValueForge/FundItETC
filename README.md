# FundItETC

FundItETC is an open-source, decentralized crowd funding platform in development for deployment on Ethereum Classic.

It is an expansion on a JSMastery educational project by [Adrian Hajdin](https:\\jsmastery.pro) to whom we are grateful.

## Development environment

The back-end for FundItETC is a suite of four Solidity smart contracts developed for and deployed to the ETC network using the thirdweb Web3 and HardHat frameworks.

FundItETC will be accompanied by a JavaScript-based UI application and website which is expected to utilize the Tailwind CSS framework.

## Change log

Here are the changes and explanations from the original JSMastery project:

### Solidity

- Changed the Solidity version pragma to `^0.8.9`, which allows for minor version updates to Solidity 0.8.
- Added a `payable` modifier to the `owner` field in the `Campaign` struct to indicate that the owner can receive ether.
- Added a `active` field to the `Campaign` struct to indicate if the campaign is still active or has ended.
- Removed the return value of the `createCampaign` function since it was not being used.
- Added more input validation to the `createCampaign` function to ensure that required fields are not empty and values are greater than 0.
- Removed the `numberOfCampaigns - 1` return value from the `createCampaign` function since it was not necessary.
- Changed the `getDonors` function to external and added the `view` modifier since it does not modify state.
- Changed the `getDonors` function name to `getCampaignDonors` for clarity.
- Changed the `getCampaigns` function to two separate functions, `getActiveCampaigns` and `getEndedCampaigns`, which list active and ended campaigns respectively.
- Added input validation to the `donateToCampaign` function to check that the campaign is active and has not ended before accepting donations.
- Changed the `campaign.owner.call` method to `campaign.owner.transfer` to simplify the payment process and reduce the risk of reentrancy attacks.
- Changed the `getDonors` and `getCampaigns` functions to return arrays of `Campaign` structs for consistency.
- Changed the `getActiveCampaigns` and `getEndedCampaigns` functions to only return campaigns that are active or have ended, respectively.
- Added an `endCampaign` function to allow the campaign owner to end a campaign.
- Added `ifundit.sol` interface contract to define the functions that the proxy contract will use.
- Added `funditproxy.sol` proxy contract to allow for the upgrade of the main contract without affecting the proxy contract.  This is to be done by changing the address of the main contract in the proxy contract.
- Changed all relevant functions to use the proxy contract instead of the main contract address.
- Added a `fundit` folder to contain the main contract, proxy contract, and interface contract.
- Moved `fundit`, `ifundit`, and `funditproxy` contracts to the `contracts/fundit` folder.
- Renamed contracts using MixedCase to `FundIt`, `IFundIt`, and `FundItProxy`.
- Added `FundItStorage` contract to separate logic from storage.
- Added annotations to the `FundIt` contract to explain the functions and variables.
