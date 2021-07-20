// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TipsyLocker.sol";
import "./HoldersWhiteList.sol";

contract TipsyLockerWhiteListed is TipsyLocker {

    HoldersWhiteList private _whiteList = new HoldersWhiteList();

    constructor() TipsyLocker(
        0xe5773fbC12472F2f860E23322cf8c8DE7820bc8C,
        0x9c01eF205F5F87adBb1419Ec52E396d08Bf7b8C4
        ) {
    }

    function deposit(uint256 amount) override public {
        require(_whiteList.exists(msg.sender));
        super.deposit(amount);
    }
}