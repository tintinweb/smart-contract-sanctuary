// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ERGTrade is ERC20 {
    constructor(uint256 initialSupply) ERC20("ERGTrade", "ERGT") {
        _mint(msg.sender, initialSupply);
    }
}