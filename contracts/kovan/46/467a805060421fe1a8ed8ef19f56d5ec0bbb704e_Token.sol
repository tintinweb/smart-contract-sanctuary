/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token{
    string public name="ETV_Community_Token";
    string public symbol="ETV";
    uint256 public decimals=18;
    uint256 public totalSupply=1000;
    
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from,address indexed to,uint256 value);
    
    constructor(string memory _name,string memory _symbol,uint _decimal,uint _total){
        name=_name;
        symbol=_symbol;
        decimals=_decimal;
        totalSupply=_total;
        balanceOf[msg.sender]=totalSupply;
    }
    
    function transfer(address _to,uint256 _value)external returns(bool sucess){
        require(balanceOf[msg.sender]>=_value);
        balanceOf[msg.sender]=balanceOf[msg.sender]-(_value);
        balanceOf[_to]=balanceOf[_to]+(_value);
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    
}