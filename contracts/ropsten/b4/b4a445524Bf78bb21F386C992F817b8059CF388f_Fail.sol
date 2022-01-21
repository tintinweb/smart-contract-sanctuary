// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract Fail {
    function fail() external {
        require(msg.sender == address(0), "Nope");
    }
}