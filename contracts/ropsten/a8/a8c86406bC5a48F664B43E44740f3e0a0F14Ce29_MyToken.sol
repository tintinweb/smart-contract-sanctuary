// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";

contract MyToken is Initializable, ERC20Upgradeable {
    function initialize(string memory name, string memory symbol, uint256 initialSupply) public virtual initializer {
        __ERC20_init(name, symbol);
        _mint(_msgSender(), initialSupply);
    }
}