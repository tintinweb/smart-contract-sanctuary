/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

contract Counter {
    uint public count = 0; 

    function incrementCount() public {
        count = count + 1; 
    }
}