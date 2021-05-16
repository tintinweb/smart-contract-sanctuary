// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IHER.sol";

contract ERC20 is IERC20 {
    
    string public _name;
    string public _symbol;
    uint256 _totalSupply;
    uint _decimals = 18;
    
    mapping(address => uint) balances;
    mapping(address=> mapping(address=> uint)) allowances;
    
    constructor (string memory name_, string memory symbol_, uint initialSupply) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }
    
    function name() external view returns (string memory) {
        return _name;
    }
    
    
    
    function totalSupply() external override view returns (uint256) {
            return _totalSupply;
        }

    
    function balanceOf(address _account) external override view returns (uint256){
        return balances[_account];
    }


    function transfer(address recipient, uint256 amount) external override returns (bool){
        require(amount <= balances[msg.sender], "not enough balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
        
    }
    
    
    function allowance(address owner, address spender) external override view returns (uint256){
        return allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) external override returns (bool){
        allowances[msg.sender][spender] = amount;
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool){
        require(allowances[sender][msg.sender] > amount, "no right");
        balances[sender] -= amount;
        balances[recipient] += amount;
        return true;
    }


}