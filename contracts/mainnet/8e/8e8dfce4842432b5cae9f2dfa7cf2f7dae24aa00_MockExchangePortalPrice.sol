/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-26
*/

pragma solidity ^0.6.12;

contract MockExchangePortalPrice {
  function getValue(address _from, address _to, uint256 _amount)
   external
   view
   returns (uint256)
  {
    return 0;
  }

  function getTotalValue(
    address[] calldata _fromAddresses,
    uint256[] calldata _amounts,
    address _to)
    external
    view
    returns (uint256)
  {
    return 0;
  }
}