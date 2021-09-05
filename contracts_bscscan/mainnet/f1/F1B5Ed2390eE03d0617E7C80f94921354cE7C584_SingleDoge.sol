// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SingleDoge is ERC20 {
    constructor() ERC20("Coin Hunters", "CHTR") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}