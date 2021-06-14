/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract salvador {
    
    uint256 initialsupply = 10000*(10**6)*(10**18);
    using SafeMath for uint256;
    
    string  public name      = "El Salvador Coin";
    string  public symbol    = "ESDC";
    uint    public decimals  = 18;
    
    

    uint256 public totalSupply = initialsupply;
    address admin;
    
    mapping (address => uint256 ) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender)  public view returns (uint) {
        return allowed[tokenOwner][spender];
    }
    
    function transfer(address to, uint tokens) public returns (bool) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender]    =   balances[msg.sender].sub(tokens);
        balances[to]            =   balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address delegate,uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    function transferFrom(address owner, address buyer,uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner],"ERC20: insufficient balance ");
        require(numTokens <= allowed[owner][msg.sender],"ERC20: insufficient allowance");
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] =  allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
     
    constructor()  {
        balances[msg.sender] =  initialsupply;
        admin = msg.sender ;
    }
    
    
    event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
    event Transfer(address indexed from      , address indexed to     ,uint tokens);
}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return (a - b);
    }   
    function add(uint256 a, uint256 b) internal pure returns (uint256)   {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}