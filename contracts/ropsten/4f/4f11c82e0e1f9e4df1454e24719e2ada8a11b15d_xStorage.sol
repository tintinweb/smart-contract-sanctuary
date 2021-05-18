/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract xStorage {
    
    uint256 xData;
    
    function setData(uint256 dataToSet) external {
        xData = dataToSet;
        
    }
    
    function getData() public view returns (uint256) {
        return xData;
    }
    
    
    
    
    
    
}