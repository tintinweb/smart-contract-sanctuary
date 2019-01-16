pragma solidity ^0.4.25;

contract Blockhashes {
    
    mapping(uint => bytes32) public hashes;
    event Error(string msg);
    
    function add_recent (uint n) public {
        bytes32 h = blockhash(n);
        if (h == 0) {
            emit Error("blockhash fails");
        } else {
            hashes[n] = h;
        }
    }
    
    function add_old (uint n, bytes memory child_header) public {
        bytes32 child_hash = hashes[n+1];
        assert(child_hash == keccak256(child_header));
        bytes memory parent_hash = new bytes(32);
        for(uint i=0; i< 32; i++){
            parent_hash[i] = child_header[i+4];
        }
        bytes32 h;
        assembly {
            h := mload(add(parent_hash, 32))
        }
        hashes[n] = h;
    }
    
    function get_blockhash (uint n) public constant returns (bytes32) {
        return hashes[n];
    }
    
}