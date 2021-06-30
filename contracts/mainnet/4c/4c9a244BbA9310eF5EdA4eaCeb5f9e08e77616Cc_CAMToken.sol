// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract CAMToken is ERC20, ERC20Detailed {
    constructor(uint256 initialSupply) ERC20Detailed("CAM Token", "CAM", 0) public {
        _mint(msg.sender, initialSupply);
        _initManagers(msg.sender);
    }
}