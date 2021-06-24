// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ELira is ERC20 {
    constructor() ERC20("eLira", "LIR") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}