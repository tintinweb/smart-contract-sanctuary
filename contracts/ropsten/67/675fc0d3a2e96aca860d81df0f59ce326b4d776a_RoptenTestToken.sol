/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.8.0;

interface CustomERC20{
    function totalSupply() external returns(uint);
    function balanceOf(address owner) external returns(uint);
    function approve(address spender, uint amount) external returns(bool);
    function allowance(address owner, address spender) external returns(uint);
    function transfer(address to, uint amount) external returns(bool);
    function transferFrom(address from, address to, uint amount) external returns(bool);
}

contract RoptenTestToken is CustomERC20{
    string public name;
    string public symbol;
    uint public decimals;
    uint public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address frm, address to, uint amount);
    event Approved(address frm, address to, uint amount);
    
    constructor(string memory _name,string memory _symbol,uint _decimals,uint _totalTokens){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = _totalTokens * (10 ** _decimals);
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() external view override returns(uint){
        return _totalSupply;
    }
    
    function balanceOf(address owner) external view override returns(uint){
        return balances[owner];
    }
    
    function approve(address spender, uint amount) external override returns(bool){
        allowed[msg.sender][spender] = amount;
        emit Approved(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns(uint){
        return allowed[owner][spender];
    }
    
    function transfer(address to, uint amount) external override returns(bool){
        require(amount <= balances[msg.sender], "Amount exceeds total balance of sender");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address owner, address to, uint amount) external override returns(bool){
        require(amount <= allowed[owner][msg.sender],"Amount exceeds allowed balance");
        require(amount <= balances[owner], "Amount exceeds total balance of sender");
        
        balances[owner] -= amount;
        allowed[owner][msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(owner, to, amount);
        return true;
    }
}