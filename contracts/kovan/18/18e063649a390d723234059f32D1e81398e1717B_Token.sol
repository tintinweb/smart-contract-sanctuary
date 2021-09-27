/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    address private _minter;
    string private _name = "My Cat Token";
    string private _symbol = "CAT";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000000000000000000000; // 1 mln tokens
    // 000000000000000000
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor (){
        _minter = msg.sender;
        _balances[_minter] = _totalSupply;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }
    function myBalance()public view returns (uint256 balance) { // for more convenient tests
    return balanceOf(msg.sender);
    }
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_from != address(0));
        _balances[_from] = _balances[_from] - _value;
        _balances[_to] = _balances[_to] + _value;
        emit Transfer(_from,_to,_value);
    }
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_value <= _balances[msg.sender]);
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address from,address to,uint256 value) external returns (bool success){
        require(value <= _allowed[from][msg.sender]);
        _transfer(from,to,value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
        emit Transfer(from,to,value);
        return true;
    }
    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_spender != address(0));
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool success) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender] + addedValue;
        emit Approval(msg.sender,spender,_allowed[msg.sender][spender]);
        return true;
    }
    function decreaseAllowance(address spender, uint256 decreaseValue) external returns (bool success) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender] - decreaseValue;
        emit Approval(msg.sender,spender,_allowed[msg.sender][spender]);
        return true;
    }
    function _mint(address account,uint256 amount) internal{
        require(account!=address(0));
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0),account,amount);
    }
    function mint(address account,uint256 amount) external returns (bool success) {
        require(msg.sender == _minter);
        _mint(account,amount);
        return true;
    }
    function _burn(address account,uint256 amount) internal {
        require(account != address(0));
        require(amount<=_balances[account]);
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account,address(0),amount);
    }
    function burnFrom(address account, uint256 amount) internal {
        require(account != address(0));
        require(amount <= _allowed[account][msg.sender]);
        _allowed[account][msg.sender] = _allowed[account][msg.sender] - amount;
        emit Approval(account,msg.sender,_allowed[account][msg.sender]);
        _burn(account,amount);
    }
    function minterBurn(address account,uint256 amount) external returns (bool success) {
        require(msg.sender == _minter);
        _burn(account,amount);
        return true;
    }
}