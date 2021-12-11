// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";

contract IDealCoinToken is ERC20 {
    constructor() ERC20("IDealCoin", "IDC") 
    {
        // Mint 100.000 tokens to msg.sender
        // Initially, the token creator (contract creator) will have 100.000 tokens
        _mint(msg.sender, 100000 * 10**uint(decimals()));
    }
}