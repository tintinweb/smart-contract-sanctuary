// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

/**
 * @title HashString
 */
contract HashString {
    event StringHashed(address indexed _from, bytes32 _text);

    function hashString(string memory _text) public {
        emit StringHashed(msg.sender, keccak256(abi.encodePacked(_text)));
    }
}