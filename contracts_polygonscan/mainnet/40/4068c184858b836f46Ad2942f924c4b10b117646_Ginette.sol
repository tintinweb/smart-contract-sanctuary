// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Ginette is ERC20, ERC20Burnable {
    constructor() ERC20("Ginette", "GINA") {
        _mint(msg.sender, 1000000000 * 10**decimals());
    }
}