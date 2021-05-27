/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.5.17;

contract eficcientExampleCode {

  struct storing {
    uint value;
  }

  mapping (uint => storing) public map;

  uint pointer = 0;
  
  event newHash(uint _hash, uint _id);

  function storeHash(uint _hash, uint _id) public {
    storing storage proof = map[_id];
    proof.value = _hash;
    emit newHash(_hash, _id);
    //pointer += 1;
  }

}