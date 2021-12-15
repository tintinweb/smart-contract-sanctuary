// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./OwnableAccessControl.sol";
import "./Airdrop.sol";

contract OpmetaToken is ERC20, Ownable, OwnableAccessControl, Pausable, Airdrop {

    bytes32 public constant TRANSFERABLE = keccak256("TRANSFERABLE");

    constructor(string memory name, string memory symbol, uint supply, address owner) ERC20(name, symbol) {
        _mint(owner, supply);
        transferOwnership(owner);
        _setupRole(TRANSFERABLE, owner);
    }

    function mint(address account, uint amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint amount) public onlyOwner {
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused() || hasRole(TRANSFERABLE, from), "ERC20: token transfer while paused");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}