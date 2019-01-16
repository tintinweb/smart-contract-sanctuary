pragma solidity ^0.4.25;
contract Coins {
    mapping (address => uint256) balances;
//mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    function totalSupply() public returns (uint256) {
        totalSupply = 1000;
        balances[msg.sender] =totalSupply;
        return totalSupply;
    }
    
   function transfer(address _to, uint256 _value) public payable returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer( msg.sender,_to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) constant public returns (uint256 balance) {
      return balances[_owner];
  }
    
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
   
}