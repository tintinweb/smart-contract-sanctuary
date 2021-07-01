pragma solidity ^0.4.24;

import "./OptimusERC20.sol";
import "./OptimusCrowdsale.sol";

contract OptimusShop   {

  OptimusERC20 public _token;
  OptimusCrowdsale public _crowdsale;
  constructor( ) public { }
  function initializeShop( 
    string name, 
    string symbol, 
    uint8 decimals, 
    uint256 cap,
    uint256 rate,
    address wallet,
    uint256 goal_in_eth,
    uint256 openingtime,
    uint256 closingtime) public{
        _token = new OptimusERC20(name,symbol,decimals,cap);
        _crowdsale = new OptimusCrowdsale(rate,wallet,_token,goal_in_eth,now,now + 1 years);
        _token.addMinter(address(_crowdsale));
      
  }


}