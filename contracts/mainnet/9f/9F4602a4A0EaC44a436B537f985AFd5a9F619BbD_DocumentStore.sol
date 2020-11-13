pragma solidity ^0.5.16;

import "./Ownable.sol";

contract DocumentStore is Ownable {
  string public name;
  string public version = "2.3.0";

  /// A mapping of the document hash to the block number that was issued
  mapping(bytes32 => uint256) public documentIssued;
  /// A mapping of the hash of the claim being revoked to the revocation block number
  mapping(bytes32 => uint256) public documentRevoked;

  event DocumentIssued(bytes32 indexed document);
  event DocumentRevoked(bytes32 indexed document);

  constructor(string memory _name) public {
    name = _name;
  }

  function issue(bytes32 document) public onlyOwner onlyNotIssued(document) {
    documentIssued[document] = block.number;
    emit DocumentIssued(document);
  }

  function bulkIssue(bytes32[] memory documents) public {
    for (uint256 i = 0; i < documents.length; i++) {
      issue(documents[i]);
    }
  }

  function getIssuedBlock(bytes32 document) public view onlyIssued(document) returns (uint256) {
    return documentIssued[document];
  }

  function isIssued(bytes32 document) public view returns (bool) {
    return (documentIssued[document] != 0);
  }

  function isIssuedBefore(bytes32 document, uint256 blockNumber) public view returns (bool) {
    return documentIssued[document] != 0 && documentIssued[document] <= blockNumber;
  }

  function revoke(bytes32 document) public onlyOwner onlyNotRevoked(document) returns (bool) {
    documentRevoked[document] = block.number;
    emit DocumentRevoked(document);
  }

  function bulkRevoke(bytes32[] memory documents) public {
    for (uint256 i = 0; i < documents.length; i++) {
      revoke(documents[i]);
    }
  }

  function isRevoked(bytes32 document) public view returns (bool) {
    return documentRevoked[document] != 0;
  }

  function isRevokedBefore(bytes32 document, uint256 blockNumber) public view returns (bool) {
    return documentRevoked[document] <= blockNumber && documentRevoked[document] != 0;
  }

  modifier onlyIssued(bytes32 document) {
    require(isIssued(document), "Error: Only issued document hashes can be revoked");
    _;
  }

  modifier onlyNotIssued(bytes32 document) {
    require(!isIssued(document), "Error: Only hashes that have not been issued can be issued");
    _;
  }

  modifier onlyNotRevoked(bytes32 claim) {
    require(!isRevoked(claim), "Error: Hash has been revoked previously");
    _;
  }
}
