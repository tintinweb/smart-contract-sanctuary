/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20Minter {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function isMinter(address account) external view returns (bool);
    function addMinter(address account) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BRZTokenMinter {
    
    IERC20Minter public tokenBRZ;
    
    constructor(address tokenAddress) {
        tokenBRZ = IERC20Minter(tokenAddress);
    }
  
    function mint(address account, uint256 amount) public returns (bool) {
        tokenBRZ.mint(account, amount);
        return true;
    }
    
}