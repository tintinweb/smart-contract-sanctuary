/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.6 <0.9.0;

//import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';

contract MyTokenBSC{
 // Variables
 
 string public name = "JFDESOUSA TOKEN";
 string public symbol = "JFDS";
 uint8 public decimals = 18;
 uint public totalSupply = 1000000 * 10 ** 18;
 
 mapping(address => uint) public balanceOf;
 mapping(address => mapping(address => uint)) public allowance;
 
 
 // Events
 event Transfer(address indexed from, address indexed to, uint amount);
 event Approval(address indexed owner, address indexed spender, uint amount);
 event TransferFrom(address indexed from, address indexed to, uint amount);
 
 constructor() {
     balanceOf[msg.sender] = totalSupply;
 }  
 
 
 function transfer(address _to, uint _amount) public {
     require(balanceOf[msg.sender] >= _amount, 'Balance too slow');
     balanceOf[msg.sender] -= _amount;
     balanceOf[_to] += _amount;
     emit Transfer(msg.sender, _to, _amount);
 }
 
 function approve(address _spender, uint _amount) public {
     allowance[msg.sender][_spender] = _amount;
     emit Approval(msg.sender, _spender, _amount);
 }
 
 function transferFrom(address _from, address _to, uint _amount) public {
     require(balanceOf[_from] >= _amount, 'Balance too slow');
     require(allowance[_from][msg.sender] >= _amount, 'Balance too slow');
     
     allowance[_from][msg.sender] -= _amount;
     balanceOf[_from] -= _amount;
     balanceOf[_to] += _amount;
     
     emit TransferFrom(_from, _to, _amount);
     
 }
 
 
}