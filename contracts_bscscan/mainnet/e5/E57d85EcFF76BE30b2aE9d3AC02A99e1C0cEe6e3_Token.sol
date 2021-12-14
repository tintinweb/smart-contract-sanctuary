// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "ERC20.sol";

contract Token is ERC20 {
    constructor () public ERC20 ("Starch", "STC"){
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }
}