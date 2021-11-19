/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Counter {
    uint public count = 0; 

    function incrementCount() public {
        count = count + 2;
    }
}