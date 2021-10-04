// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

// contract SHWAToken is ERC20 {
    
//     constructor() ERC20("ShibaWallet", "SHWA") {
//         uint256 initialSupply = 3000000000000000000000000000; // 3Billions 10 0000 0000 0000 0000 0000 0000 00
//         _mint(msg.sender, initialSupply);
//     }
    
// }

contract TestToken is ERC20 {
    
    constructor() ERC20("Test Name", "Test-1") {
        uint256 initialSupply = 3000000000000000000000000000; // 3Billions 10 0000 0000 0000 0000 0000 0000 00
        _mint(msg.sender, initialSupply);
    }
    
}