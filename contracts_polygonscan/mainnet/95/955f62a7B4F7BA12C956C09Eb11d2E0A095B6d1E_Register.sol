/**
 *Submitted for verification at polygonscan.com on 2021-12-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Register {
    event RegisterDevice(string data);
    address public proxy = 0xB9479aAd23dec5710DF70a9Ee756d211b2A7B6CC;

    function register(string memory data) public {
        require(msg.sender == proxy);
        emit RegisterDevice(data);
    }
}