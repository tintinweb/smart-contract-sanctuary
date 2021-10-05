//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <=0.9.0;

import "ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("ShopToken","STN") {
        _mint(msg.sender, 1000000);
    }
    
}