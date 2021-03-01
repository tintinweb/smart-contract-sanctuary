pragma solidity 0.4.18;

import "./simple.sol";
contract generator
{
      
    // logs
    event LogAddress (string item, address addr);
  
      function generate(string _name, string _symbol, uint8 _decimals, uint256 _supplyAmount) external {
        // create token
        TTT token=    new TTT(_name,_symbol,_decimals,_supplyAmount,msg.sender);
        // give tokens to user and dubiHolders

        // log new token address
        LogAddress("token", address(token));
    
      }
}