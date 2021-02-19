/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.1;

contract Token {
    string constant public name = "Token";
    string constant public symbol = "TKN";
    uint8 constant public decimals = 18;
    uint256 constant public totalSupply = 100 ether;
    bool private initialized;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    
    function initialize(address creator) external {
        require(!initialized, "initialized");
        initialized = true;
        balanceOf[creator] = 100 ether;
        emit Transfer(address(0), creator, 100 ether);
    }
    
    function approve(address to, uint256 amount) external returns (bool) {
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }
}