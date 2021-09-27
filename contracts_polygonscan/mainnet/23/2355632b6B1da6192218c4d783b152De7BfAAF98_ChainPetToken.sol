// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";

contract ChainPetToken is ERC20 {
    address tokenOwner;
    uint256 initialSupply = 1000000 * 10**18; // 1,000,000 = 1 million tokens
    
    constructor() ERC20("Chain Pet Token", "CPT") {
        tokenOwner = msg.sender;
        _mint(tokenOwner, initialSupply);
    }
    
    function mintAdditional(uint256 additional) public onlyBy(tokenOwner)  {
        _mint(tokenOwner, additional);
    }
    
    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }
}