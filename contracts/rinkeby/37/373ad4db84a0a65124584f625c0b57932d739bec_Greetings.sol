/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-07
*/

pragma solidity ^0.4.11;


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