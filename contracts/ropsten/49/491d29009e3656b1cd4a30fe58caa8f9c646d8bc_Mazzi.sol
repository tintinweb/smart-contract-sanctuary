// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC20_flat.sol";

contract Mazzi is ERC20 {
    constructor(uint256 initialSupply) public ERC20 ("Mazzi", "MAZZI"){
        _mint(msg.sender, initialSupply);
        }
}