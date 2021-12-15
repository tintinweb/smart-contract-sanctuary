/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    constructor() {
        name = "Jorge Luis Guanipa Sanchez";
        symbol = "JLGS";
        decimals = 18;
        totalSupply = 10000000 * (10**decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Sender does not have enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) private {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Source account does not have enough balance");
        require(allowance[_from][msg.sender] >= _value, "Sender is not allowed to send that many tokens");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}