// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20.sol';
import './ERC20Burnable.sol';

contract SFIRE is ERC20, ERC20Burnable {
    constructor(address owner, uint256 initialSupply) ERC20("SFIRE", "SFIRE") {
        _mint(owner, initialSupply);
    }
}