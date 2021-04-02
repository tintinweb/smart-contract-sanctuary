/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    
   string store = "abcdef";
    
    function getStore() public view returns (string memory) {
        return store;
    }
    
    function setStore(string memory _value) public {
        store = _value;
    }
}