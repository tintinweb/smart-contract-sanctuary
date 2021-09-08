/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract KaymeToken{
  // name
  string public name = "Kayme Token";
  // Symbol or Ticker
  string public symbol = "KAYME";
  // decimal 
  uint256 public decimals = 3;
  // totalsupply
  uint256 public totalSupply;
  
  // transfer event
  event Transfer(address indexed sender,address indexed nereye,uint256 miktar);

  // Approval
  event Approval(address indexed Nereden , address indexed harcayan, uint256 miktar);
  
 // balance mapping  
  mapping (address => uint256) public balanceOf;
  
  // allowance mapping
  mapping(address => mapping(address => uint256)) public allowance;
//   allowance[msg.sender][_harcayan] = miktar
//  a[msg.sender][_harcayanaddres ] = 1000;
  
  constructor(uint256 _totalsupply)  {
      totalSupply = _totalsupply; 
      balanceOf[msg.sender] = _totalsupply;
  }
  
  // transfer function
  function transfer(address _nereye,uint256 _miktar) public returns(bool success){
  // the user that is transferring must have suffiecent balance
  require(balanceOf[msg.sender] >= _miktar , 'Yeterli bakiyeniz bulunmamaktadir...');
  // subtracnt the miktar from sender
  balanceOf[msg.sender] -= _miktar;
  // add the miktar to the user transfered
  balanceOf[_nereye] += _miktar;
  emit Transfer(msg.sender,_nereye,_miktar);
  return true;
  }

  // approve function
  function approve(address _harcayan,uint256 _miktar) public returns(bool success){
  // increase allownce
  allowance[msg.sender][_harcayan] += _miktar;
  // emit allownce event
  emit Approval(msg.sender,_harcayan,_miktar);
  return true;
  }
  
  // transferFrom function
  function transferFrom(address _nereden,address _nereye,uint256 _miktar) public returns(bool success){
  // check the balance of from user
  require(balanceOf[_nereden] >= _miktar,' Kullanicinin yeterli bakiyesi yok...');
  // check the allownce of the msg.sender
  require(allowance[_nereden][msg.sender] >= _miktar,'Harcama iznine sahip kullanicinin gerekli odenegi bulunmamaktadir....');
  // subtract the miktar from user
  balanceOf[_nereden] -= _miktar;
  // add the miktar to user
  balanceOf[_nereye] += _miktar;
  // decrese the allownce
  allowance[_nereden][msg.sender] -= _miktar;
  // emit transfer
  emit Transfer(_nereden,_nereye,_miktar);
  return true;
  }
 
  
}