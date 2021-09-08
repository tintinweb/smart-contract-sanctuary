/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract Counter {
    uint public count;
    
    function increment() external {
        count += 1;
    }
}