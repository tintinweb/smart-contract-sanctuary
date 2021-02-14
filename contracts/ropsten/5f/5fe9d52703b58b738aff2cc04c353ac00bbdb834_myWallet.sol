/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.7.4;


interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
}

contract myWallet {
    
    address payable owner;
    
    constructor() {
       owner = msg.sender;
    }
    
    function setOwner (address payable newOwner) external {
        require (msg.sender == owner);
        owner = newOwner;
    }
    
    function getOwner() external view returns(address) {
        return owner;
    }
    
    receive() external payable {
        deposit();
    }
    
    function deposit() public payable {
        
    }
    
    function transferTo(address payable recipient) external payable returns (bool succsess) {
        recipient.transfer(msg.value);
        return true;
    }
    
    function withdraw(uint256 amount) external returns (bool succsess) {
        require(msg.sender == owner);
        owner.transfer(amount);
        return true;
    }
    
    
    function withdrawToken(address tokenAddress, uint256 value) external returns (bool succsess) {
        require(msg.sender == owner);
        ERC20 erc20 = ERC20(tokenAddress);
        erc20.transfer(owner, value);
        return true;
    }
    
    function approveToken(address tokenAddress, uint256 value) external returns (bool succsess) {
        require(msg.sender == owner);
        ERC20 erc20 = ERC20(tokenAddress);
        erc20.approve(owner, value);
        return true;
    }
    
}