// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract StandardToken is ERC20 {
    constructor() ERC20("ERC Token", "FTG") {
        _mint(msg.sender, 80000000 * 10 ** decimals());
    }
}