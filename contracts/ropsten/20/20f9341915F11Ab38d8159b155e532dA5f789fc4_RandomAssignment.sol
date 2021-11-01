/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity >=0.4.25 <0.6.0;


contract RandomAssignment {

  enum ContractStates { Join, SecretRevealed}
  ContractStates myState;


  // g^(ab) mod p
  uint256 g;
  uint256 a;
  uint256 p;
  uint256 ga; // g^a mod p
  bytes32 commitga;

  address owner;

  mapping (address => uint256) commits;

  constructor(uint256 _g, bytes32 _c, uint256 _p) public {
    commitga = _c;
    g = _g;
    p = _p;
    myState = ContractStates.Join;
    owner = msg.sender;
  }

  function join(uint256 _b) public {
    require (myState == ContractStates.Join, "No one can join anymore!");
    commits[msg.sender] = _b;
  }

  function reveal(uint256 _ga, uint256 _a) public {
    require (msg.sender == owner, "Only owner!");
    require (myState == ContractStates.Join, "You cant reveal twice!");
    myState = ContractStates.SecretRevealed;
    a = _a;
    ga = _ga;
    // verificar se sha(_ga)==commitga
  }

  function getGenerator() public view returns (uint256) {
      return g;
  }

  function getPrime() public view returns (uint256) {
      return p;
  }

  function getExp() public view returns (uint256) {
    require (myState ==ContractStates.SecretRevealed,"Not yet!");
    return a;
  }

  function getGA() public view returns (uint256) {
    require (myState ==ContractStates.SecretRevealed,"Not yet!");
    return ga;
  }


  function getCommit(address who) public view returns (uint256) {
    return commits[who];
  }



}