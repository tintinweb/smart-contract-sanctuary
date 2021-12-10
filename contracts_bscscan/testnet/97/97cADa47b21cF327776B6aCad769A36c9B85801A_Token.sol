/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address public owner;
    modifier restricted() {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    modifier issuerOnly() {
        require(isIssuer[msg.sender], "You do not have issuer rights");
        _;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isIssuer;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event IssuerRights(address indexed issuer, bool value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function getOwner() public view returns (address) {
        return owner;
    }

    function mint(address to, uint256 amount) public issuerOnly returns (bool success) {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
        return true;
    }

    function burn(uint256 amount) public issuerOnly returns (bool success) {
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function burnFrom(address from, uint256 amount) public issuerOnly returns (bool success) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool success) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool success) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function transferOwnership(address newOwner) public restricted {
        require(newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, newOwner);
        owner = newOwner;
    }

    function setIssuerRights(address issuer, bool value) public restricted {
        isIssuer[issuer] = value;
        emit IssuerRights(issuer, value);
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupplyFormatted) {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        totalSupply = totalSupplyFormatted * 10**decimals_;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}