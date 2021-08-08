/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract QuyLop {
    string private Ten;
    
    function setTen(string memory ten) public {
        Ten = ten;
    }
    
    function getTen() public view returns (string memory) {
        return Ten;
    }
}