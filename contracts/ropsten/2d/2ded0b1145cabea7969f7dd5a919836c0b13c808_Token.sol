// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
contract Token is ERC20 {
     
        constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
    
}