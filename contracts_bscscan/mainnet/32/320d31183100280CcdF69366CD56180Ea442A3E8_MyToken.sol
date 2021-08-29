// contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "AccessControl.sol";
import "BEP20.sol";

contract MyToken is BEP20, AccessControl {
    bytes32 public constant admin = keccak256("admin");
    constructor() BEP20('Lightcoin', 'LHC') {
        _mint(msg.sender, 100000 * 10 ** 8);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
    
    function mint(address to, uint amount) external {
        require(hasRole(admin, msg.sender), "Caller is not a admin");
        _mint(to, amount);
    }
    
    function burn(uint amount) external {
        require(hasRole(admin, msg.sender), "Caller is not a admin");
        _burn(msg.sender, amount);
        
    }
    
}