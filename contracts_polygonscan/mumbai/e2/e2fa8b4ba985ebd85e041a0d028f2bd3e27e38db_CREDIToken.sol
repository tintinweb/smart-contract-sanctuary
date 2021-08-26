// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.7;

import "./ERC20CHILD.sol";

contract CREDIToken is ERC20 {
    constructor() ERC20("TESTCR1", "TESTCR1", 0xb5505a6d998549090530911180f38aC5130101c6) {
        uint8 decimals = 18;
        _mint(
            0 * 10**decimals,
            decimals,
            0x0Ba4f79732a70c8428b18f8506d60fF7b581F349
        );
    }
}