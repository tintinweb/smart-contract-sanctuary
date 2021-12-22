// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";


contract NguyenVanDatToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 n) ERC20(name, symbol) {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _mint(msg.sender, n * 10**uint(decimals()));
    }
}