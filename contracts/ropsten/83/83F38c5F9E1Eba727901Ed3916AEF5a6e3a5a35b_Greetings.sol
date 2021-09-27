/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.4.26;



// File: Greetings.sol

contract Greetings {
        string message;

        function Greetings() {
            message = "I am ready";
        }

        function setGreetings (string _message) {
            message = _message;
        }

        function getGreetings() constant returns (string) {
            return message;
        }
}