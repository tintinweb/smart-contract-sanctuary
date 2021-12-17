// SPDX-License-Identifier: CC0-1.0

pragma solidity >=0.7.0 <0.9.0;

contract Tweeter {
    event Tweet(string indexed message, address indexed from);

    function tweet(string calldata message) external {
        emit Tweet(message, msg.sender);
    }
}