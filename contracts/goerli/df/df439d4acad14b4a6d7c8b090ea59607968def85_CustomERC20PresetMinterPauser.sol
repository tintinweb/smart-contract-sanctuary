// File: contracts/CustomERC20PresetMinterPauser.sol
import "./ERC20PresetMinterPauser.sol";
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract CustomERC20PresetMinterPauser is ERC20PresetMinterPauser {
    constructor(string memory name, string memory symbol, uint8 decs) public ERC20PresetMinterPauser(name, symbol) {
        _setupDecimals(decs);
    }
}