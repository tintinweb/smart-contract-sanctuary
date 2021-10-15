// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @title Brightspot
 */
contract BRIGHTSPOT is ERC20 {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("BRIGHTSPOT", "BRIA") {
        _mint(msg.sender, 1800000000 * (10 ** uint256(decimals())));
    }
}