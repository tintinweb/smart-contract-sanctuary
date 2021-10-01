/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract MyContract {
    string s1 = "Lorem";
    string s2 = "ipsum";
    
    function foo() external view returns (string memory, string memory) {
        return (s1,s2);
    }
}