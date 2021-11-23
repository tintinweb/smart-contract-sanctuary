// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Lucy is ERC20, ERC20Burnable {
    constructor() ERC20("Lucy", "LUCY") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}