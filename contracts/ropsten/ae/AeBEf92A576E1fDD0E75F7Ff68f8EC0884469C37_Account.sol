/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Account {
    uint public balance;
    uint public constant MAX_UINT = 2**256 - 1;

    function deposit(uint _amount) public {
        //  before deposit
        uint oldBalance = balance;
        //  after deposit
        uint newBalance = balance + _amount;

        // newBalance does not overflow if newBalance >= oldBalance
        require(newBalance >= oldBalance, "Overflow");

        balance = newBalance;

        assert(balance >= oldBalance);
    }

    function withdraw(uint _amount) public {
        uint oldBalance = balance;

        // balance need to greater than amount
        require(balance >= _amount, "Underflow");

        if (balance < _amount) {
            revert("Underflow");
        }

        balance -= _amount;

        //  After withdraw
        assert(balance <= oldBalance);
    }
}