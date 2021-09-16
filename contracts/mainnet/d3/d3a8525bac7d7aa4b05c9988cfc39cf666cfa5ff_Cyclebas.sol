// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

contract Cyclebas is ERC20 {
    constructor() ERC20("cyclebas", "cycion") {
        _mint(msg.sender, 500000000 * 10 ** decimals());
    }
}