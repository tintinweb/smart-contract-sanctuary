// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./H_Currency.sol";

contract HEUR is H_Currency {

    string public constant NAME = "HEdpAY HEUR Token";
    string public constant SYMBOL = "HEUR";

    function __HEUR_init() external initializer {
        __ERC20Token_init(NAME, SYMBOL);
    }

    uint256[50] private __gap;
}