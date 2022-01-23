// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "draft-ERC20Permit.sol";
import "ERC20Votes.sol";

/// @custom:security-contact [email protected]
contract Kikkercoin is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
    constructor() ERC20("Kikkercoin", "KWAK") ERC20Permit("Kikkercoin") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}