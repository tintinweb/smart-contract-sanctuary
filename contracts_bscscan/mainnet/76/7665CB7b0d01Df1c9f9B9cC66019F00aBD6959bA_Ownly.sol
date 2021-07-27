// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20PresetFixedSupply.sol";

contract Ownly is ERC20PresetFixedSupply {
    constructor() ERC20PresetFixedSupply ("Ownly", "OWN", 10000000000 * 10**18, 0x672b733C5350034Ccbd265AA7636C3eBDDA2223B) {}
}