/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Banking {
    address private _cryptol_address = 0xB0DD74bc7Dc6278ed1CFf32bd76A9FcBc2EDA67d;
    address owner;
    
    constructor() {
      owner = msg.sender;
    }
    
    function contractBalance() external view returns(uint) {
        return IERC20(_cryptol_address).balanceOf(address(this));
    }
    
    function withdraw(uint256 amount) external {
        require(
            msg.sender == owner,
            "Only the Owner can call this function"
        );
        require(
            IERC20(_cryptol_address).balanceOf(address(this)) >= amount,
            "Insufficient funds. Deposit balance is not enough. Withdraw lower amount"
        );
        
        address caller = msg.sender;
        IERC20 cryptol_token = IERC20(_cryptol_address);
        cryptol_token.transfer(caller, amount);
    }
    
}