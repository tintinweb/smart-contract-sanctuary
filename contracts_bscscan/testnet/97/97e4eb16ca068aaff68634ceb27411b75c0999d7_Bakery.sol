/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

pragma solidity ^0.4.8;

contract Bakery {

  // index of created contracts

  address[] public contracts;

  // useful to know the row count in contracts index

  function getContractCount() 
    public
    constant
    returns(uint contractCount)
  {
    return contracts.length;
  }

  // deploy a new contract

  function newCookie(string newName, uint8 newDecimals)
    public
    returns(address)
  {
    Cookie c = new Cookie(newName, newDecimals);
    contracts.push(c);
    return c;
  }
}


contract Cookie {

  // suppose the deployed contract has a purpose
  address public myAddress;
  string public name;
  uint8 public decimals;
  
  constructor(string _name, uint8 _decimals){
      name = _name;
      decimals = _decimals;
      myAddress = msg.sender;
  }

  function getFlavor()
    public
    constant
    returns (string)
  {
    return "mmm ... chocolate chip";
  }    
}