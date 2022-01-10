pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "ERC20.sol";

contract Crown is ERC20 {

    uint256 constant public tSupply = 200_000_000 * 1e18;

    constructor() ERC20("Space Crown", "SMCW") {
        _mint(msg.sender, tSupply);
    }
}