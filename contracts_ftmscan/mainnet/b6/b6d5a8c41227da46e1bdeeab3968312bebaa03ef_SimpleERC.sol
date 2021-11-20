/**
 *Submitted for verification at FtmScan.com on 2021-11-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;
contract SimpleERC {
    uint8 public decimals = 18;
    string public name = "TEST DONT BUY OR YOU WILL GET RUGGED";
    string public symbol = "TEST";
    uint256 public totalSupply = 1e24;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(){
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function balanceOf(address holder) public view returns(uint256) {
        return balances[holder];
    }
    
    
    function allowance(address holder, address spender) public view returns(uint256) {
        return allowed[holder][spender];
    }
    
    
    function transfer(address to, uint256 amount) public returns(bool) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        allowed[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    
    function approve(address spender, uint256 amount) public returns(bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}