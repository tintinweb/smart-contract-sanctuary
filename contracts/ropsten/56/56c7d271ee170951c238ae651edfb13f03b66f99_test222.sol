pragma solidity ^0.4.18;

contract Token {

    // total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    // return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    // return transfer results
    function transfer(address _to, uint256 _value) returns (bool success) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract StandToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        // check total num , sender&#39;s balance
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    mapping (address => uint256) balances;
    uint256 public totalSupply;
}

contract test222 is StandToken {

    /* Public variables of the token */
    string public name;                   // Token Name
    uint8 public decimals;                // decimals to show
    string public symbol;                 // symbol
    
    //constructor function 
    constructor() {
        totalSupply = 3 * 1000 * 1000 * 1000;   // totalSupply
        balances[msg.sender] = totalSupply;               
        
        name = "test222";                       // coin name
        decimals = 18;                          // decimals
        symbol = "TS";                          // symbol
    }
}