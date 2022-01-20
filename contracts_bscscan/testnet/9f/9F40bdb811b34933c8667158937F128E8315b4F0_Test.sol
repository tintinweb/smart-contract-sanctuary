/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.0;

contract Test{
    uint public lanuchAt;

    function setLanuch() public{
        lanuchAt = block.timestamp;
    }
}