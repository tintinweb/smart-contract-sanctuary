// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";

contract TFI is ERC20 {
    constructor (string memory name, string memory symbol) ERC20(name, symbol) public {
        _mint(msg.sender, 1000000000 * 10 ** uint(decimals()));
    }
}