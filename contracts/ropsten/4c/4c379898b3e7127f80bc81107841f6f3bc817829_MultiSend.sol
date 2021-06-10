/**
 *Submitted for verification at Etherscan.io on 2021-06-10
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

contract MultiSend {
    address public owner;
    address private token_address = 0xB0DD74bc7Dc6278ed1CFf32bd76A9FcBc2EDA67d; // CRYPTOL Ropsten
    
    constructor() {
        owner = msg.sender;
    }
    
    function contractBalance() external view returns(uint) {
        return IERC20(token_address).balanceOf(address(this));
    }
    
    function multisendToken(address[] memory to, uint256 amount) external {
        require(
            msg.sender == owner,
            "multisendToken: Only the Owner can call this function"
        );
        IERC20 erc20token = IERC20(token_address);
        
        uint8 i = 0;
        uint256 size = to.length;
        
        for (i; i < size; i++) {
            erc20token.transfer(to[i], amount);
        }
    }

    function withdrawTokens(uint256 amount) external {
        require(
            msg.sender == owner,
            "withdrawTokens: Only the Owner can call this function"
        );
        require(
            IERC20(token_address).balanceOf(address(this)) >= amount,
            "withdrawTokens: Insufficient funds. Deposit balance is not enough. Withdraw lower amount"
        );
        
        IERC20 token = IERC20(token_address);
        token.transfer(msg.sender, amount);
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

        payable(msg.sender).transfer(amount);
    }
    
}