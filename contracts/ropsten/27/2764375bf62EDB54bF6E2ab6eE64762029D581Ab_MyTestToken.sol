// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract MyTestToken is ERC20 {
    constructor() ERC20("My Test Token", "MTTK") {
        _mint(msg.sender, 3337777777 * 10 ** decimals());
    }
}