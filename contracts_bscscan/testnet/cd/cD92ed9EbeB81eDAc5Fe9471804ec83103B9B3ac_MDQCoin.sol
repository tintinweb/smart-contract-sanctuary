/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.14 <0.9.0;

contract MDQCoin {
  
    mapping (address =>uint) public balances;
    mapping(address=>mapping (address =>uint))public allowance;

    uint public totalSupply = 1000 * 10 ** 18;
    string public name ="MDQCoin";
    string public symbol ="MDQ";
    uint public decimals = 18;
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    constructor () {
        balances[msg.sender] = totalSupply;
    }
    function balanceOf (address owner) public view returns(uint){
        return balances[owner];
    }
    function transfer(address to,uint amount) public returns(bool){
        require(balanceOf(msg.sender)>= amount,"Het tien roi");
        balances[msg.sender]-=amount;
        balances[to] += amount;
        emit Transfer(msg.sender,to, amount);
        return true;
    }
    function transferFrom(address from,address to,uint amount) public returns(bool){
        require(balanceOf(from)>= amount,"Het tien roi");
        require(allowance[from][msg.sender]>= amount,"Het tien roi");
        balances[from]-=amount;
        balances[to] += amount;
        emit Transfer(from,to, amount);
        return true;
    }
    function approve (address spender,uint amount) public returns(bool){
        allowance[msg.sender][spender]= amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }
}