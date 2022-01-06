/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.7;

contract ERC20Token {

    event Transfer(address indexed _from,
    address indexed _to,
    uint256 _value);

    event Approval(address indexed _owner,
    address indexed _spender,
    uint256 _value );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;


    string public name;
    string public symbol;
    uint256 public decimal;
    uint256 public totalSupply;

    constructor (string memory _name, string memory _symbol, uint256 _decimal, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;

    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value,"Insufficient balance for transfer");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;



    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        //uint256 allowed = allowance[_from][msg.sender];
        require(balanceOf[_from] >= _value);
        require (allowance[_from][msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        allowance [_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    
    }
    
}