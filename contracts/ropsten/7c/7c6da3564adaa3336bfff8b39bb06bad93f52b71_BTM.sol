/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

pragma solidity >= 0.7.0;

// -------------------------------------------------------------------
// 
// Symbol       : BTM
// Name         : ByTime
// Total supply : 1.000.000 (burnable)
// Decimals     : 18
// -------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// -------------------------------------------------------------------

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// TODO: Improvement using Owner and Pausable interfaces

contract BTM is IERC20{
    string  private constant _name = "ByTime";
    string  private constant _symbol = "BTM";
    string  private constant _version = "ByTime v0.0.1";
    uint256 private          _totalSupply = 1_000_000E18; // 1 million tokens
    uint8   private  constant _decimals = 18;

    mapping(address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint)) private _allowances;

    constructor() {
        _balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value) external override returns (bool success) {
        require(balanceOf(msg.sender) >= _value);
        _balanceOf[msg.sender] -= _value;
        _balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external override returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success) {
        require(balanceOf(_from)             >=_value);
        require(allowance(_from, msg.sender) >=_value);
        _balanceOf[_from] -= _value;
        _balanceOf[_to]   += _value;
        _allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address account) public view override returns (uint) {
        return _balanceOf[account];
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function version() external pure returns (string memory) {
        return _version;
    }
}