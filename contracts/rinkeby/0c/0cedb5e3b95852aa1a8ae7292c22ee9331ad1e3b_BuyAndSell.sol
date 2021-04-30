/**
 *Submitted for verification at Etherscan.io on 2021-04-30
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
    address payable private comissionAddr = payable(0x2cA90f6BE87cd46E9cF68Eb6DFD94825fa257956);
    uint buyPrice = 15;
    
    function buyToken(address _tokenAddress) public payable {
        ERC20 token = ERC20(_tokenAddress);
        uint tokens = msg.value * buyPrice;
        require(token.balanceOf(contractAddr) >= tokens);
        comission(tokens);
        token.transfer(msg.sender, tokens);
    }
    
    function comission(uint tokensBought) internal {
        uint a = tokensBought*5/100;
        comissionAddr.transfer(a);
        
    }
    
    function sellToken(address _tokenAddress) public payable {
        ERC20 token = ERC20(_tokenAddress);
        uint tokens = msg.value * buyPrice;
        require(token.balanceOf(msg.sender) >= tokens);
        token.transfer(address(this), tokens);
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