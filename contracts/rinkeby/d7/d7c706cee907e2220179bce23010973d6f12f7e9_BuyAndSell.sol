/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.0;

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
    
    address public owner = msg.sender;
    address private contractAddr = address(this);
    // address payable private comissionAddr = payable(0x2cA90f6BE87cd46E9cF68Eb6DFD94825fa257956);
    uint buyPrice = 15;
    
    function buyToken(address _tokenAddress,address payable comissionAddr) public payable returns (bool success) {
        ERC20 token = ERC20(_tokenAddress);
        uint tokens = msg.value * buyPrice;
        require(token.balanceOf(contractAddr) >= tokens);
        uint comission = tokens * 5 / 100;
        token.transfer(comissionAddr, comission);
        tokens  = tokens - comission;
        token.transfer(msg.sender, tokens);
        return true;
    }
    
    function sellToken(address _tokenAddress, uint tokenAmount) public returns (bool success) {
        ERC20 token = ERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= tokenAmount);
        uint allowance = token.allowance(msg.sender, contractAddr);
        require(allowance >= tokenAmount);
        token.transferFrom(msg.sender, contractAddr, tokenAmount);
        return true;
    }
    
    function withdrawERC20Token(address _tokenAddress, address _to, uint _amount) public returns (bool success) {
        require(owner == msg.sender);
        return ERC20(_tokenAddress).transfer(_to, _amount);
        
    }
    
    function withdrawETH(address payable _to, uint _amount) public returns (bool) {
        require(owner == msg.sender);
        _to.transfer(_amount);
        return true;
    }
    
    receive() external payable{}
}