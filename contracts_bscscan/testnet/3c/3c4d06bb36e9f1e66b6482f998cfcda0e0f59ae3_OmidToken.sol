/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

pragma solidity ^0.8.2;

contract OmidToken{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000 * 10 ** 18;
    string public name = "My First Token";
    string public symbol= "MFTTT";
    uint public decimals = 18;
    
    event Transfer(address indexed from , address indexed to , uint value);
    event Approval(address indexed owner, address indexed spender , uint value);
    
    constructor() {
        
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint) {
        
        return balances[owner];
    }
    
    function transfer(address to , uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value , "balance is not enough");
        balances[to]+=value;
        balances[msg.sender]-=value;
        emit Transfer(msg.sender,to,value);
        return true;
        
    }
    
    function transferFrom(address from,address to, uint value) public returns(bool){
        require(balanceOf(from) >= value , "balance is not enough");
        require(allowance[from][msg.sender] >= value ,"allowance is not enough");
        balances[to]+=value;
        balances[from]-=value;
        emit Transfer(from,to,value);
        return true;
        
    }
    
    function approve(address spender , uint value) public returns(bool){
        allowance[msg.sender][spender]=value;
        emit Approval(msg.sender,spender,value);
        return true;
        
    }
    
    
    
}