// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Blockchain is ERC20, ERC20Burnable {
    constructor() ERC20("Blockchain", "BBB") {
        _mint(msg.sender, 2000000000 * 10 ** decimals());
    }
}