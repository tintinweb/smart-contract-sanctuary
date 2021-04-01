// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Token is ERC20, ERC20Burnable {
    constructor () ERC20("PIXL", "PIXL") {
        _mint(msg.sender, 1000000);
    }
}