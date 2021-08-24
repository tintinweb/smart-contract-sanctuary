//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";


contract RaiderAurumToken is ERC20PresetMinterPauser {
    // initate the Aurum token and create 1,000,000,000 of it 
    constructor () ERC20PresetMinterPauser("RaiderAurum", "AURUM") {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
    
}