//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import './ERC20.sol';
import './Context.sol';

contract Deploy is ERC20{

    constructor(string memory symbol, string memory name, uint256 supply) ERC20(name, symbol) {
        _mint(_msgSender(), supply);

    }

}