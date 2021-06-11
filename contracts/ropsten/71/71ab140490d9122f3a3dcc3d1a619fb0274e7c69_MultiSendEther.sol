/**
 *Submitted for verification at Etherscan.io on 2021-06-11
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

contract MultiSendEther {
    address public owner;

    constructor() {
        owner = msg.sender;
    }
    
    function contractBalance() external view returns(uint) {
        return address(this).balance;
    }
    
    function multisendEther(address[] memory to, uint256 amount) external {
        require(
            msg.sender == owner,
            "multisendToken: Only the Owner can call this function"
        );
        
        uint8 i = 0;
        uint256 size = to.length;
        
        for (i; i < size; i++) {
            payable(to[i]).transfer(amount);
        }
    }
    
    function withdraw(uint256 amount) external {
        require(
            msg.sender == owner,
            "withdraw: Only the Owner can call this function"
        );
        require(
            address(this).balance >= amount,
            "withdraw: Insufficient funds. Deposit balance is not enough. Withdraw lower amount"
        );

        payable(owner).transfer(amount);
    }
    
}