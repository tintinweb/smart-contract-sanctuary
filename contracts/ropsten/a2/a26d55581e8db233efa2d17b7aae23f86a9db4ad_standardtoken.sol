pragma solidity ^0.4.24;

contract token {
    mapping(address => uint)balances;
    event Transfer(address _from,address _to,uint _value);
    
    function balanceOf(address _owner) public constant returns(uint balance) {
        return _owner.balance;
    }
    function transfer(address _to,uint _value) public returns(bool success) {
        if( balances[msg.sender] >= _value && _value >= 0){
            balances[_to] += _value;
            balances[msg.sender] -= _value;
            emit Transfer(msg.sender,_to,_value);
            return true;
            
        }
        else{
            return false;
        }
    }
}

contract standardtoken is token {
    function testCoin () public returns(uint _value) {
        balances[msg.sender] = 1000;
        _value = balances[msg.sender];
        return _value;
    }
}