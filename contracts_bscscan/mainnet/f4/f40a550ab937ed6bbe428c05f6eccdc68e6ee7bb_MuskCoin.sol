// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC20.sol";

contract MuskCoin is ERC20 {
    constructor() ERC20("MuskCoin", "MSKC") {
        _mint(msg.sender, 536504312 * 10 ** decimals());
    }
}