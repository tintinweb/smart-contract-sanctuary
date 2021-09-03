/**
 *Submitted for verification at polygonscan.com on 2021-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Counter {
    uint256 public count = 0;
    
    function getCount() view public returns(uint256){
        return count;
    }
    
    function increment() public {
        count++;
    }
}