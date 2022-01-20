/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 private number;
    
    function store(uint256 num) public{
        number = num;
    }

    function retreive() public view returns(uint256){
        return number;
    }
}