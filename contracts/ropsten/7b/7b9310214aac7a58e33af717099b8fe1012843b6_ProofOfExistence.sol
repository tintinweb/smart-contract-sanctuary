pragma solidity ^0.4.23;

contract ProofOfExistence {
    
    event ProofCreated(
        uint256 indexed uuid,
        string name,        
        string ssn,
        string title,
        bytes32 documentHash
    );

    address public owner;
  
    mapping (uint256 => bytes32) hashesById;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier noHashExistsYet(uint256 uuid) {
        require(hashesById[uuid] == &quot;&quot;);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function notarizeHash(uint256 uuid, string name, string ssn, string title, bytes32 documentHash) onlyOwner noHashExistsYet(uuid) public {
        hashesById[uuid] = documentHash;

        emit ProofCreated(uuid, name, ssn, title, documentHash);
    }

    function doesProofExist(uint256 uuid, bytes32 documentHash) public view returns (bool) {
        return hashesById[uuid] == documentHash;
    }
}