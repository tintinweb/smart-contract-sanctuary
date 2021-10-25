/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.9;

contract SimpleStorage {
    
    uint internal storedData;
    
    constructor(uint x) {
        storedData = x;
    }
    
    function set(uint x) public {
        storedData = x;
    }
    
    function get() public view returns(uint) {
        return storedData;
    }
    
}