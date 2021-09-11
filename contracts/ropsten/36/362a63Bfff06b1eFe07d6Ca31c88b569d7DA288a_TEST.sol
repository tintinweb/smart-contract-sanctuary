// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract TEST is ERC20, Ownable {
    constructor() ERC20("TEST", "TTK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}