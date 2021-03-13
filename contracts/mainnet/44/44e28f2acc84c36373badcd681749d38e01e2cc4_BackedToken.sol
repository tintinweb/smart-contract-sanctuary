pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./ERC20.sol";

contract BackedToken is ERC20 {
    address public owner;
    
    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) public {
        owner = msg.sender;
    }
    
    function ownerMint (address account, uint amount) public {
        require(msg.sender == owner, "Only owner may mint");
        _mint(account, amount);
    }
    
    function ownerBurn (address account, uint amount) public {
        require(msg.sender == owner, "Only owner may burn third party");
        _burn(account, amount);        
    }
    
    function selfBurn (uint amount) public {
        _burn(msg.sender, amount);        
    }
}