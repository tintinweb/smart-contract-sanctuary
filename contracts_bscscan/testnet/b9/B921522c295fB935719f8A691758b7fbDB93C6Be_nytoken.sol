/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

pragma solidity ^0.8.2;
contract nytoken{
    string public name="erc20";
    string public symbol="ERC";
    uint public   totalsupply=10000*10**18;
    uint public    decimal=18;
    address public owner;
    mapping(address=>uint)public balances;
    event Transfer(address indexed from,address indexed to,uint value);
    constructor(){
       balances[msg.sender]=totalsupply;
        
     }
     function balanceof(address addr)public view returns(uint){
        return balances[addr];
        
    }
    function transfor(address to,uint value)public returns(bool){
        require(balanceof(msg.sender)>=value, 'balances too low');
        // require(!froozenaccount[msg.sender],'account is froozen');
         
    while ( value > 0 )
        value = value - 5;
 
    if ( value == 0 ){
        return true;
    }
        
        balances[to] +=value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender,to,value);
        return true;
    }
    
         
}