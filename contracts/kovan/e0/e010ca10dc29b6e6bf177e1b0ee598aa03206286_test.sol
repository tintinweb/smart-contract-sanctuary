/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract test {
    struct Test {
        address aaa;
        address bbb;
    }
    
    mapping (address => Test) testsPerAddress;
    
    function change() public {
        testsPerAddress[msg.sender].aaa = msg.sender;
    }
}