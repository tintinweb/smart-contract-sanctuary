// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TipsyLocker.sol";

contract TipsyLockerProduction is TipsyLocker {

    constructor() TipsyLocker(
        0xf380334b9A181F54BF2f32FDD3e153D259472eBB,
        0x9c01eF205F5F87adBb1419Ec52E396d08Bf7b8C4
        ) {
    }
}