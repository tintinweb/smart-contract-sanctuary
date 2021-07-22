// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20PresetFixedSupply.sol";

contract Tae is ERC20PresetFixedSupply {
    constructor() ERC20PresetFixedSupply ("Taeng Mabaho", "TAE", 10000000000 * 10**18, 0x768532c218f4f4e6E4960ceeA7F5a7A947a1dd61) {}
}