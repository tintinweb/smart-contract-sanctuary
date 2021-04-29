/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Counter{
    
    uint256 private number;
    
    
    function store(uint256 _number) public {
        number = _number;
    }
    
    function retreive() public view returns (uint256) {
        return number;
    }
    
}