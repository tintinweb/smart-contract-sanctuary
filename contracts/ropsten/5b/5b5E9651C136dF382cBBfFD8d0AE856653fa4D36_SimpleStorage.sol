/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SimpleStorage {
    uint public storedData;
    
    function set(uint x) public {
        storedData = x;
    }
    
    function get() public view returns(uint getVal) {
        return storedData;
    }
}