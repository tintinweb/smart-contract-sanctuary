/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract Timestamp {
    event ShowTimestamp(uint _timestamp);

    function getNowTimestamp() public view returns (uint) {
        return now;
    }

    function timestamp() public {
        emit ShowTimestamp(now);
    }
}