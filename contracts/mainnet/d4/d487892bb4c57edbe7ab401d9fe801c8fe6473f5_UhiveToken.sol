// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Capped.sol";


contract UhiveToken is ERC20Capped {

    event Burn(address indexed _from, uint256 _amount);

    constructor (string memory name_,
                string memory symbol_,
                uint256 cap)
                ERC20(name_, symbol_)
                ERC20Capped(cap) {

        _mint(msg.sender, cap);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        _reduceCap(amount);
        emit Burn(msg.sender, amount);
    }
}