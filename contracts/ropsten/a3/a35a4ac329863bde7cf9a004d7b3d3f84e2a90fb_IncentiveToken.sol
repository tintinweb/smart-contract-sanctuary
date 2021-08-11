// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract IncentiveToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable {
    
    constructor() {
        initialize();
    }
    
    function initialize() initializer public {
        __ERC20_init("Incentive", "INC");
        __ERC20Burnable_init();
        __Ownable_init();
        _mint(owner(), 210000000000000000000000000000);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}