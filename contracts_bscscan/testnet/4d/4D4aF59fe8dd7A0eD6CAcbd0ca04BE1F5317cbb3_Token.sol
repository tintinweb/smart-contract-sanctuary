/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.4.26;

contract Token{
    mapping(address => uint)public balances;
    mapping(address =>mapping(address => uint))public allowance;
    uint public totalSupply =10000* 10 **18;
    string public name ="Saimon";
    string public symbol="SMN";
    uint public decimals=18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner,address indexed spender, uint value);
    
    constructor(){
        balances[msg.sender]= totalSupply;
    }
    
    function balanceof(address owner) public view returns(uint){
        return balances[owner];
    }
    
    function transfer(address to, uint value)public returns(bool){
        require(balanceof(msg.sender) >= value, 'balance is low');
        balances[to]+= value;
        balances[msg.sender] -=value;
        emit Transfer(msg.sender , to , value);
        return true;
    }
    
    function tranferFrom(address from,address to,uint value)public returns(bool){
        require(balanceof(from)>=value,'balance is low');
        require(allowance[from][msg.sender] >= value, 'no allowance');
        balances[to] += value;
        balances[from] -=value;
        emit Transfer(from,to, value);
        return true;
    }
    
    function allowance(address spender, uint value)public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender,spender,value);
        return true;
        
        
    }
}