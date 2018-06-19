pragma solidity ^0.4.13;

contract Registrar {
  function transfer(bytes32 _hash, address newOwner);
  function entries(bytes32 _hash) constant returns (uint, Deed, uint, uint, uint);
}

contract Deed {
  address public owner;
  address public previousOwner;
}

contract ownerCheck{
  Registrar registrar = Registrar(0x6090A6e47849629b7245Dfa1Ca21D94cd15878Ef);  

  function ownerCheck() {}

  function checkOwner(bytes32 label) returns(address){
    Deed deed;
    (,deed,,,) = registrar.entries(label); 
    return deed.owner();
  }

  function checkPrevOwner(bytes32 label) returns(address){
    Deed deed;
    (,deed,,,) = registrar.entries(label); 
    return deed.previousOwner();
    } 
 
}