// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Shish is ERC20 {
    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 100500 * 10 ** uint(decimals()));
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}