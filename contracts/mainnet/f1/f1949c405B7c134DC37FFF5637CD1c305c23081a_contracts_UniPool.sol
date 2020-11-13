// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface notify {
    function notifyRewardAmount(uint256 reward) external;
}

contract UTap {
    IERC20 public Token;
    notify public Pool;
    uint256 public blocklock;
    address public bucket;

    constructor(
        IERC20 Tokent,
        address buckt,
        notify Poolt
    ) public {
        Token = Tokent;
        bucket = buckt;
        Pool = Poolt;
    }

    function tap() public {
        require(tx.origin == msg.sender, "UTap: External accounts only");
        require(blocklock <= now, "block");
        Token.transfer(bucket, Token.balanceOf(address(this)) / 50);
        blocklock = now + 7 days;
        Pool.notifyRewardAmount(Token.balanceOf(address(this)) / 50);
    }
}
