pragma solidity ^0.4.24;

contract TUSD {
    /* This creates an array with all balances */
    mapping (address => uint256) public balances;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor ( uint256 initialSupply) public {
        balances[msg.sender] = initialSupply;          // Give the creator all the initial tokens
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value);
        require (balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
    
    function getBalance(address a) public constant returns (uint256){
        return balances[a];
    }
}