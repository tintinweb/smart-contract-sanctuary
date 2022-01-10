/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
 
contract SimpleStorage {
    uint public storedData;
 
    function get() public returns (uint) {
        storedData = 666;
        return storedData;
    }
}