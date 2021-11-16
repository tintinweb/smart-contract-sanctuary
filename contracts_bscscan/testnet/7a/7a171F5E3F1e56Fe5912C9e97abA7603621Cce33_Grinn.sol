// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Grinn is ERC20 {
    constructor(uint256 initialSupply) ERC20 ("Grinn", "GRIN") {
        _mint(msg.sender, initialSupply);
    }
}