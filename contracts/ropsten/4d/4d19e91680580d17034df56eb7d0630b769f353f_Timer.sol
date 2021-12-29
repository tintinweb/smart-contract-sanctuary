/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Timer {
    uint256 private currentTime;

    constructor() {
        currentTime = 0;
    }

    function setTime(uint256 _newTime) public {
        currentTime = _newTime;
    }

    function getTime() public view returns (uint256) {
        return currentTime;
    }
}