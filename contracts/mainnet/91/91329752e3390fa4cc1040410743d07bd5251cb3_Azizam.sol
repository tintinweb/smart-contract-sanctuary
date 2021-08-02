// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Burnable.sol";

contract Azizam is ERC20PresetFixedSupply {
    constructor() ERC20PresetFixedSupply("Azizam", "AZM", 1000000 * 10 ** 18, msg.sender) {
    }
}