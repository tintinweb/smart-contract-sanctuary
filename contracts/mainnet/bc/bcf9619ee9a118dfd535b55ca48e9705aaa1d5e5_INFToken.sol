// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./AccessControl.sol";
import "./Context.sol";
import "./ERC20Burnable.sol";


contract INFToken is Context, AccessControl, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
    }
    
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "INFToken: must have minter role to mint");
        _mint(to, amount);
    }
}