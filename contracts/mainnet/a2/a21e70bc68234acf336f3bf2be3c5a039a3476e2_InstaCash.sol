/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
contract InstaCash {
    string public name = "InstaCoin";
    string public symbol = "INC";
    uint8 public decimals = 8;
    uint256 public totalSupply = 10000000000 * (uint256(10) ** decimals);
    using SafeMath for uint256;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
}
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { assert(b <= a); return a - b; }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; assert(c >= a); return c; }
}