// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC20.sol";
import "./AccessControlEnumerable.sol";

contract MadToken is ERC20, AccessControlEnumerable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor () ERC20("Adventures Game", "MAD") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    modifier onlyMinters() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Only minters can call this function");
        _;
    }

    function mint(address account, uint256 amount) external onlyMinters {
        _mint(account, amount);
    }

}