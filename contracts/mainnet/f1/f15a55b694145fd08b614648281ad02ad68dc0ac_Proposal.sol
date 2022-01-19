/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function modifyParameters(bytes32, uint256) public virtual;
  function modifyParameters(bytes32, bytes32, uint256) public virtual;
  function taxSingle(bytes32) public virtual;
}

contract Proposal {
  function execute(bool) public {
    // GEB_ORACLE_RELAYER - adjusting redemption rate bounds to +100% and -50% over 4 months (30.5 days per month)
    Setter(0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851).modifyParameters("redemptionRateLowerBound", 999999934241503702775225172);
    Setter(0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851).modifyParameters("redemptionRateUpperBound", 1000000065758500621404894451);

    // GEB_TAX_COLLECTOR - Set stability fee to 0.1%
    Setter(0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB).taxSingle("ETH-A");
    Setter(0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB).modifyParameters("ETH-A", "stabilityFee", 1000000000031693947650284507);

    // GEB_SURPLUS_AUCTION_HOUSE - adjust bidDuration and totalAuctionLength to the values set at the old Auction House
    Setter(0x4EEfDaE928ca97817302242a851f317Be1B85C90).modifyParameters("bidDuration", 3600);
    Setter(0x4EEfDaE928ca97817302242a851f317Be1B85C90).modifyParameters("totalAuctionLength", 259200);
  }
}