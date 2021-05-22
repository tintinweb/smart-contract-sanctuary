/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

/// @title implements custom ERC20 token for CS188 project 2
/// @author Alberto Diaz ([email protected])
/// @dev Compliant with ERC20 Token Standard

pragma solidity =0.8.0;

contract Token {
    uint256 _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    
    // gives msg.sender of constructor 100 tokens to start
    constructor() {
        _balances[msg.sender] = 100;
        _totalSupply = 100;
    }

    function name() public view returns (string memory) {
        return "604967268";
    }
    
    function symbol() public view returns (string memory) {
        return "CS188";
    }
    
    function decimals() public view returns (uint8) {
        return uint8(18);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function _findBalanceOf(address _account) internal view returns (uint256) {
        return _balances[_account];
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _findBalanceOf(_owner);
    }
    
    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount >= 0, "ERC20: transfer amount must be non-negative");
        require(_balances[_sender] >= _amount, "ERC20: transfer amount exceeds balance");
        
        _balances[_sender] = _balances[_sender] - _amount;
        _balances[_recipient] = _balances[_recipient] + _amount;
        emit Transfer(_sender, _recipient, _amount);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    // Helper function: approves new allowance given _from address, _to address, and new allowance _value
    function _approveAllowance(address _from, address _spender, uint256 _value) internal {
        require(_from != address(0), "ERC20: allowance approval from the zero address");
        require(_spender != address(0), "ERC20: allowance approval to the zero address");
        require(_value >= 0, "ERC20: allowance should be non-negative");
        require(_balances[_from] > _value, "ERC20: allowance is greater than balance");
        
        _allowances[_from][_spender] = _value;
        emit Approval(_from, _spender, _value);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _approveAllowance(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _transfer(_from, _to, _value);
        _approveAllowance(_from, _to, _allowances[_from][_to] - _value);
        return true;
    }
}