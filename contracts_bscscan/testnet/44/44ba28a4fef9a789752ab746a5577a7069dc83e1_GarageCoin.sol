// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC20.sol";
import "Pausable.sol";
import "Ownable.sol";

contract GarageCoin is ERC20, Pausable, Ownable {
    constructor() ERC20("GarageCoin", "GRG") {
        uint256 total = 500000000 * (10**decimals());
        uint256 crowdsale = (total * 30) / 100; // %30
        uint256 reserved = total - crowdsale;

        _mint(msg.sender, reserved);
        _mint(0x97f8CE73EB18588A63dC77217FEE495Ab78266ab, crowdsale); // send %30 of tokens to crowdsale wallet
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}