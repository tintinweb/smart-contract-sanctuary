/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;


contract SimpleStorage {
    uint storedData;
    
    function store(uint x) public {
        storedData = x;
    }
    
    function retrieve() public view returns(uint) {
        return storedData;
    }
}