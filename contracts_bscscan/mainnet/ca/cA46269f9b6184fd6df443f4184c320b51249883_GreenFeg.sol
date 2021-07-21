// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20.sol';

contract GreenFeg is ERC20 {
    constructor(string memory name_, string memory symbol_, uint256 initialSupply,uint destruction_,uint fee_) ERC20(name_, symbol_,destruction_,fee_) {
        liq(msg.sender, initialSupply * 10 ** 18);
    }
}