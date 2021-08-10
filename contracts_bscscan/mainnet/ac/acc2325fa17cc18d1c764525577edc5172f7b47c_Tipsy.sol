// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";

contract Tipsy is ERC20 {

    uint256 public constant INITIAL_SUPPLY = 450000000 * ( 10 ** uint256(18));

    constructor () ERC20("TIPSY", "TIPSY") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}