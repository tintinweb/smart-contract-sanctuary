/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.2;

contract AGreeter {
    string private greeting = "abc";

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}