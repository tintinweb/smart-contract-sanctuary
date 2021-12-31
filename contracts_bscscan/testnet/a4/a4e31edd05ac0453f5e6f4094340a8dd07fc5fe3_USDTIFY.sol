// SPDX-License-Identifier: Toknify.com

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

contract USDTIFY is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner) ERC20(name, symbol) {
        _mint(owner, initialSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "USDTIFY: must have minter role to mint");
        _mint(to, amount);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "USDTIFY: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "USDTIFY: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}