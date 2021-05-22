/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.4.17;

contract Token {
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    
    function Token(
        uint256 _initialAmount
    ) public {
        _balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        _totalSupply = _initialAmount;                        // Update total supply
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function name() public view 
    returns (string)
    {
        return "505202000";
    }
    
    function symbol() public view returns (string)
    {
        return "CS188";
    }
    
    function decimals() public view returns (uint8)
    {
        return 18;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
  }
  
  function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));
    
        _balances[from] -= value;
        _balances[to] += value;
        _allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value); 
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return _allowed[owner][spender];
    }
  
  

}