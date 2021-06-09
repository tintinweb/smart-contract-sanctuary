// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract XASHTOKEN is ERC20 {
    constructor() ERC20("XASHTOKEN", "XASH") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}