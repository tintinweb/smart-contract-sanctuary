/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//means extends contract
contract TestBenson {
    function sayHello() public pure returns (string memory) {
        return ("Hello World");
    }

    function echo(string memory name) public pure returns (string memory) {
        return name;
    }
}