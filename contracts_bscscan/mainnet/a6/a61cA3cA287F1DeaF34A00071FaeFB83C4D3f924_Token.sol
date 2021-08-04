// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Token is ERC20Detailed {

    /**
     * @dev Constructor that gives developper admin rights
     */
    constructor () ERC20Detailed("Duino Coin on BSC", "bscDUCO", 18) {
		AdminAddress = msg.sender;
    }
}