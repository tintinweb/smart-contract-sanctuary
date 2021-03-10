// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract RootERC20 is ERC20 {
    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {}

    function mint(uint256 amount) public returns (bool) {
        _mint(_msgSender(), amount);

        return true;
    }
}