// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract KingCoin is ERC20
{
      constructor(string memory name_, string memory symbol_) 
        ERC20(name_, symbol_ )
      {
        _mint(_msgSender(), 1000000000000000000000000000);
      }
    
}