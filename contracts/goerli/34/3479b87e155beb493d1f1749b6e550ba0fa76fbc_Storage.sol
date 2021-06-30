/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.8;

contract Storage {
    
    uint256 private number;
    
    function store(uint256 num) public {
        number = num;
    }
    
    function retreive() public view returns (uint256){
        return number;
    }
}