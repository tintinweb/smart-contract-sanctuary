/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Token{
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
     
     constructor(string memory _name,string memory _symbol,uint _decimals,uint _totalSupply){
         name=_name;
         symbol=_symbol;
         decimals=_decimals;
         totalSupply=_totalSupply;
         balanceOf[msg.sender]=totalSupply;
     }
     function transfer(uint256 _value,address _to) public returns(bool){
         require(balanceOf[msg.sender]>=_value);
         _transfer(msg.sender,_to,_value);
         return true;
     }
     function _transfer(address _from,address _to,uint256 _value) internal{
         require(_to!=address(0));
         balanceOf[_from]-=_value;
         balanceOf[_to]+=_value;
         emit Transfer(msg.sender,_to,_value);
     }
     function approve(address _spender,uint256 _value) public returns(bool){
         require(_spender!=address(0));
         allowance[msg.sender][_spender]+=_value;
         emit Approval(msg.sender,_spender,_value);
         return true;
     }
     function transferFrom(address _from,address _to,uint256 _value) public returns(bool){
         require(balanceOf[_from]>=_value);
         require(allowance[_from][msg.sender]>=_value);
         _transfer(_from,_to,_value);
         allowance[_from][msg.sender]-=_value;
         return true;
     }

}