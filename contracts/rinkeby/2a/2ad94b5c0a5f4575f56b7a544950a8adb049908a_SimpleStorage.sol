/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract SimpleStorage {
    uint storeData; 
    
    
    function set(uint x) public {
        storeData = x;
    }
    
    function get() public view returns (uint) {
        return storeData;
    }
}