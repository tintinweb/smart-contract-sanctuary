/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}

contract MusiToken is ERC20 {
    
    string private _name;
    string private _symbol;
    uint8  private _decimal;
    uint256 private _totalSupply;
    
    
    mapping (address => uint256) private balances; // musi => 10000 eth； zhang sanzhangsan => 200 eth;
    // 
    mapping (address => mapping (address => uint256)) private allowances; // musi => [(zhangsan, 200), (lisi, 100)]
    
    
    constructor(string memory name_, string memory symbol_, uint8 decimal_, uint256 totalSupply_){
        _name = name_;
        _symbol = symbol_;
        _decimal = decimal_;
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
    }

    
    function name() external override view returns (string memory) {
        return _name;
        
    }
    function symbol() external override view returns (string memory) {
        return _symbol;
    }
    function decimals() external override view returns (uint8) {
        return _decimal;
    }
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address _owner) external override view returns (uint256 balance) {
        return balances[_owner];
    }
    function transfer(address _to, uint256 _amount) external override returns (bool success) {
        
        require(balances[msg.sender] >= _amount, "Not enought money !");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
        
    }
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success) {
        uint _allowwance = allowances[_from][msg.sender];
        uint _leftAllowance = _allowwance - _value;
        require ( _leftAllowance >= 0, "Not enought !");
        allowances[_from][msg.sender] -= _leftAllowance;
        
        require(balances[_from] > _value, "Not enought!");
        balances[_from] -= _value;
        balances[_to] += _value;
        return true;
    }
    function approve(address _spender, uint256 _value) external override returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        return true;
    }
    function allowance(address _owner, address _spender) external override view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}