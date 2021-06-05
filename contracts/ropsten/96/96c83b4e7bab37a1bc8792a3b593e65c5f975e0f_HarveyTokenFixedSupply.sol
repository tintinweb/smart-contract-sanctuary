// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract HarveyTokenFixedSupply is ERC20Burnable {
    string private tokenName = "HarveyTestFixedSupply";
    string private tokenTicker = "HTFS";
    uint256 private tokenSupply = 1000000;


    constructor() public ERC20(tokenName, tokenTicker){
        _mint(msg.sender, tokenSupply);
    }
}