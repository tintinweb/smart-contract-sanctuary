// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "ERC20.sol";

contract Token is ERC20 {

    constructor () ERC20("Royal Tender Regarded Democracy", "RTRD") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}