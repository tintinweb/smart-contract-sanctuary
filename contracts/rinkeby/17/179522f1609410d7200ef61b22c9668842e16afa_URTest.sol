// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC20.sol";

contract URTest is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}