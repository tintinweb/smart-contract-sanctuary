/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract MyStorage {

  
    function store(uint256 num) public {}
 
    function retrieve() public view returns (uint256){}
  
    function increaseByOne() external returns (uint256) {}
  
     function decreaseByOne() external returns (uint256) {}
     
    function multiply(uint256 num1, uint256 num2) external pure returns (uint256) {}
  
}


contract MyCall {
    MyStorage ms;
    
    function store(uint256 num) external {
        ms = MyStorage(0xAEf0A674B55F1D2C07C3A6F0aA6538a22a0b4D26);
        ms.store(num);
        uint256 result = ms.increaseByOne();
        emit ShowResult(result);
    }
    
    event ShowResult(uint256);
}