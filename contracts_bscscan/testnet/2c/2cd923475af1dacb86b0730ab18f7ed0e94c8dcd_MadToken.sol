// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControlEnumerable.sol";

contract MadToken is ERC20, AccessControlEnumerable {


    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyMinters() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Only minters can call this function");
        _;
    }

    function mint(address account, uint256 amount) external onlyMinters {
        _mint(account, amount);
    }

}