// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";

contract ERC20Token is Initializable, ERC20Upgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}

    function initialize(string memory tokenName, string memory tokenSymbol, uint256 tokenSupply) initializer public {
        __ERC20_init(tokenName, tokenSymbol);
        _mint(msg.sender, tokenSupply * 10 ** decimals());
    }
}