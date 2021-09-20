/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ERC20Interface{
    //total supply
    //function totalsupply() external view returns(uint);
    //balanceof
    //function balanceOF(address tokenOwner) external view returns(uint balance);
    //allowance
    //function allowance(address tokenOwner, address spender) external view returns(uint256 remaining);
    //Approve
    function approve(address _spender, uint256 _value) external returns(bool success);
    //transfer
    function transfer(address to, uint256 tokens) external returns(bool success);
    //transferFrom
    function transferFrom(address  _from, address _to, uint256 _value) external returns(bool success);
    //event transfer
    event Transfer(address indexed from, address indexed _to, uint value);
    //event Approval
    event Approve(address indexed _owner, address indexed _spender, uint256 _value);
}


contract MyToken is ERC20Interface{
    string public name;
    string public symbol;
    uint Totalsupply;
    
    mapping(address => uint256) public Balanceof;
    mapping(address => mapping(address => uint256)) private allowance;
    
    constructor( uint256 _initialsupply){
        name = "Snapper";
        symbol = "SFT";
        Balanceof[msg.sender] = _initialsupply;
        Totalsupply = _initialsupply;
    }
    
    function transfer(address _to, uint256 _value) public override returns(bool success){
        require(Balanceof[msg.sender] >= _value);
        Balanceof[msg.sender] -= _value;
        Balanceof[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public override returns(bool sucess){
        allowance[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public override returns(bool success){
        require(_value <= Balanceof[_from]); //checking if owner has enough Balance
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        Balanceof[_from] -= _value;
        Balanceof[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}