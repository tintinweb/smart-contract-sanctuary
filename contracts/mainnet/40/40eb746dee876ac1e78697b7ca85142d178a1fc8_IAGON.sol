// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";
import "./draft-ERC20Permit.sol";

contract IAGON is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, ERC20Permit {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

    constructor() ERC20("IAGON", "IAG") ERC20Permit("IAGON") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SNAPSHOT_ROLE, msg.sender);
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function snapshot() public {
        require(hasRole(SNAPSHOT_ROLE, msg.sender));
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}