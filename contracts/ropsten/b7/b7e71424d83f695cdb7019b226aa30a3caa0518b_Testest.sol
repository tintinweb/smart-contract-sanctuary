/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
 abstract contract  EIP20Interface {

    uint256 public totalSupply;

    function  balanceOf(address _owner) virtual public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) virtual
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) virtual public returns (bool success);

    function approve(address _spender, uint256 _value) virtual
        public 
        returns (bool success);
    function allowance(address _owner, address _spender) virtual
        public
        view
        returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract Testest  {
    constructor(address _addr){
        addrrrr = EIP20Interface(_addr);
    }
    EIP20Interface addrrrr;
    event Add(uint256 indexed amount);
    mapping(address => uint256) public values;
    
    function set_value(uint256 _value) public returns(bool _result){
        values[msg.sender] = _value;
        emit Add(_value);
        _result =true;
    }
    
    function add_value(uint256 _value) public returns(bool _result){
        values[msg.sender] += _value;
        _result =true;
    }
    
    function sub_value(uint256 _value) public returns(bool _result){
        values[msg.sender] -= _value;
        _result =true;
    }
    
    function get_value() public view returns( uint256 _result){
        _result = values[msg.sender];
    }
    
    function get_value1(address _value) public view returns( uint256 _result){
        _result = values[_value];
    }
    
    function trnasfer(address _addr, uint256 _amount)public returns(bool _result){
        addrrrr.transfer(_addr, _amount);
        addrrrr.transfer(_addr, _amount);
        addrrrr.transfer(_addr, _amount);
        addrrrr.transfer(_addr, _amount);
        _result = true;
    }
}