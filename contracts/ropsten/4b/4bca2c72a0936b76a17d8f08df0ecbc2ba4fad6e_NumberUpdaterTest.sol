/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract NumberUpdaterTest { 
    
    uint8 public num;
    
    function getMyNum() public view returns (uint8) {
        return num;
    }
    
    function setMyNum(uint8 _num) public {
        num = _num;
    }
    
}