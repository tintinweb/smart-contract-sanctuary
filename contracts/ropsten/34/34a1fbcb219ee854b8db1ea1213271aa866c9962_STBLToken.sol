pragma solidity ^0.7.0;

import "Context.sol";
import "ERC20.sol";
import "Ownable.sol";
import "AccessControl.sol";



contract STBLToken is Context, ERC20, Ownable, AccessControl {
  constructor() ERC20("SweneStable","STBL") {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _mint(msg.sender, 10e22);
    }

    bytes32 MINTER_ROLE = keccak256("MINTER_ROLE");

    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }
    function grantMinterRole(address _to) public {
        // Check that the calling account has the admin role
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the default admin");
        require(!hasRole(MINTER_ROLE, _to), "Address already has minter role");
        grantRole(MINTER_ROLE, _to);
    }
    function revokeMinterRole(address _from) public {
        // Check that the calling account has the admin role
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the default admin");
        require(hasRole(MINTER_ROLE, _from), "Address does not have minter role");
        revokeRole(MINTER_ROLE, _from);
    }
}