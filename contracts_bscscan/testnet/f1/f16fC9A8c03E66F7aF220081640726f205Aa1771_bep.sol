/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.8.2;
contract bep{
    string public name="Bucks";
    string public symbol="BKS";
    uint public   totalsupply=20000000000;
    uint public    decimal=9;
    event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address owner,address indexed spender,uint value);
    mapping(address=>uint)public balances;
    mapping(address=> mapping(address=>uint))public allowances;
      constructor(){
        balances[msg.sender]=totalsupply;
    }
        function balanceof(address addr)public view returns(uint){
        return balances[addr];
        
    }
    function transfor(address to,uint value)public  {
        require(balanceof(msg.sender)>=value, 'balances too low');
      
        
        balances[to] +=value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender,to,value);
     }
    
    function approve(address spender,uint value)public{
        allowances[msg.sender][spender]=value;
        emit Approval(msg.sender,spender,value);
        
    }
        function transfrom(address from,address to, uint value)public{
        require(balanceof(from)>=value,"balane too low");
        require(allowances[from][msg.sender]>=value,'allowancestoo low');
        emit Transfer(from,to,value);
        balances[to] +=value;
        balances[from] -= value;
        
        
        
    }
}