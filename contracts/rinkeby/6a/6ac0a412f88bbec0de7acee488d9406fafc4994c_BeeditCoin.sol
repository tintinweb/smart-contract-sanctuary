// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";

contract BeeditCoin is ERC20PresetMinterPauser {
    constructor(uint256 initialSupply)
        ERC20PresetMinterPauser("Honey Money", "HON")
    {
        _mint(msg.sender, initialSupply);
    }
}