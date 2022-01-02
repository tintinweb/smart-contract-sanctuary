// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

contract ChirpCity {
    event ChirpCityMessage(address indexed from, string message);

    function chirp(string calldata message) external {
        emit ChirpCityMessage(msg.sender, message);
    }
}