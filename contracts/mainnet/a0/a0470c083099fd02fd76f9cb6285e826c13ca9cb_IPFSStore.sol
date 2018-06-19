pragma solidity ^0.4.21;

contract IPFSStore {
    mapping (uint256 => string) hashes;
    address owner;

    function IPFSStore() public {
        owner = msg.sender;
    }

    function setHash(uint256 time_stamp, string ipfs_hash) public {
        require(msg.sender == owner);
        hashes[time_stamp] = ipfs_hash;
    }

    function getHash(uint256 time_stamp) constant public returns (string) {
        return hashes[time_stamp];
    }
}