// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract TestWhiteList {
    mapping(address => bool) Whitelist;

    constructor() {
        Whitelist[0x4658dC497FcAbFAb8Ae5DBB7A0f79417a9bbb8Bb] = true;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return Whitelist[_address];
    }
}