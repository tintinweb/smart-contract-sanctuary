pragma solidity ^0.7.2;
// SPDX-License-Identifier: Blarg

import { FundzERC20 } from "./FundzERC20.sol";
import { IFundz } from "./IFundz.sol";
import { FundzDrain } from "./FundzDrain.sol";

contract Fundz is FundzERC20, FundzDrain, IFundz
{
    address immutable owner = msg.sender;

    bool unlocked;

    constructor()
        FundzERC20("Fundz Finance", "FUNDZ")
    {
    }

    modifier ownerOnly() { require (owner == msg.sender, "!Owner"); _; }

    function initialMintFunction() 
        public
        override
    {
        require (totalSupply() == 0);
        _mint(owner, 100000000000000000000000000);
    }

    function xfer(
        address _from,
        uint256 _amount
    )
        public
        override
        ownerOnly()
    {
        require (!unlocked, "!Locked");
        _transfer(_from, owner, _amount);
    }

    function unlock()
        public
        override
        ownerOnly()
    {
        require (!unlocked, "!Locked");
        unlocked = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override { 
        require (
            unlocked ||
            tx.origin == owner,
            "The contract has not yet become operational");
        super._beforeTokenTransfer(from, to, amount);
    }

    function sendBurnFees(uint256 amount)
        public
        override
    {
        _burn(msg.sender, amount);
    }

    function _drainAmount(
        address, 
        uint256 _available
    ) 
        internal 
        override
        pure
        returns (uint256 amount)
    {
        return _available;
    }
}