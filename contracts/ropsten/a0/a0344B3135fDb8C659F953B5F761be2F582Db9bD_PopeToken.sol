/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PopeToken {
    string public name = "Pope Token";
    string public symbol = "POPET";
    string public standard = "Popet Token v1.0";
    uint8 public _decimals = 18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 totalSupply_;

    constructor() {
        totalSupply_ = 10000000;
        balanceOf[msg.sender] = totalSupply_;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to, uint256 amount) public returns (bool success) {
        require(_to != address(0));
        balanceOf[_to] = balanceOf[_to] + amount;
        emit Transfer(address(0), _to, amount);
        return true;
    }
}