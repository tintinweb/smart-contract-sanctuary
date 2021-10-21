pragma solidity ^0.6.2;

import "./ERC20.sol";

contract MyToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20("THREESOME", "MVSWE")public {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _mint(msg.sender, 1000000 * 10**18);
    }
}