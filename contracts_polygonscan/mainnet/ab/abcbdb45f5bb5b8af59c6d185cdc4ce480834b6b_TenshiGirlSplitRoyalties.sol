/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract TenshiGirlSplitRoyalties {

    function split(address[] memory tokenOwners, uint[] memory amounts) external payable {
        require(tokenOwners.length == amounts.length, "Must have the same length!");
        for(uint i = 0; i < tokenOwners.length; i++) {
            payable(tokenOwners[i]).transfer(amounts[i]);
        }
    } 
}