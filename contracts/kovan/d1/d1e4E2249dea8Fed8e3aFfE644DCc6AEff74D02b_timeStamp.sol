// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

contract timeStamp {
    function blockTimeStampValue() external view returns (uint timeStamp) {
        timeStamp = block.timestamp;
    }
}