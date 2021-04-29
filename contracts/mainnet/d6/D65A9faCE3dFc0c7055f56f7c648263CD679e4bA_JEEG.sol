// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract JEEG is ERC20 {
    constructor() ERC20("JEEG", "JEEG") {
        _mint(msg.sender, 500000000000 * 10 ** decimals());
    }
}