/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint number; 
    event Was(uint number);
    event Becomes(uint number);
    
    function store(uint num) public{
        emit Was(number);
        require(num>10,"failure");
        number = num;
        emit Becomes(number);
    }

    function retrieve() public view returns (uint){ 
        return number;
    }

}