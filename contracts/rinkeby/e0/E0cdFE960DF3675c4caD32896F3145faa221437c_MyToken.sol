// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
 
contract MyToken {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() {
        name = "MyToken";
        symbol = "MTB";
        decimals = 18;
        
        totalSupply = 100*10**18;
        _balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_balances[msg.sender] >= _value, "Transfer amount exceeds balance!");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_balances[_from] >= _value, "Transfer amount exceeds balance!");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        
        emit Transfer(_from, _to, _value);

        uint256 currentAllowance = _allowances[_from][msg.sender];
        require(currentAllowance >= _value, "Transfer amount exceeds allowance!");
         _allowances[_from][msg.sender] = currentAllowance - _value;
        
        emit Approval(_from, msg.sender, currentAllowance - _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}