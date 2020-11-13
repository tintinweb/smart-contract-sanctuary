// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISprout} from "./ISprout.sol";


contract TreasuryDrip {
    IERC20 public Token;
    uint256 public blocklock;
    ISprout public bucket;

    constructor(IERC20 Tokent, ISprout buckt) public {
        Token = Tokent;
        bucket = buckt;
    }

    function tap() public {
        Token.transfer(
            bucket.treasuryDAO(),
            Token.balanceOf(address(this)) / 100
        );
        require(blocklock <= now, "block");
        blocklock = now + 1 days;
    }
}
