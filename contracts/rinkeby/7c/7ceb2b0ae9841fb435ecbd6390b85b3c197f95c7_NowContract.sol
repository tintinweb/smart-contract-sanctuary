//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

contract NowContract {
    uint32 public nowValue = 0;

    constructor () {
        computeNow();
    }

    function computeNow() public {
        nowValue = uint32(block.timestamp);
    }
}

