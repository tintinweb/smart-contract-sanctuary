/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ERC20Interface
{
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ElonShibask is ERC20Interface
{
    string public name = "Elon Shibask";
    string public symbol = "ESHIBASK";
    uint public decimals = 18;
    uint public override totalSupply = 1000000000 * 10**18;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    
    constructor ()
    {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint balance)
    {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public override returns (bool success)
    {
        require(balances[msg.sender] >= tokens, "Not enough tokens");
        require(tokens > 0, "Amount can't be zero");
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    function allowance(address tokenOwner, address spender) view public override returns(uint)
    {
        return allowed[tokenOwner][spender];
    }
    
     function approve(address spender, uint tokens) public override returns (bool success)
     {
         require(balances[msg.sender] >= tokens, "Select another token value");
         
         allowed[msg.sender][spender] = tokens;
         
         emit Approval(msg.sender, spender, tokens);
         return true;
     }
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success)
    {
        require(allowed[from][msg.sender] >= tokens);
        require(balances[from] >= tokens, "Not enough tokens");
        require(tokens > 0, "Amount can't be zero");
        
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][msg.sender] -= tokens;
        
        emit Transfer(from, to, tokens);
        
        return true;
    }
}