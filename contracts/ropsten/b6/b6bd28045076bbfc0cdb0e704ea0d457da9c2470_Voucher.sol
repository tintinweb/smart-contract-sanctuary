/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity >= 0.6.0;

contract Voucher {
    
    // A mapping is like a dictionary in Python.
    mapping(address=>uint256) public balances;
    
    constructor() {
        // The sender inside the constructor is the creator of the contract.
        balances[msg.sender] = 100; // This number is arbitrarily chosen.
    }
    
    function transfer(address _to, uint256 _value) public {
        
        require(balances[msg.sender] >= _value, "Not enough funds.");
        // transfer tokens from msg.sender (msg is a global object) to _to
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        // All the contracts are atomic, so they are completed or they are reverted.
    }
}