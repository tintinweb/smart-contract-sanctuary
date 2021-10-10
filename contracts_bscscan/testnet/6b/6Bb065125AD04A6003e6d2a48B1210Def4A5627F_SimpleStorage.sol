/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

pragma solidity ^0.8.3;

contract SimpleStorage {
    // State variable to store a number
    uint public balance;

    // You need to send a transaction to write to a state variable.
    function deposit(uint num) public {
        balance += num;
    }
    
    function withdraw(uint num) public {
        balance -= num;
    }

    // You can read from a state variable without sending a transaction.
    function get() public view returns (uint) {
        return balance;
    }
}