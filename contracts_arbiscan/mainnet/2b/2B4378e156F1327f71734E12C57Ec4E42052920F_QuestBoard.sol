pragma solidity 0.4.24;

import "./StandardToken.sol";

contract QuestBoard is StandardToken {
    string public constant symbol = "QST";
    string public constant name = "QuestBoard";
    uint8 public constant decimals = 18;
    
    uint256 internal constant tokenUnit = 10**18;
    uint256 internal constant oneBillion = 10**9;
    uint256 internal constant maxTokens = 1 * oneBillion * tokenUnit;
    
    
     
     /**
   * @return the number of decimals of the token.
   */
     
    
 
  
    constructor() public {
        totalSupply_ = maxTokens;
        balances[msg.sender] = maxTokens;
    }
}