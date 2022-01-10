/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT

    pragma solidity ^0.8.0;

    contract MyContract {
        string _name;
        uint _balance;

        constructor (string memory name , uint balance) {
            require(balance >= 500, "Balance must equal to 500 Bath or more than");
            _name = name;
            _balance = balance;
        }

        function getBalance() public view returns(uint balance) {
            return _balance;
        }

        function desposit(uint amount) public {
            require(amount > 0, "Please desposit more than 0 Bath. You Know!");
            _balance += amount;
        } 

        function withdraw(uint money) public {
            require(money > 0, "Please withdraw more than 0 Bath. You Know!");
            _balance -= money;
        }

    }