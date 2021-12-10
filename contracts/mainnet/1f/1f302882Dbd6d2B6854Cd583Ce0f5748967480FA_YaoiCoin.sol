// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

contract YaoiCoin is ERC20 {
    constructor() ERC20("YaoiCoin", "YAOI") {
        _mint(msg.sender, 5000000000000000000 * 10 ** decimals());
    }
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}