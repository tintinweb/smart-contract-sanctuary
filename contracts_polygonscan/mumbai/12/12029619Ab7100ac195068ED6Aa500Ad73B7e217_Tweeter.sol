// SPDX-License-Identifier: CC0-1.0

pragma solidity >=0.7.0 <0.9.0;

contract Tweeter {
    event Tweet(address indexed from, string indexed message);

    function tweet(string calldata message) external {
        emit Tweet(msg.sender, message);
    }
}