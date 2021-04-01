pragma solidity ^0.7.0;

import "Context.sol";
import "IERC20.sol";
import "ERC20.sol";
import "Ownable.sol";
import "SWNStake.sol";
import "AccessControl.sol";



contract SWNToken is Context, ERC20, SWNStake, AccessControl {
      constructor() ERC20("SweneToken","SWN") {
        // Grant the minter role to a specified account
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, 10e22);
    }

    bytes32 MINTER_ROLE = keccak256("MINTER_ROLE");

    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }
}