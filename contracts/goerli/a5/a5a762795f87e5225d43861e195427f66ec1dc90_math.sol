/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract math{
    
    uint256 number;
    
    function store(uint256 num) public{
        number = num;
    }
    
    function retrieve() public view returns(uint256){
        return number;
    }
}