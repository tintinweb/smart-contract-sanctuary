pragma solidity ^0.4.11;

contract MeetupToken {
    
    uint256 public totalSupply;
    mapping (address => uint256) balances;
    
    string public name;               
    uint8 public decimals;                
    string public symbol;
   
    function MeetupToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;      
        totalSupply = _initialAmount;                        
        name = _tokenName;                                   
        decimals = _decimalUnits;                            
        symbol = _tokenSymbol;                               
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function () {
        throw;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}