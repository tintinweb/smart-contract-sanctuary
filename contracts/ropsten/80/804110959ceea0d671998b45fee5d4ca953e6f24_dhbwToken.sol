// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OZ-ERC20.sol";

contract dhbwToken is ERC20 {
    constructor() ERC20 ("DHBW-Token", "DHBW"){
        _mint(msg.sender, 1000000 * 10 ** (uint256(decimals())));
    }
}