// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract VIXFIN is ERC20 {
    constructor(uint256 initialSupply) ERC20("VIXFIN", "VXF") {
        _mint(msg.sender, initialSupply);
    }
}