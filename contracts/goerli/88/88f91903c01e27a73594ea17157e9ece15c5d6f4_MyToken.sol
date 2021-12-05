// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("Tang Metaverse Game", "TMG") {
        _mint(_msgSender(), 100000000 * 10 ** decimals());
    }
}