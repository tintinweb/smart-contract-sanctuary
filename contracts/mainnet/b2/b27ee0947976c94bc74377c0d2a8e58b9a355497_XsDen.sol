// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract XsDen is ERC20 {
    constructor() ERC20("XsDen", "XD") {
        _mint(msg.sender, 20200401 * 10 ** decimals());
    }
}