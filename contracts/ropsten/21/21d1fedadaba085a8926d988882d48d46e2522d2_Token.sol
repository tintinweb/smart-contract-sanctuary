/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Token {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply; // 1 million tokens. 18 0s are added for the decimals: Ethereum does not support floating point values.

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier ensureValidAddress(address _to) {
        require(_to != address(0));
        _;
    }

    modifier ensureEnoughBalance(address _from, uint256 value) {
        require(balanceOf[_from] >= value);
        _;
    }

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply; // the contract creator gets all of the tokens.
    }

    function approve(address _sender, uint256 _value) ensureValidAddress(_sender) external returns(bool success) {
        allowance[msg.sender][_sender] += _value;
        emit Approval(msg.sender, _sender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(allowance[_from][msg.sender] >= _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) ensureValidAddress(_to) ensureEnoughBalance(_from, _value) internal {
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        emit Transfer(_from, _to, _value);
    }
}