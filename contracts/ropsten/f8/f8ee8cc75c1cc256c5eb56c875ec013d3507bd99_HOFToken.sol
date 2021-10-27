// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract HOFToken is ERC20, Ownable {
    mapping(address => bool) ownerApprovals;

    constructor(uint256 initialSupply) ERC20("HOFToken", "HOF") {
        approveOwner(true);
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    /**
     * @dev Sets whether the owner is allowed to transfer tokens to other wallets (without a limit) to {value}
     *
     * NOTE: Unlike the approve function, this function does not limit the amount of tokens that can be transfered.
     */
    function approveOwner(bool value) public {
        ownerApprovals[msg.sender] = value;
    }

    /**
    * @dev Transfers {amount} tokens from {from} to {to}.
    *
    * Requirements:
    * - `from` must have approved the owner via the approveOwner method
    */
    function ownerTransfer(address from, address to, uint256 amount) onlyOwner public returns (bool) {
        if (ownerApprovals[from] != true)
            return false;

        _transfer(from, to, amount);
        return true;
    }

    /**
    * @dev Checks if the given account has approved the contract owner to transfer HOF tokens on their behalf
    */
    function isOwnerApproved(address account) public view returns (bool){
        return ownerApprovals[account];
    }
}