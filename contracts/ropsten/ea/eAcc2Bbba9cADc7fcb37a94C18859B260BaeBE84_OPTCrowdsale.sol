pragma solidity ^0.4.24;

import "./MintedCrowdsale.sol";
import "./ERC20Mintable.sol";



contract OPTToken is ERC20Mintable {

  string public constant name = "Optimus Token";
  string public constant symbol = "OPT";
  uint8 public constant decimals = 18;
}



contract OPTCrowdsale is MintedCrowdsale {

  constructor(
    uint256 rate,
    address wallet,
    ERC20Mintable token
  )
    public
    Crowdsale(rate, wallet, token)

  {
    //As goal needs to be met for a successful crowdsale
    //the value needs to less or equal than a cap which is limit for accepted funds
    
  }
}