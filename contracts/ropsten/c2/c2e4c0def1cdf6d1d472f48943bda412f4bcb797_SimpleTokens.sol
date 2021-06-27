/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity ^0.4.19;

contract SimpleTokens {
  string public my_name;
  address public my_address;
  uint INITIAL_SUPPLY = 10000;
  mapping(address => uint) balances;

  function SimpleToken() public {
    balances[msg.sender] = INITIAL_SUPPLY;
  }

  // transfer token for a specified address
  function transfer(address _to, uint _amount) public {
    require(balances[msg.sender] > _amount);
    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
  }

  // Gets the balance of the specified address
  function balanceOf(address _owner) public constant returns (uint) {
    return balances[_owner];
  }
  
  
    
  function f(uint start, uint daysAfter) public view{
    if (block.timestamp >= start + daysAfter * 365 days){
    }
  }

  
  
  function Destroy() external{
    selfdestruct(my_address);
  }

}