/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Play {
    error Dudidu();


    function sad() public payable {
        if (msg.value > 0) 
            revert Dudidu();
    }
}