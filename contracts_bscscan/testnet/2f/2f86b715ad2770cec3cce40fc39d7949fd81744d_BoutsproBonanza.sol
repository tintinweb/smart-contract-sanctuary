/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: none
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

contract BoutsproBonanza {
    
    struct User {
        bool registered;
    }
    
    address public owner = msg.sender;
    address private tokenAddress = 0x6B6c271E8c2D9f4802eE110148fEFCae4c8982EA;
    uint sendAmt = 1000 * 10**18;
    
    mapping(address => User) user;
    
    event TokensTransferred(address from, uint amount);
    event OwnershipTransferred(address to);
    
    // Send fixed amount of tokens from user
    function sendTokens() public returns (bool) {
        require( !user[msg.sender].registered );
        BEP20 token = BEP20(tokenAddress);
        token.transferFrom(msg.sender, address(this), sendAmt);
        user[msg.sender].registered = true;
        emit TokensTransferred(msg.sender, sendAmt);
        return true;
    }
    
    // Token withdrawal by owner
    function withdrawTokens(address payable to, address tokenAddr, uint amount) public returns (bool) {
        require(msg.sender == owner, "Only owner");
        BEP20 token = BEP20(tokenAddr);
        token.transfer(to, amount);
        return true;
    }
    
    // Check registration status
    function status(address _user) public view returns (bool) {
        return user[_user].registered;
    }
        
    // Ownership Transfer
    function onwershipTransfer(address to) public returns (bool) {
        require(msg.sender == owner, "Only owner");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }

    // DO NOT ACCEPT BNB
    receive() external payable {
        revert();
    }
}