/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity ^0.4.0;   

contract SimpleCoin {   

  mapping (address => uint256) public coinBalance; 
 
  constructor(uint256 _initialSupply) public {
    coinBalance[msg.sender] = _initialSupply;   
  }
 
  function transfer(address _to, uint256 _amount) public {
    require(coinBalance[msg.sender] >= _amount);      
    require(coinBalance[_to] + _amount >= coinBalance[_to]);                             
    coinBalance[msg.sender] -= _amount;  
    coinBalance[_to] += _amount;    
    //emit transfer(_to, _amount);  
  }
}