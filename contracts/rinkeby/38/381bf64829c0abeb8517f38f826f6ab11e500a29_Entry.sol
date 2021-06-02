// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./erc20.sol";
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Entry is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        
    }

    function getDeveloperName() external pure returns(string memory) {
        return 'cgb';
    }
}