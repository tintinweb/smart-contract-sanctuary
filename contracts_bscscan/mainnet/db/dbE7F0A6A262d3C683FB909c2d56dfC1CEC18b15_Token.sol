/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

pragma solidity ^0.8.2;

contract Token{
    mapping(address=> uint) public balances;
    mapping(address=> mapping(address=>uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Yaadmancoin";
    string public symbol = "YMC";
    uint public decimals = 18;

    event Transfer (address indexed from, address indexed to, uint value);
    event approval (address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
    return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender)>= value, 'Balance too low');
        balances[to] += value;
        balances [msg.sender] -= value; 
        emit Transfer (msg.sender, to, value);
        return true;       
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
    require(balanceOf(from)>= value,'Balancee too low');
    require(allowance[from][msg.sender]>= value, 'allowance too allowance');
    balances[to] += value;
    balances[from] -= value; 
    emit Transfer(from, to, value);
    return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit approval(msg.sender, spender, value);
        return true;
    }
}