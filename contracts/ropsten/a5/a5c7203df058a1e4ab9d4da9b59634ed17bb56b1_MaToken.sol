/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MaToken {

    string public name = 'Ma Token';
    string public symbol = 'Ma';
    string public standard = "Ma Token v1.0";
    uint256 public totalSupply;
    mapping(address => uint256) public balanceof;

    constructor(uint256 initSupply) {
        totalSupply = initSupply;
        balanceof[msg.sender] = initSupply;
    }

    event Transfer(
        address payable _from,
        address payable _to,
        uint256 _value
    );

    event Approval(
        address payable _owner,
        address payable _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address _to, uint256 _value) public returns(bool succ) {
        require(balanceof[msg.sender] >= _value);

        balanceof[msg.sender] -= _value;
        balanceof[_to] += _value;

        emit Transfer(payable(msg.sender), payable(_to), _value);

        return true;
    }

    function approve(address payable _spender, uint256 _value) public returns(bool succ) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(payable(msg.sender), _spender, _value);

        return true;
    }

    function transferFrom(address payable _from, address payable _to, uint256 _value) public returns(bool succ) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceof[_from] -= _value;
        balanceof[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

}