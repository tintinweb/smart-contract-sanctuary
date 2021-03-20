/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;


//------------------------------------------------------------------------------------------------------------------
//
// ethbox Token
//
// Token symbol:    EBOX
// Token name:      ethbox Token
// 
// Total supply:    65.000.000 * 10^18
// Decimals:        18
//
//------------------------------------------------------------------------------------------------------------------


contract SafeMath
{
    //
    // Standard overflow / underflow proof basic maths library
    //
    
    function safeAdd(uint a, uint b) public pure returns (uint c)
    {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c)
    {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c)
    {
        require(b > 0);
        c = a / b;
    }
}


interface ERC20Interface
{
    //
    // Standard ERC-20 token interface
    //
    
    function totalSupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns(uint);
    function allowance(address tokenOwner, address spender) external view returns(uint);
    function approve(address spender, uint tokens) external returns(bool);
    function transfer(address to, uint tokens) external returns(bool);
    function transferFrom(address from, address to, uint tokens) external returns(bool);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}


contract ethboxToken is ERC20Interface, SafeMath
{
    //
    // Standard ERC-20 token
    //
    

    string  public symbol       = "EBOX";
    string  public name         = "ethbox Token";
    uint8   public decimals     = 18;
    uint    public _totalSupply = 65000000e18;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    
    constructor()
    {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    fallback() external payable
    {
        revert("Please don't send funds directly to the ethbox Token contract.");
    }
    
    function totalSupply() override external view returns(uint)
    {
        return safeSub(_totalSupply, balances[address(0)]);
    }

    function balanceOf(address tokenOwner) override external view returns(uint)
    {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) override external view returns(uint)
    {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) override external returns(bool)
    {
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        
        return true;
    }
    
    function transfer(address to, uint tokens) override external returns(bool)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) override external returns(bool)
    {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        
        emit Transfer(from, to, tokens);
        
        return true;
    }
}