// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SHIBACAT is ERC20 {
    constructor() ERC20("SHIBA CAT", "SHIBCAT") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}