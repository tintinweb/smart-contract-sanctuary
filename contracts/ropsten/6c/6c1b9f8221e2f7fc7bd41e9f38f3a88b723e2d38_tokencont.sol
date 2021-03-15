/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface token{
    
    function totalsupply() external view returns(uint);
    function balanceOf(address account)external view returns(uint);
    function allowance(address owner, address delegate) external view returns(uint);
    function transfer( address reciver,  uint numtoken) external returns(bool);
    function approve(address spender, uint numtoken)external  returns(bool);
    function transferFrom(address owner,address buyer, uint numtoken) external returns(bool);
    
}

contract tokencont is token{
    
    string public constant name = "ERC20";
    string public constant symbol = "ERC";
    uint public constant decimals = 18;
    
    event Approve(address indexed tokenowner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    mapping(address => uint) balance;
    
    mapping(address => mapping(address => uint)) allowed;
    
    
    uint public override totalsupply;
    
    using safeMath for uint;
    
    constructor(uint total){
        totalsupply = total;
        balance[msg.sender] = totalsupply;
    }

    
    function balanceOf(address owner) public override view returns(uint){
        return balance[owner]; 
    }
    
    function transfer(address reciver, uint numtoken) public override  returns(bool){
        require(numtoken <= balance[msg.sender]);
        
        balance[msg.sender]=balance[msg.sender].sub(numtoken);
        balance[reciver] = balance[reciver].add(numtoken);
        emit Transfer(msg.sender , reciver , numtoken);
        return true;
    }
    
    function approve(address delegate, uint numtoken) public override  returns(bool){
        allowed[msg.sender][delegate] = numtoken;
        emit Approve(msg.sender , delegate , numtoken);
        return true;
    }
    
    function allowance(address owner, address delegate) public override view returns(uint){
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numtoken) public override  returns(bool){
        require(balance[owner] >= numtoken);
        require(allowed[owner][msg.sender] >= numtoken);
        
        balance[owner] = balance[owner].sub(numtoken);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numtoken);
        balance[buyer] = balance[buyer].add(numtoken);
        emit Transfer(owner, buyer, numtoken);
        return true;
    }
}

library safeMath{
    function sub(uint a, uint b)internal pure returns(uint){
        assert(a >= b);
        return a - b;
    }
    
    function add(uint a, uint b)internal pure returns(uint){
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}