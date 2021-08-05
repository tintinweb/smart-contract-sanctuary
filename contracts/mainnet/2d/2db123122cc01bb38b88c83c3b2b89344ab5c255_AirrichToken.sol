pragma solidity ^0.5.12;

import "./ERC20Standard.sol";

contract AirrichToken is ERC20Standard {
 constructor() public {
  totalSupply = 21000000000000000;
  name = "Airrich Token";
  decimals = 8;
  symbol = "Airrich Token";
  version = "1.0";
  balances[msg.sender] = totalSupply;
 }
}