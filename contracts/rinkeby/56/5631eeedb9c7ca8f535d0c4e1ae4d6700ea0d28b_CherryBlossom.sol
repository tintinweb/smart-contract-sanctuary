// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10;

import './ERC20.sol';

contract CherryBlossom is ERC20 {
    constructor() ERC20("CherryBlossom", "CBM") public {
        uint INITIAL_SUPPLY = 6909090909;
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}