// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./Freezable.sol";
import "./Describable.sol";

contract Juno is ERC20, Freezable, Describable {

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, string memory description, address issuer) ERC20(name, symbol) public {
	_setupDescription(description);
        _setupDecimals(decimals);
        _freeze(issuer, false);
        _freeze(address(0), false);
        _mint(issuer, totalSupply);
        _freeze(address(0), true);
    }

    function unfreezeAndTransfer(address recipient, uint256 amount) public onlyOwner {
        unfreeze(recipient);
        require(transfer(recipient, amount), "transfer");
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override whenTransfer(from, to) {
    }

}