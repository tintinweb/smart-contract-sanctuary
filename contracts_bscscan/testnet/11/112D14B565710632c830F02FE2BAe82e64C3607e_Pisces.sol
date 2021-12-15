// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Pisces is ERC20 {
    constructor() ERC20("Pisces", "PC") {
_mint(msg.sender, 100000000 * 10 ** decimals());
    }
}