pragma solidity ^0.4.23;

import "Crowdsale.sol";

contract AladeenCrowdsale is Crowdsale {
  constructor(
    uint256 _rate,
    address _wallet,
    ERC20 _token
    
  )
    Crowdsale(_rate, _wallet, _token)
    public
  {
  }
}