/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

/*SPDX-License-Identifier: UNLICENSED*/
pragma solidity ^0.6.6;
 
//ERC Token Standard 20 Interface
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//Actual token contract
contract Plunge is ERC20Interface {
    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        symbol = "PLG";
        name = "Plunge";
        decimals = 18;
        _totalSupply = 1000000000*(10**18);
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
 
    function balanceOf(address tokenOwner) public view override returns (uint) {
        return balances[tokenOwner];
    }
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    
    function transfer(address to, uint tokens) public override returns (bool success) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(msg.sender) >= tokens, "ERC20: transfer amount exceeds balance");
        balances[msg.sender] = balances[msg.sender].safeSub(tokens) ;
        balances[to] = balances[to].safeAdd(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public override returns (bool success) {
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= tokens, "ERC20: transfer amount exceeds balance");
        require(allowance(from,msg.sender) >= tokens, "ERC20: transfer amount exceeds allowance");
        balances[from] = balances[from].safeSub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].safeSub(tokens);
        balances[to] = balances[to].safeAdd(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    receive () external payable {
        revert();
    }
}

//Safe Math Interface

library SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}