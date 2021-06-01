// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./TokenRecover.sol";


contract BitBase is ERC20, ERC20Burnable, ERC20Permit, TokenRecover {
    constructor() ERC20("BitBase", "BTBS") ERC20Permit("BitBase") {
        _mint(msg.sender, 60000000 * 10 ** decimals());
    }
}