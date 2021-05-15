// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

contract GIAN is ERC20, ERC20Permit {
    constructor() ERC20("GIAN", "GIAN") ERC20Permit("GIAN") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}