/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.5.13;

contract Bank {
    uint256 balance;
    uint256 public MAX_UINT = 2**256 - 1;

    constructor() public {
        balance = 1; //initial balance
    }

    function getBalance1() public view returns (uint256) {
        return balance;
    }

    function deposit(uint256 amount) public {
        //balance + amount does not overflow if balance + amount >= balance
        uint256 oldBalance = balance;
        uint256 newBalance = balance + amount;
        require(newBalance >= oldBalance, "Overflow"); //this condition needs to be true to update the balance
        balance = newBalance;
        assert(balance >= oldBalance); // this assertion should always evaluate to true
    }

    function withdraw(uint256 amount) public {
        //balance - amount does not underflow if balance >= amount
        uint256 oldBalance = balance;
        //comment this
        require(balance >= amount, "Underflow");
        // or comment this
        if (balance <= amount) {
            revert("Underflow"); // if condition is to check if more complex using revert is preferred
        }
        balance = balance - amount;
        assert(balance <= oldBalance); // this assertion should always evaluate to true
    }
}