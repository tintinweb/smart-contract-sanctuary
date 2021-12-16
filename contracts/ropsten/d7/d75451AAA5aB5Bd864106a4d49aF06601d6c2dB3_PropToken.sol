// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20PresetFixedSupply.sol";

contract PropToken is ERC20PresetFixedSupply {
    // Can mint and burn but comes with an initial supply.
    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner)
        ERC20PresetFixedSupply(name, symbol, initialSupply, owner)
    { 
        // solhint-disable-previous-line no-empty-blocks 
    }
}