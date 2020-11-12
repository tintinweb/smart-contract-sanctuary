pragma solidity ^0.4.19;  

import "./BurnableToken.sol";  
import "./StandardToken.sol";  
import "./Ownable.sol";  
  
/**  
* @title ZolToken is a basic ERC20 Token  
*/  
contract ZolToken is StandardToken, Ownable, BurnableToken{  
  
  uint256 public totalSupply;  
  string public name;  
  string public symbol;  
  uint32 public decimals;  
  
  /**  
 * @dev assign totalSupply to account creating this contract */  constructor() public {  
  symbol = "ZOL";  
  name = "ZloopToken";  
  decimals = 6;  
  totalSupply = 5000000000000;  
  
  owner = msg.sender;  
  balances[msg.sender] = totalSupply;  
  
  emit Transfer(0x0, msg.sender, totalSupply);  
 }}
