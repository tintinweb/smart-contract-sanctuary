// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
/**
 *  @dev An ERC20 token for MATE. 
 *  Welcome to Vmates World
 *     Official Website: https://www.vmates.io
 *     Twitter: https://twitter.com/Vmates_official
 *     Telegram Group: https://t.me/vmatescommunity
 *  Enjoy your new life!
 */
contract VmatesToken is ERC20 {
    /**
     * @dev Constructor.
     */
    constructor(
    )
        ERC20("Vmates Token", "MATE")
    {   
        _mint(msg.sender, 20000000 * 10 ** 18); // 20 million
    }

}