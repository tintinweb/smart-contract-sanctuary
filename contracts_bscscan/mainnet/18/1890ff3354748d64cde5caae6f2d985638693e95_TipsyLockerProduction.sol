// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TipsyLocker.sol";

contract TipsyLockerProduction is TipsyLocker {

    constructor() TipsyLocker(
        0xAcC2325fA17CC18d1C764525577EDc5172F7b47C,
        0x9c01eF205F5F87adBb1419Ec52E396d08Bf7b8C4
        ) {
    }
}