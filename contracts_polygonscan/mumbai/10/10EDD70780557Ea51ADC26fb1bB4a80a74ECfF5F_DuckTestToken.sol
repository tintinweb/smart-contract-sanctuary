/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DuckTestToken {
    mapping (address => uint256) public balanceof;
    mapping (address => mapping(address => uint256)) public allowance;

    string public name = "DuckTestToken";
    string public symbol = "DTT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000 * (10 ** decimals);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    constructor () {
        balanceof[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceof[msg.sender] >= _value, "Not enough tokens to transfer");

        balanceof[msg.sender] -= _value;
        balanceof[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value, "Not approved to spend this amount");
        require(balanceof[_from] >= _value, "Not enough balance to transfer");

        balanceof[_from] -= _value;
        balanceof[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

}