pragma solidity ^0.4.23;


/*
* @title Capture
* @author Parker McCurley (parker@decentcrypto.com)
* @notice Capture is meant to store ipfs hashes and emit events as they are stored
*/
contract Capture {
  struct IPFSHash {
    address sender;
    string hash;
  }

  mapping(bytes32 => IPFSHash) public ipfsHashes;
  mapping(bytes32 => bool) private hashExists;

  event HashStored(address indexed sender, string ipfsHash);

  /*
  * @notice Retrieve a stored ipfs hash object
  * @param ipfsHash String that will be used to lookup the hash
  */
  function retrieve(string ipfsHash) public view returns (address, string) {
    bytes32 hash = keccak256(abi.encodePacked(ipfsHash));

    return (ipfsHashes[hash].sender, ipfsHashes[hash].hash);
  }

  /*
  * @notice Store an ipfs hash and emit a HashStored event
  * @param ipfsHash String that will be stored in the contract
  */
  function store(string ipfsHash) public {
    bytes32 hash = keccak256(abi.encodePacked(ipfsHash));

    require(!hashExists[hash]);

    ipfsHashes[hash].sender = msg.sender;
    ipfsHashes[hash].hash = ipfsHash;

    hashExists[hash] = true;

    emit HashStored(ipfsHashes[hash].sender, ipfsHashes[hash].hash);
  }
}