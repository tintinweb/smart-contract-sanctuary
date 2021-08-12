/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Increment {
    uint public x = 0;
    
    function increment(uint y) public {
        x = x + y;
    }
}