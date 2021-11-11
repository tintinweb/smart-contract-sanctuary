/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;contract Token {
    
string public name;
string public symbol;
uint256 public decimals;
uint256 public totalSupply;
mapping(address => uint256) public balanceOf;
mapping(address => mapping ( address => uint256 )) public Defi_Allowence;
event Transfer( address indexed from , address indexed to ,uint256 value);
event Approve( address indexed owner , address indexed spender , uint256 value);
constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
name = _name;
symbol = _symbol;
decimals = _decimals;
totalSupply = _totalSupply;
balanceOf[msg.sender] = totalSupply;
}
function transfer( address _to , uint256 _value) external returns (bool success){
require(balanceOf[msg.sender] >= _value);
_transfer(msg.sender , _to , _value);
return true;
}
function _transfer(address _from , address _to , uint256 _value ) internal {
require(_to != address(0)); //it checks that the receiver address is not null
balanceOf[_from] = balanceOf[_from] - (_value);
balanceOf[_to] = balanceOf[_to] + (_value);
emit Transfer(_from , _to , _value);
}
function approval(address _spender , uint256 _value) external returns (bool){
require(_spender != address(0));
Defi_Allowence[msg.sender][_spender] = _value;
emit Approve(msg.sender , _spender , _value);
return true;
} function transferFrom(address _from , address _to , uint256 _value) external returns (bool){
require(_value <= balanceOf[_from]);
require(_value <= Defi_Allowence[_from][msg.sender]);
Defi_Allowence[_from][msg.sender] = Defi_Allowence[_from][msg.sender] - (_value);
_transfer(_from , _to , _value);
return true;
}
    
}