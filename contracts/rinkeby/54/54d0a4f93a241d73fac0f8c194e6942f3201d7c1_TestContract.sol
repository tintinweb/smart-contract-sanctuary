/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.5.0;

contract TestContract {
    
    uint balance = 50100;
    
    // Getter function
    function getBalance() public view returns(uint) {
        return balance;
    }
    
    // Setter function
    function deposit(uint _amount) public {
        balance = balance + _amount;
    }
    
}