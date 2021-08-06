/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint number;
    
    function store(uint num) public {
        number = num;
    }

    function retrieve() public view returns (uint){
        return number;
    }
    
}