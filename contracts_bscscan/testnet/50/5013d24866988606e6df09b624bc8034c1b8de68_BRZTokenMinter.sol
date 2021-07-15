/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20Minter {
    function mint(address account, uint256 amount) external;
}

contract BRZTokenMinter {
    
    IERC20Minter public tokenBRZ;

    //TokenAddress is the address of TokenOwner and NOT the original TokenAddress
    constructor(address tokenAddress) {
        tokenBRZ = IERC20Minter(tokenAddress);
    }
  
    function mint(address account, uint256 amount) public returns (bool) {
        tokenBRZ.mint(account, amount);
        return true;
    }
    
}