// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";

contract MGAStablecoin is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("MGA Stablecoin", "MGAx") public {
        
    }
}