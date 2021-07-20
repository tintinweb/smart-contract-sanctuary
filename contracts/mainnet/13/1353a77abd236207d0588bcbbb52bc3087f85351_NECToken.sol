// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";


contract NECToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("New era", "NEC") {
        _mint(msg.sender, initialSupply);
    }
}