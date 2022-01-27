// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.11;

import "./ERC20.sol";

contract AfroAmericanToken is ERC20 {
    constructor() ERC20("AfroAmericanCoin", "AFRO") {
        _mint(msg.sender, 10 * 1000000 * 1000000000000000000 );
    }
}