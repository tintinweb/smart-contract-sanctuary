pragma solidity ^0.4.25;
contract Coinsnik {
    mapping (address => uint256) balances;
  
    constructor(uint initialSupply) payable public{
   
        balances[msg.sender] =initialSupply;
    }
   function transfer(address _to, uint256 _value) public payable returns (bool success) {
        // if (balances[msg.sender] >= _value && _value > 0) {
        //     balances[msg.sender] -= _value;
        //     balances[_to] += _value;
            emit Transfer( msg.sender,_to, _value);
            return true;
      
    }
    function balanceOf(address _owner) constant public returns (uint256 balance) {
      return balances[_owner];
  }
    
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
   
}