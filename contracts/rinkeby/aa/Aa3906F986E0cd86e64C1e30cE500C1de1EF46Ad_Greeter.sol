/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Greeter {
    string public greeting = "Hello world";

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}