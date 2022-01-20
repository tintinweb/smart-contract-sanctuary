// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20.sol";

contract RTNToken is BEP20 {
    constructor() BEP20("RTN", "RTN") {
        _mint(msg.sender, 100000000000 * 10**18);
    }
}