// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Burnable.sol";

contract ChineseFreedom is ERC20PresetFixedSupply {
    constructor() ERC20PresetFixedSupply("ChineseFreedom", "CF", 1000000 * 10 ** 18, msg.sender) {
    }
}