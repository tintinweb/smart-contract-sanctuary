/**
 *Submitted for verification at Etherscan.io on 2021-09-28
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
    
    function changeLocal() public {
        Test storage test2 = testsPerAddress[msg.sender];
        test2.aaa = msg.sender;
    }
}