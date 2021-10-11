/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);
    
 function mint(uint256 amount) external returns(bool success);
 function burn(uint256 amount) external returns(bool success);
    
    

  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);

}

contract Intern is IERC20 {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    address admin;
    
    
    mapping(address => uint) balances;
    mapping(address => mapping(address=>uint256)) allowed;
    uint256 totalSupply_;
    constructor(string memory _name, string memory _symbol, uint8 _decimal,uint256 _totalsupply) {
        admin = msg.sender;
        totalSupply_ = _totalsupply* 10**_decimal;
        balances[msg.sender] = totalSupply_;
        name = _name;
        symbol = _symbol;
        decimals = _decimal;
    }
    
    
    function totalSupply() public override view returns(uint256){
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256){
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 value) public override returns (bool){
        require(value <= balances[msg.sender],"not sufficient balance to transfer");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender,to,value);
        return true;
    }

    
     function mint(uint256 amount) public override returns(bool success) {
         totalSupply_ += amount;
         balances[msg.sender] += amount;    
         emit Transfer(address(0),msg.sender, amount);
         return true;
    }
    
     function burn(uint256 amount) public override returns(bool success) {
         require(amount <= balances[msg.sender],"don't have sufficient amount to burn");
         totalSupply_ -= amount ;
         balances[msg.sender] -= amount;
         emit Transfer(msg.sender,address(0), amount);
         return true;
  }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
     function approve(address _spender,uint256 _amount) public override returns(bool success) {
       allowed[msg.sender][_spender] = _amount;
       emit Approval(msg.sender, _spender, _amount);
       return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && _allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender]-= _value;
        emit Transfer(_from, _to, _value); 
        return true;
    }

}