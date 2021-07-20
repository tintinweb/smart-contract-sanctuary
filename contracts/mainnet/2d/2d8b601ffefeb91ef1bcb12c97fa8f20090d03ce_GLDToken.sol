// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";


contract GLDToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("New abc", "ABC") {
        _mint(msg.sender, initialSupply);
    }
}