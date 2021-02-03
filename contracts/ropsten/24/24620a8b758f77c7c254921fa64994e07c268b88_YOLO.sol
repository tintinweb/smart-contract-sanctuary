// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./ERC20Permit.sol";
import "./ERC20Burnable.sol";

contract YOLO is ERC20Permit, ERC20Burnable {
    constructor(uint256 initialSupply) ERC20("You Only Live Once", "YOLO") EIP712("You Only Live Once", "1") {
        _mint(msg.sender, initialSupply);
    }
}