/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract KaymeToken{
  // tokenin adı
  string public name = "Kayme Token";
  
  // sembolü
  string public symbol = "KAYME";
  
  // ondalık 
  uint256 public decimals = 11;
  
  // arz
  uint256 public totalSupply;



  
  // transfer eventi
  event Transfer(address indexed sender,address indexed nereye,uint256 miktar);

  // Approval eventi
  event Approval(address indexed Nereden , address indexed harcayan, uint256 miktar);

  
  //bakiye mapping  
  mapping (address => uint256) public balanceOf;  
  //allowance mapping
  mapping(address => mapping(address => uint256)) public allowance;




  //Yapıcı kısım 
  constructor(uint256 _totalsupply){
      totalSupply = _totalsupply; 
      balanceOf[msg.sender] = _totalsupply;
	}



  
  // transfer fonksiyonu
  function transfer(address _nereye,uint256 _miktar) public returns(bool success){
  // transfer eden kullanıcının yeterli bakiyeye sahip olması gerek
  require(balanceOf[msg.sender] >= _miktar , 'Yeterli bakiyeniz bulunmamaktadir...');
  // miktarı göndericiden eksilt
  balanceOf[msg.sender] -= _miktar;
  // transferin yapıldığı kullanıcıya miktarı ekle
  balanceOf[_nereye] += _miktar;
  emit Transfer(msg.sender,_nereye,_miktar);
  return true;
  }




  // approve fonksiyonu
  function approve(address _harcayan,uint256 _miktar) public returns(bool success){
  // ödenek artırma
  allowance[msg.sender][_harcayan] += _miktar;
  // allownce eventini yayma
  emit Approval(msg.sender,_harcayan,_miktar);
  return true;
  }
  
  
  
  
  // transferFrom fonksiyonu
  function transferFrom(address _nereden,address _nereye,uint256 _miktar) public returns(bool success){
  // kullanıcı bakiyesini kontrol et
  require(balanceOf[_nereden] >= _miktar,' Kullanicinin yeterli bakiyesi yok...');
  // msg.sender ödenegi/izni kontrol et
  require(allowance[_nereden][msg.sender] >= _miktar,'Harcama iznine sahip kullanicinin gerekli odenegi bulunmamaktadir....');
  // kullanıcıdan miktarı çıkar
  balanceOf[_nereden] -= _miktar;
  // kullanıcıya miktarı ekle
  balanceOf[_nereye] += _miktar;
  // ödeneği azalt
  allowance[_nereden][msg.sender] -= _miktar;
  // transfer eventini yay
  emit Transfer(_nereden,_nereye,_miktar);
  return true;
  }
}