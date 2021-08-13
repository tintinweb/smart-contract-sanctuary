// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./burnable.sol";

contract Megabit is ERC20, ERC20Burnable {
    constructor() ERC20("Megabit", "MBT") {
        _mint(msg.sender, 100000000000000000000000000000);
    }
}