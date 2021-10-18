//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import './ERC20.sol';

contract Deploy is ERC20{

    constructor(string memory symbol, string memory name, uint256 supply, address to) ERC20(name, symbol) {
        _mint(to, supply);

    }

}