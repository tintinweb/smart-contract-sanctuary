/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity >=0.4.25 <0.6.0;


contract CommitVector {

  enum ContractStatesType {Commit,Reval,Finished}
  ContractStatesType contractState;

  enum CommitStatesType {Waiting,Revealed}

  struct OneCommit {
    bytes32 commit;
    byte[] value;
    bool verified;
    CommitStatesType myState;
    }

  mapping(address => OneCommit) myCommits;

  address owner;

  constructor() public {
    owner = msg.sender;
    contractState = ContractStatesType.Commit;
  }


  function commit(bytes32 commitValue) public {
    OneCommit memory c;
    c.commit = commitValue;
    c.verified = false;
    c.myState = CommitStatesType.Waiting;
    myCommits[msg.sender] = c;
  }


  function reveal(bytes32 nonce, byte[] memory v) public {


    bytes memory bs = abi.encodePacked(nonce);
    for (uint i=0;i<v.length;i++) {
      bs = abi.encodePacked(bs,v[i]);
    }
    bytes32 ver = sha256(bs);
    //bytes32 ver = sha256(abi.encodePacked(nonce,v));

    myCommits[msg.sender].myState = CommitStatesType.Revealed;
    if (ver==myCommits[msg.sender].commit) {
      myCommits[msg.sender].verified = true;
      myCommits[msg.sender].value =v;
    }
  }

  /*function calc(bytes32 nonce, byte v) public returns (bytes32){

    bytes32 ver = sha256(abi.encodePacked(nonce,v));
    return ver;

  }*/


  function isCorrect(address other) public returns (bool) {
    return myCommits[other].verified;
  }

  function getValue(address other) public returns(byte[] memory) {
    return myCommits[other].value;
  }


}