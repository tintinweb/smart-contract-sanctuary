// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./H_Currency.sol";

contract HCAD is H_Currency {

    string public constant NAME = "HEdpAY HCAD Token";
    string public constant SYMBOL = "HCAD";

    function __HCAD_init() external initializer {
        __ERC20Token_init(NAME, SYMBOL);
    }

    uint256[50] private __gap;
}