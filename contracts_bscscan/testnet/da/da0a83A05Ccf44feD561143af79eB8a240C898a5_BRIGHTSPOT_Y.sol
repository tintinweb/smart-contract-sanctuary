// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

/**
 * @title Brightspot
 */
contract BRIGHTSPOT_Y is ERC20, ERC20Burnable {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("BRIGHTSPOT_Y", "BRIY") {
        _mint(msg.sender, 105000000000 * (10 ** uint256(decimals())));
    }
}