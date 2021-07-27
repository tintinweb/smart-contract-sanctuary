/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

//SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface BEP20 {
             function totalSupply() external view returns (uint theTotalSupply);
             function balanceOf(address _owner) external view returns (uint balance);
             function transfer(address _to, uint _value) external returns (bool success);
             function transferFrom(address _from, address _to, uint _value) external returns (bool success);
             function approve(address _spender, uint _value) external returns (bool success);
             function allowance(address _owner, address _spender) external view returns (uint remaining);
             event Transfer(address indexed _from, address indexed _to, uint _value);
             event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Airdrop {
    
    address public owner;
    uint airdropAmount;
    address tokenAddress = 0xaDF73DF1a181c21fB4BF5A8bB71f3e938892bDf4;
    BEP20 token = BEP20(tokenAddress);
    
    event Airdropped(uint, address[]);
    event OwnershipTransferred(address);
    event Received(address, uint);
    
    constructor() {
        owner = msg.sender;
    }
    
    // Set airdrop amount 
    function setAirdropAmount(uint amt) public {
        require(msg.sender == owner, "Only owner");
        airdropAmount = amt;
    }
    
    // Airdrop 
    function airdrop(address[] memory addresses) public returns (bool) {
        require(msg.sender == owner, "Only owner");
        uint len = addresses.length;
        
        for(uint i = 0; i < len; i++){
            token.transfer(addresses[i], airdropAmount);
        }
        
        emit Airdropped(airdropAmount, addresses);
        return true;
    }
    
    // Owner Token Withdraw    
    function withdrawToken(address tokenAddr, address to, uint amount) public returns(bool) {
        require(msg.sender == owner);
        BEP20 _token = BEP20(tokenAddr);
        _token.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner);
        to.transfer(amount);
        return true;
    }
    
    // Transfer ownership
    function transferOwnership(address to) public {
        require(msg.sender == owner, "Only owner");
        owner = to;
        emit OwnershipTransferred(to);
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}