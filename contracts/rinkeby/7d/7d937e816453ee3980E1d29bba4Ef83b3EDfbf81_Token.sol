/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity ^0.5.0;


contract Token  {
  string  public name;
  string  public symbol;
  uint256 public decimals;

  constructor() public {
    name = "Dai Stablecoin (DAI)";
    symbol = "DAI";
    decimals = 18;
  }
}