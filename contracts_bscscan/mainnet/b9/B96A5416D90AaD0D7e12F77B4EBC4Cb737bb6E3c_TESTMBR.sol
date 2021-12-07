// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "IMintableToken.sol";
import "PausableAdmin.sol";

contract TESTMBR is IMintableToken, ERC20, PausableAdmin {
    constructor() ERC20("TESTMBR", "TESTMBR") {
        _newRole("MINTER");
        addRole("MINTER", _msgSender());
    }

    function mint(address account, uint256 amount) external override onlyRoleIn("MINTER") whenNotPaused {
        _mint(account, amount);
    }
}