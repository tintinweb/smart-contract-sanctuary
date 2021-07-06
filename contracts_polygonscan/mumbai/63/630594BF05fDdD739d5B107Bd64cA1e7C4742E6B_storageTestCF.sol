/**
 *Submitted for verification at polygonscan.com on 2021-06-29
*/

pragma solidity ^0.5.17;

contract storageTestCF {

  struct storing {
    string value;
    string tipus;
  }

  mapping (uint => storing) public map;
  
  event newHash(string _hash, uint _id);

  function storeHash(string memory _hash, uint _id) public {
    storing storage proof = map[_id];
    proof.value = _hash;
    proof.tipus = 'animal';
    emit newHash(_hash, _id);
  }

}