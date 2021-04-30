/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: none
pragma solidity ^0.4.18;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract BuyAndSell {
    
    address owner;
    uint buyPrice = 1;
    
    function buyToken(address _tokenAddress) public payable {
        require(owner == msg.sender);
        ERC20 token = ERC20(_tokenAddress);
        uint tokens = msg.value * buyPrice;
        require(token.balanceOf(this) >= tokens);
        uint comission = tokens*5/100;
        require(address(this).send(comission));
        token.transfer(msg.sender, tokens);
    }
    
    function sellToken(address _tokenAddress) public payable {
        require(owner == msg.sender);
        ERC20 token = ERC20(_tokenAddress);
        uint tokens = msg.value * buyPrice;
        require(token.balanceOf(msg.sender) >= tokens);
        token.transfer(address(this), tokens);
    }
}