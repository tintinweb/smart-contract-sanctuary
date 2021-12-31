/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract Test {
    bool public canTrade = false;

    constructor () {}
    
    function allowTrading() external {
        canTrade = true;
    }
}