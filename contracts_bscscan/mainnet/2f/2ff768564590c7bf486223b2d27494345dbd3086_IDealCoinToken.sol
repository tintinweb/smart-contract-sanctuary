// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";

contract IDealCoinToken is ERC20 {
    constructor() ERC20("IDealChain", "IDC") 
    {
        // Mint 21.000.000 tokens to msg.sender
        // Initially, the token creator (contract deployer) will have 21.000.000 tokens
        _mint(msg.sender, 21000000 * 10**uint(decimals()));
    }

    function burn(uint256 amount) public virtual
    {
        _burn(msg.sender, amount);
    }
}