/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract DogeCoins{
  // Nombre
  string public name = "Doge Coin";
  // Symbolo del token
  string public symbol = "DOG";
  // Decimales 
  uint256 public decimals = 18;
  // totalsupply
  uint256 public totalSupply;
  
  // Evento de transferencia
  event Transfer(address indexed sender,address indexed to,uint256 amount);

  // Aprovación
  event Approval(address indexed From , address indexed spender, uint256 amount);
  
 // Mapeando el balance 
  mapping (address => uint256) public balanceOf;
  
  // Mapeando el allowance
  mapping(address => mapping(address => uint256)) public allowance;
//   allowance[msg.sender][_spender] = amount
//  a[msg.sender][_spenderaddres ] = 1000;
  
  constructor(uint256 _totalsupply)  {
      totalSupply = _totalsupply; 
      balanceOf[msg.sender] = _totalsupply;
  }
  
  // Función de transferencia
  function transfer(address _to,uint256 _amount) public returns(bool success){
  // El usuario que quiere realizar la transferencia no cuenta con los fondos suficientes
  require(balanceOf[msg.sender] >= _amount , 'No cuentas con el fondo suficiente');
  // Sustrar el monto del usuario
  balanceOf[msg.sender] -= _amount;
  // Añadir el monto al usuario que se le transfirió
  balanceOf[_to] += _amount;
  emit Transfer(msg.sender,_to,_amount);
  return true;
  }

  // Función de aprovación
  function approve(address _spender,uint256 _amount) public returns(bool success){
  // Incrementar allowance
  allowance[msg.sender][_spender] += _amount;
  // Emitir evento de allowance
  emit Approval(msg.sender,_spender,_amount);
  return true;
  }
  
  // Functions transferFrom
  function transferFrom(address _from,address _to,uint256 _amount) public returns(bool success){
  // Verificar el balance del usuario
  require(balanceOf[_from] >= _amount,'El usuario cuenta con suficiente saldo.');
  // verificar el allowance desde msg.sender
  require(allowance[_from][msg.sender] >= _amount,'El usuario no fue aprovado');
  // Sustraer el mondo desde el usuario
  balanceOf[_from] -= _amount;
  // Añadir el monto al usuario
  balanceOf[_to] += _amount;
  // Restar el allowance
  allowance[_from][msg.sender] -= _amount;
  // Emitir trasnferencia
  emit Transfer(_from,_to,_amount);
  return true;
  }
 
  
}