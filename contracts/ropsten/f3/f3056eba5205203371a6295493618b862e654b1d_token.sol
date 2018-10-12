pragma solidity ^0.4.24;

contract token{
    mapping (address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    constructor(uint256 intialsupply) public payable {
        balances[msg.sender] = intialsupply;
    }
    function balanceOf(address _owner)public constant returns (uint256 balance) {
        return _owner.balance;
    }
    
     function transfer(address _to, uint256 _value) public returns (bool success) {
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
 }