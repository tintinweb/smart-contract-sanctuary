// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract PEACOCK is ERC20 {
    constructor(uint256 initialSupply) public ERC20("PEACOCK", "PCK") {
        _mint(msg.sender, initialSupply);
    }
}