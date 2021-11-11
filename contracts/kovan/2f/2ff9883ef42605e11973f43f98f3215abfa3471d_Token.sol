/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Token
{
    string public _name;
    string public _symbol;
    uint public _decimals;
    uint public _totalSupply;
    
    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public approvals;
    
    event Transfer(address indexed sender, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor()
    {
        _name = "Raccoon";
        _symbol = "RAC";
        _decimals = 18;
        _totalSupply = 800000000000 * 10**_decimals;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view returns (string memory)
    {
        return _name;
    }
    
    function symbol() public view returns (string memory)
    {
        return _symbol;
    }
    
    function decimals() public view returns (uint)
    {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint)
    {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint balance)
    {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) public view returns (uint remaining)
    {
        return approvals[_owner][_spender];
    }
    
    function approve(address _spender, uint _value) external returns (bool)
    {
        require(_spender != address(0));
        approvals[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal
    {
        require(_to != address(0));
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint _value) external returns (bool success)
    {
        require (_value <= balances[msg.sender]);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool success)
    {
        require(_value <= balances[_from]);
        require(_value <= approvals[_from][msg.sender]);
        approvals[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}