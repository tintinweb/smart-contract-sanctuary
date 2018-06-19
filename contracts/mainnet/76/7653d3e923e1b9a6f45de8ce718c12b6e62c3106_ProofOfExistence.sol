pragma solidity ^0.4.18;

contract ProofOfExistence {

  event ProofCreated(bytes32 documentHash, uint256 timestamp);

  address public owner = msg.sender;

  mapping (bytes32 => uint256) hashesById;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier noHashExistsYet(bytes32 documentHash) {
    require(hashesById[documentHash] == 0);
    _;
  }

  function ProofOfExistence() public {
    owner = msg.sender;
  }

  function notarizeHash(bytes32 documentHash) onlyOwner public {
    var timestamp = block.timestamp;
    hashesById[documentHash] = timestamp;
    ProofCreated(documentHash, timestamp);
  }

  function doesProofExist(bytes32 documentHash) public view returns (uint256) {
    if (hashesById[documentHash] != 0) {
      return hashesById[documentHash];
    }
  }
}