/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract Token {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balenceOf;
    mapping(address => mapping(address => uint256)) allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

//1000000000000000000000000
    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balenceOf[msg.sender] = totalSupply;
    }

    function transfer (address _to, uint256 _value) public returns (bool success) {
        balenceOf[msg.sender] -= _value;
        balenceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve (address _spender, uint256 _value) external returns (bool success) {
        require(balenceOf[msg.sender] >= _value);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value);
        require(balenceOf[_from] >= _value);
        
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer (address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balenceOf[_to] += _value;
        balenceOf[_from] -= _value;
        emit Transfer(_from, _to, _value);
    }
}