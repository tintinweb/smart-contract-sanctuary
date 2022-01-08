// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Feather is ERC20, ERC20Burnable {
    constructor() ERC20("Feather", "FEATHER") {
        _mint(msg.sender, 1000000000 * 10**decimals());
    }
}