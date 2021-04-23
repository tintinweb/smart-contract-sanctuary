// SPDX-License-Identifier: MIT
// Creator: Prosper

pragma solidity 0.6.5;

import "./ERC20UpgradeSafe.sol";
import "./Initializable.sol";


contract PROS is Initializable, ERC20UpgradeSafe {

    function initialize(string memory name, string memory symbol) public initializer {
    	__ERC20_init(name, symbol);
    	uint totalSupply = 100000000 * (10 ** 18);
    	_mint(_msgSender(), totalSupply);
    }
}