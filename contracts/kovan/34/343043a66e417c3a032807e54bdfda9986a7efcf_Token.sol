/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

contract Token {
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowances;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor (string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) external returns (bool) {
        require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        require(balanceOf[_from] >= _value);
        require(allowances[_from][msg.sender] >= _value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;
        _transfer(_from, _to, _value);
        return true;
    }
}