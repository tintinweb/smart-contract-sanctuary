/*
GeyserToken

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

// pragma solidity 0.8.4;
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

/**
 * @title GYSR token
 *
 * @notice simple ERC20 compliant contract to implement GYSR token
 */
contract CashFlash is ERC20 {
    uint256 DECIMALS = 18;
    uint256 TOTAL_SUPPLY = 10 * 10**10 * 10**DECIMALS;

    constructor() ERC20("CashFlash", "CFT") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}