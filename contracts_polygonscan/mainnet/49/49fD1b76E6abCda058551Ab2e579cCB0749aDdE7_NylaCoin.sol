// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract NylaCoin is ERC20 {
    constructor(uint256 initial_supply) ERC20("NylaCoin", "NYLA") {
        _mint(msg.sender, initial_supply);
    }
}