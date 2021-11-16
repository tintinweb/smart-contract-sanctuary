/**
 *Submitted for verification at polygonscan.com on 2021-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
 
 contract Counter{
     
     uint256 public count = 0;
     
     function increment() public returns(uint) {
        count +=1;
        return count;
     }
 }