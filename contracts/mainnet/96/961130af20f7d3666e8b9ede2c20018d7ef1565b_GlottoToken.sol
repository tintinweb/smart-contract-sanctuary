// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./ERC20Optional.sol";

contract GlottoToken is ERC20Optional {
    uint256 private _initial_supply = 10000000000 * ( 10 ** 18 );

    constructor() public ERC20("GlottoToken", "GLTT") {
        _mint(msg.sender, _initial_supply);
    }
}