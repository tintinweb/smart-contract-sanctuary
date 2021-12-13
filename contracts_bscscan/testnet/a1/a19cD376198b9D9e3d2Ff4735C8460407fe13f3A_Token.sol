/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

pragma solidity ^0.8.2;

contract Token{
    //How balances get tracked to addresses
    mapping(address => uint) public balances;
    //allow smart contract to sign your transactions
    mapping(address => mapping(address => uint)) public allowance;
    //definitions
    uint public totalSupply = 48000000 * 10 ** 18;
    string public name = "Chris Games Token"; 
    string public symbol = "CGT";
    uint public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(){
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address owner) public view returns(uint){
        return balances[owner]; 
    }

    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) > value, "balances not available");
        balances[msg.sender] -= value; 
        balances[to] += value; 
        emit  Transfer(msg.sender,to,value);
        return true;    
    }

    function transferFrom(address from,address to, uint value) public returns(bool){
        require(balanceOf(from) > value, "balances not available");
        require(allowance[from][msg.sender] > value, "allowance not available");
        balances[from] -= value; 
        balances[to] += value; 
        emit Transfer(from,to,value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool){
       allowance[msg.sender][spender] = value; 
       emit Approval(msg.sender, spender,value);
       return true;
    }

}