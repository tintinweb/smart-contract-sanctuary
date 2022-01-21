/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT
 
pragma solidity >=0.8.0 <0.9.0;

contract counter {
    uint public count = 0;
    function increment () public returns(uint) {
        count +=2;
        return count;
        
    }
}