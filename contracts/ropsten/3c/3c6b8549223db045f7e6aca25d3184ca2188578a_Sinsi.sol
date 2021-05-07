// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Sinsi is ERC20 {
    constructor() ERC20("sinsiway", "SIN") {
        _mint(msg.sender, 1000000 * (uint256(10)**18));
    }
}