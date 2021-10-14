// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC20.sol";

contract BSTv2 is ERC20 {

    uint256 public constant INITIAL_SUPPLY = 2500000000 * ( 10 ** uint256(9));

    constructor () ERC20("BSTv2", "BSTv2") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}