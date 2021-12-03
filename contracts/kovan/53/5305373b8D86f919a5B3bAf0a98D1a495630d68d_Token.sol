/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract Token {
    // "My Token", "MTK", 18, 1000000000000000000000000
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowonce;

    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);

    constructor (string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer (address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer (address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function tranferFrom (address _from, address _to, uint256 _value) external returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowonce[_from][_to]);
        allowonce[_from][_to] = allowonce[_from][_to] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve (address _spender, uint256 _value) external returns (bool success) {
        require(_spender != address(0));
        allowonce[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}