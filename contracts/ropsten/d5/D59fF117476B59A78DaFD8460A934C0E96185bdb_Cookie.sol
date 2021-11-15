pragma solidity ^0.8.3;

contract Bakery {

  // index of created contracts

  Cookie[] public contracts;

  // useful to know the row count in contracts index

  function getContractCount() public view returns(uint contractCount)
  {
    return contracts.length;
  }

  // deploy a new contract

  function newCookie() public returns(Cookie newContract)
  {
    Cookie c = new Cookie();
    contracts.push(c);
    return c;
  }
}


contract Cookie {



  function getFlavor() public returns (string memory flavor)
  {
    return "mmm ... chocolate chip";
  }    
}

