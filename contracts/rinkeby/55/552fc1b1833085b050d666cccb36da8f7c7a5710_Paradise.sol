// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Paradise is ERC20 {
    /**
     * @dev Sets the values for {name}, {symbol} and set the {supply}
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() ERC20 ("Paradise", "PRISE") {
        uint256 supply = 589738956207003000000000000000000;
        _mint(msg.sender, supply);
    }
}