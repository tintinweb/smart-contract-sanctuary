// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC20.sol";


contract MockERC20 is ERC20 {
    constructor(uint256 supply) ERC20("Mock Token", "MOCKERC20") {
        _mint(msg.sender, supply);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}