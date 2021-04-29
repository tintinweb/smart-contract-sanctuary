// contracts/Coinhub Token.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CoinhubToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Coinhub Token", "CHB") {
        _mint(msg.sender, initialSupply);
    }
}