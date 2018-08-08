// Minimum required version of Solidity (Ethereum programming language)
pragma solidity ^0.4.0;

// Soldity contract for proof of perception
contract Percept {

    mapping(bytes32 => Proof) public proofs;    // Proof storage mappings (key => value data)

    struct Proof {              // Proof data type
        // Pre-release data
        address creator;        // Address of the proof maker
        bytes32 hash;           // 1-way hash of the proof text
        uint timestamp;         // Unix timestamp of the proof&#39;s creation
        uint blockNum;          // Latest block number during proof creation
        bytes32 proofMapping;   // Mapping hash of sender address, timestamp, block number, and proof hash

        // Post-release data
        string release;         // Proof string of perception
        bool released;          // Whether this proof has been released or not
        uint releaseTime;       // Unix timestamp of the proof&#39;s release
        uint releaseBlockNum;   // Latest block number during proof release
    }

    // Function to submit a new unreleased proof
    // Param: hash (32 bytes) - Hash of the proof text
    function submitProof(bytes32 hash) public returns (bytes32) {
        uint timestamp = now;   // Current unix timestamp
        uint blockNum = block.number;   // Current block number this transaction is in

        bytes32 proofMapping = keccak256(abi.encodePacked(msg.sender, timestamp, blockNum, hash));    // Mapping hash of proof data

        // Construct the proof in memory, unreleased
        Proof memory proof = Proof(msg.sender, hash, timestamp, blockNum, proofMapping, "", false, 0, 0);

        // Store the proof in the contract mapping storage
        proofs[proofMapping] = proof;
        
        return proofMapping; // Return the generated proof mapping
    }

    // Release the contents of a submitted proof
    // Param: proofMapping (32 bytes) - The key to lookup the proof
    // Param: release (string) - The text that was originally hashed
    function releaseProof(bytes32 proofMapping, string release) public {
        // Load the unreleased proof from storage
        Proof storage proof = proofs[proofMapping];

        require(msg.sender == proof.creator);       // Ensure the releaser was the creator
        require(proof.hash == keccak256(abi.encodePacked(release)));  // Ensure the release string&#39;s hash is the same as the proof
        require(!proof.released);                   // Ensure the proof isn&#39;t released yet

        proof.release = release;                // Release the proof text
        proof.released = true;                  // Set proof released flag to true
        proof.releaseTime = now;                // Set the release unix timestamp to now
        proof.releaseBlockNum = block.number;   // Set the release block number to the current block number
    }

    // Function to determine whether a proof is valid for a certain verification string
    // Should not be called on blockchain, only on local cache
    // Param: proofMapping (32 bytes) - The key to lookup the proof
    // Param: verify (string) - The text that was supposedly originally hashed
    function isValidProof(bytes32 proofMapping, string verify) public view returns (bool) {
        Proof memory proof = proofs[proofMapping]; // Load the proof into memory

        require(proof.creator != 0); // Ensure the proof exists

        return proof.hash == keccak256(abi.encodePacked(verify)); // Return whether the proof hash matches the verification&#39;s hash
    }

    // Functon to retrieve a proof that has not been completed yet
    // Should not be called on blockchain, only on local hash
    // Param: proofMapping (32 bytes) - The key to lookup the proof
    function retrieveIncompleteProof(bytes32 proofMapping) public view returns (
        address creator,
        bytes32 hash,
        uint timestamp,
        uint blockNum
    ) {
        Proof memory proof = proofs[proofMapping];  // Load the proof into memory
        require(proof.creator != 0);                // Ensure the proof exists
        require(!proof.released);                   // Ensure the proof has not been released

        // Return the collective proof data individually
        return (
            proof.creator,
            proof.hash,
            proof.timestamp,
            proof.blockNum
        );
    }

    // Functon to retrieve a proof that has been completed
    // Should not be called on blockchain, only on local hash
    // Param: proofMapping (32 bytes) - The key to lookup the proof
    function retrieveCompletedProof(bytes32 proofMapping) public view returns (
        address creator,
        string release,
        bytes32 hash,
        uint timestamp,
        uint releaseTime,
        uint blockNum,
        uint releaseBlockNum
    ) {
        Proof memory proof = proofs[proofMapping];  // Load the proof into memory
        require(proof.creator != 0);                // Ensure the proof exists
        require(proof.released);                    // Ensure the proof has been released

        // Return the collective proof data individually
        return (
            proof.creator,
            proof.release,
            proof.hash,
            proof.timestamp,
            proof.releaseTime,
            proof.blockNum,
            proof.releaseBlockNum
        );
    }

}