/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Splyta {
    string public symbol;
    string public name;
    address private owner;
    uint256 totalSupply = 1000 * 1000000000000000000;
    uint8 public decimals = 18;


    mapping(address => uint256 ) public balanceOf;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );

    constructor(){
        owner = msg.sender;
        name = "Splyta";
        symbol = "SPLYTA";
        balanceOf[msg.sender]= 100 * 1000000000000000000;
    }

    function transfer(address _to, uint256 _value) public payable returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Error: Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

}