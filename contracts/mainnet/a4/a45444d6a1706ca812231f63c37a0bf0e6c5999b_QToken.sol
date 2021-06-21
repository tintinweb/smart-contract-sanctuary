// SPDX-License-Identifier: MIT

// Speech on the blockchain cannot be censored.
//
// Token-powered smart contracts will take us where the mainstream media wouldn't dare.
//
// Acquire tokens from airdrop recipients. You can find them in /qresearch/.

pragma solidity ^0.8.0;

import "ERC20.sol";

contract QToken is ERC20 {
    constructor () ERC20('Q', 'WWG1WGA') {
        _mint(msg.sender, 17000000 * 10 ** uint(decimals()));
    }
}