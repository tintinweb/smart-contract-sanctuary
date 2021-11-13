/**
 *Submitted for verification at polygonscan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT

// File: contracts/Governance/IAMPT.sol


pragma solidity ^0.8.0;

interface IAMPT {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/Faucet.sol


pragma solidity ^0.8.0;


contract Faucet{

    IAMPT public amptToken;
    address public owner;

    uint256 public tokensPerUser = 10;

    mapping(address => bool) public distributions;

    constructor(IAMPT amptToken_) {
        amptToken = amptToken_;
        owner = msg.sender;
    }

    function balanceOf() public view returns (uint256) {
        return amptToken.balanceOf(address(this));
    }

    function updateTokensPerUser(uint256 value) external {
        require(msg.sender == owner, "Only owner can update");

        require(value > 0, "Value must be greater than 0");
        tokensPerUser = value;
    }

    function withdraw() external returns (bool) {
        require(msg.sender == owner, "Only owner can withdraw");

        uint256 amount = amptToken.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");

        return amptToken.transfer(owner, amount);
    }

    function getTokens() external returns (bool) {
        require(!distributions[msg.sender], "You have already received your tokens");
        require(amptToken.balanceOf(address(this)) >= tokensPerUser, "Not enough tokens in the contract");
        distributions[msg.sender] = true;

        return amptToken.transfer(msg.sender, tokensPerUser);
    }
 }