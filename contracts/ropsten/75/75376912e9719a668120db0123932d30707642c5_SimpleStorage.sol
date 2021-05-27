/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract SimpleStorage {
    // State variable to store a number
    uint public num;
    
    function set(uint _num) public {
        num = _num;
    }
    
    function get() public view returns(uint) {
        return num;
    }
}