// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

contract UltiToken is ERC20, ERC20Capped, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant RELEASE_ROLE = keccak256("RELEASE_ROLE");

    constructor() ERC20("UltiToken", "ULTI") ERC20Capped(150 * 1e9 * 1e18) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(RELEASE_ROLE, msg.sender);
        _pause(); // Transfer and burn of the tokens are paused until the release
    }

    function release() onlyRole(RELEASE_ROLE) public whenPaused {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}