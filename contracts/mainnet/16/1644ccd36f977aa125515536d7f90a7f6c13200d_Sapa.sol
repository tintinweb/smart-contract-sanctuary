// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20PresetMinterPauser.sol";


/**
 * @title Sapa
 * @dev MEME TOKEN FOR SAPA
 */
 
 
contract Sapa is ERC20PresetMinterPauser {
    constructor () public ERC20PresetMinterPauser("SapaToken", "SAPA") {
        _mint(msg.sender, 21000000);
    }
}