pragma solidity ^0.4.23;

contract IPFSStore {
    struct IPFSHashes {
        bytes32 hash;
        uint8 hashfunction;
        uint8 size;
    }
    
    bytes32 h1;
    event PostProducts (
        address indexed_from , 
        bytes32 hash_start ,
        bytes32 hash_end,
        bytes1 ptype
        );
        
    IPFSHashes[] All_hashes;
    bytes32[] all_fhashes;
    
    function addProduct(bytes32 _hash , uint8 _hashfunction , uint8 _size) public {
        IPFSHashes memory record = IPFSHashes(_hash , _hashfunction , _size);
        All_hashes.push(record);
        all_fhashes.push(record.hash);
    }
    
    function postProduct(bytes32 _hash_start , bytes32 _hash_end , bytes1 _pytpe) public {
        emit PostProducts(msg.sender , _hash_start , _hash_end , _pytpe);
    }
    
    
}