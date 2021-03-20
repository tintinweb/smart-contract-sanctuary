// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10;

import './ERC20.sol';

contract CherryBlossom is ERC20 {
    constructor() ERC20("CherryBlossom", "CBL") public {
        uint TOTAL_SUPPLY = 6900000000000000000000000;
        _mint(0x29746c9D6B317c6df26Ac1751D6cB03A55C1b8d5, TOTAL_SUPPLY);
    }
}