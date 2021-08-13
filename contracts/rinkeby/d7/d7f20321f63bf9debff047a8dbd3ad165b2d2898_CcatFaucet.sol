/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


// Adding only the ERC-20 function we need
interface CcatToken {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}


contract owned {
    CcatToken ccattoken;
    address owner;

    constructor() public{
        owner = msg.sender;
        ccattoken = CcatToken(0x40fF1b1121246D4bB308CBADF23137eC1BfcB167);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
        "Only the contract owner can call this function");
        _;
    }
}

contract mortal is owned {
    event Selfdestruct(address indexed from);
    
    // Only owner can shutdown this contract.
    function destroy() public onlyOwner {
        ccattoken.transfer(owner, ccattoken.balanceOf(address(this)));
        selfdestruct(msg.sender);
        
        emit Selfdestruct(msg.sender);
    }
}


contract CcatFaucet is mortal {

    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

    // Give out Ccat to anyone who asks
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount <= 0.1 ether);
        require(ccattoken.balanceOf(address(this)) >= withdraw_amount,
            "Insufficient balance in faucet for withdrawal request");
        // Send the amount to the address that requested it
        ccattoken.transfer(msg.sender, withdraw_amount);
        emit Withdrawal(msg.sender, withdraw_amount);
    }

    // Accept any incoming amount
    function acceptDeposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}


contract DEX is mortal {

    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event Deposit(address indexed from, uint amount);

    function buy() payable public {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = ccattoken.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some Ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        ccattoken.transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }

    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = ccattoken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the ccattoken allowance");
        ccattoken.transferFrom(msg.sender, address(this), amount);
        msg.sender.transfer(amount);
        emit Sold(amount);
    }
    
    // Accept any incoming amount
    function acceptDeposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }

}