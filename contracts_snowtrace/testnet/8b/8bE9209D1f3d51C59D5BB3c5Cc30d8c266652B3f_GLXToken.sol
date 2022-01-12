// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./Ownable.sol";

contract GLXToken is Ownable, ERC20Capped {

    constructor() ERC20("Galaxy Token", "GLX") ERC20Capped(1e9*1e18) {}

    function mint(address to, uint256 amount) external onlyOwner {
        super._mint(to, amount);
    }
}