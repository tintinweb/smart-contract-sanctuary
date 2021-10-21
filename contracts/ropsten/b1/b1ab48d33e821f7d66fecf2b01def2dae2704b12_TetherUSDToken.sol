// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TetherUSDToken is ERC20 {
    
    constructor(uint256 initialSuppy) ERC20 ("(Dev) Tether USD","USDT") {
        _mint(msg.sender, initialSuppy);
    }
    
    //replace default 18 decimals
    function decimals() public view virtual override returns(uint8) {
        return 6;
    }
}