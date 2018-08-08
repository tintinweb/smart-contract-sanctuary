pragma solidity ^0.4.24;

contract Bakery {

  // index of created contracts

  address[] public contracts;

  // useful to know the row count in contracts index

  function getContractCount()
    public
    constant
    returns(uint256)
  {
    return contracts.length;
  }

  // deploy a new contract

  function newCookie()
    public
    returns(address)
  {
    address c = new Cookie();
    contracts.push(c);
    return c;
  }
}


contract Cookie {

  // suppose the deployed contract has a purpose

  function getFlavor()
    public
    constant
    returns (string)
  {
    return "mmm ... chocolate chip";
  }
}