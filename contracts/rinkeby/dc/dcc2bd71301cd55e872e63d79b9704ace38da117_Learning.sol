/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Learning {
    
    int256 someNum;
    
    
    function setSomeNum(int256 _someNum) public {
        someNum = _someNum;
    }
    
    function getSomeNum() public view returns(int256) {
        return someNum;
    }
    
}