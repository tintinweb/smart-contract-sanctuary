/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

pragma solidity ^0.8.2;
contract token{
    uint private totalsupply=10000 *10**18;
    string public name="my token";
    string public symbol="ERC";
    uint public decimal=18;
    event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address owner,address indexed spender,uint value);
    mapping(address=>uint)public balances;
    mapping(address=> mapping(address=>uint))public allowances;
    constructor(){
        balances[msg.sender]=totalsupply;
    }
    function balanceof(address owner)public view returns(uint){
        return balances[owner];
        
    }
    function transfor(address to,uint value)public returns(bool){
        require(balanceof(msg.sender)>=value, 'balances too low');
        balances[to] +=value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender,to,value);
        return true;
    }
    
    function approve(address spender,uint value)public returns(bool){
        allowances[msg.sender][spender]=value;
        emit Approval(msg.sender,spender,value);
        return true;
    }
    function transfrom(address from,address to, uint value)public returns(bool){
        require(balanceof(from)>=value,"balane too low");
        require(allowances[from][msg.sender]>=value,'allowancestoo low');
        emit Transfer(from,to,value);
        balances[to] +=value;
        balances[from] -= value;
        return true;
        
        
    }
    
        
        
   
}