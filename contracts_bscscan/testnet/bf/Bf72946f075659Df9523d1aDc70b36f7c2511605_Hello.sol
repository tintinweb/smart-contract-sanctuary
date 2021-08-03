// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Hello is ERC20 {
    constructor() ERC20("Hello", "ALOHA") {
        _mint(msg.sender, 1000 * 10e18);
    }
}