pragma solidity ^0.4.24;

import "./DetailedERC20.sol";
import "./StandardToken.sol";
import "./BurnableToken.sol";


contract GRAY is  StandardToken, DetailedERC20, BurnableToken{

  //We inherited the DetailedERC20 
  constructor(string _name, string _symbol, uint256 _decimals) 
  DetailedERC20(_name, _symbol, _decimals)
  public {
  	totalSupply_ = 100000000000000000000000000000000;
  	balances[msg.sender] = 100000000000000000000000000000000;
    name = "Gray Ghost Token";                                   
    decimals = 18;                            
    symbol = "GRAY"; 
  }

}