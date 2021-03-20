// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10;

import './ERC20.sol';

contract TestingToken is ERC20 {
    constructor() ERC20("CherryBlossom", "CBL") public {
        uint TOTAL_SUPPLY = 6900000000000000000000000;
        _mint(0x9ac11CFDe2AEBBe11900D1B551740776460Aa975, TOTAL_SUPPLY);
    }
}