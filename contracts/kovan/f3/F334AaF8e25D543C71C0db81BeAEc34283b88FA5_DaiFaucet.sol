/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.9;


interface DaiToken {

    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract owned {
    DaiToken daitoken;
    address owner;

    constructor() public{
        owner = msg.sender;
        daitoken = DaiToken(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
        "Only the contract owner can call this function");
        _;
    }
}

contract mortal is owned {
    // Only owner can shutdown this contract.
    function destroy() public onlyOwner {
        daitoken.transfer(owner, daitoken.balanceOf(address(this)));
        selfdestruct(msg.sender);
    }
}

contract DaiFaucet is mortal {

    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);
    
    
    mapping(address => uint) public depositedBalance;
    
    
    // Give out Dai to anyone who asks
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount <= 0.1 ether);
        require(daitoken.balanceOf(address(this)) >= withdraw_amount,
            "Insufficient balance in faucet for withdrawal request");
        // Send the amount to the address that requested it
        daitoken.transfer(msg.sender, withdraw_amount);
        emit Withdrawal(msg.sender, withdraw_amount);
    }

    // Accept any incoming amount
    function () external payable {
        emit Deposit(msg.sender, msg.value);
        depositedBalance[msg.sender] = msg.value;
    }
    
}