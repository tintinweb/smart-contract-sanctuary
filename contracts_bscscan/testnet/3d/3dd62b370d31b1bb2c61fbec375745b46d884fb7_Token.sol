// SPDX-License-Identifier: TIM

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token is ERC20 {

    constructor () ERC20("RHToken", "RHT") {
        _mint(msg.sender, 50000000 * (10 ** uint256(decimals())));
    }
}