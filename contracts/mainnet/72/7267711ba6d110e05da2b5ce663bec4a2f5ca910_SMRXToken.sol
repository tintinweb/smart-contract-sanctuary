// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

contract SMRXToken is ERC20 {
    constructor(uint256 supply) ERC20("Samsara", "SMRX") {
        _mint(msg.sender, supply * (10 ** decimals()));
    }
}