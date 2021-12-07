/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IToken {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract MoneyGame {
    address public owner;
    IToken public token;

    uint256 public toPay;

    mapping(address => UserBalance) public users;
    struct UserBalance {
        uint256 available;
        uint256 withdraw;
    }  

    enum Step {
        Set,
        Get
    }
    event Transfer(
        address from,
        address to,
        uint256 amount,
        uint256 date,
        Step indexed step
    );

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    constructor(address _token) {
        owner = msg.sender;
        token = IToken(_token);
    }

    function withdraw(uint256 amount) external {
        require(
            users[msg.sender].available >= amount,
            "Not enough fund to withdraw"
        );
        toPay -= amount;
        users[msg.sender].available -= amount;
        users[msg.sender].withdraw += amount;
        token.transfer(msg.sender, amount);
        emit Transfer(
            address(this),
            msg.sender,
            amount,
            block.timestamp,
            Step.Get
        );
    }

    function setFunds(address[] calldata tos, uint256[] calldata amounts) external restricted {
        require(tos.length == amounts.length, "Num of addresses differ from num of amounts");
        for (uint i = 0; i < tos.length; i++)
          { 
            setFund(tos[i], amounts[i]);
          }
    }

    function setFund(address to, uint256 amount) internal {
        require(amount >= 0, "Amount should be > 0");
        toPay += amount-users[to].available;
        users[to].available = amount;
        emit Transfer(address(this), to, amount, block.timestamp, Step.Set);
    }

    function addFund(address to, uint256 amount) external restricted {
        require(amount > 0, "Amount should be > 0");
        toPay += amount;
        users[to].available += amount;
        emit Transfer(address(this), to, users[to].available, block.timestamp, Step.Set);
    }

    function hasFund() public view returns (uint256) {
        return users[msg.sender].available;
    }

    function getFund(address to, uint256 amount) external restricted {
        require(token.balanceOf(address(this)) >= amount, "Not enough fund to withdraw");
        token.transfer(to, amount);
        emit Transfer(address(this), to, amount, block.timestamp, Step.Get);
    }

    function requiredToken() public view returns (uint256) {
        return toPay - token.balanceOf(address(this));
    }

    function overflowToken() public view returns (uint256) {
        return token.balanceOf(address(this)) - toPay;
    }
}