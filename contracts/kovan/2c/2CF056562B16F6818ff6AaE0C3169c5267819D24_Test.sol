/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test{
    
    uint256 public testNumber;
    uint256 public testNo;
    
    constructor(){
        testNumber = 1;
        testNo = 1;
    }
    function calculation (uint256 a) external {
        testNumber += a;
    }
    
    function calcPublic (uint256 b) public {
        testNo +=b;
    }
}