pragma solidity ^0.4.24;

contract checkBal{
   mapping (address => uint256) balances;
   mapping (address => mapping (address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function balanceOf(address _owner)public constant returns (uint256 balance) {
        return _owner.balance;
    }
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(msg.sender,_to,msg.value);
            Transfer(_from,_to,_value);
            return true;
        } else { return false; }
    }
     function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
}