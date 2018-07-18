pragma solidity ^0.4.23;

contract ProofOfExistence {
    
    event ProofCreated(
        uint256 indexed id,
        string name,
        string email,
        bytes32 documentHash,
        string ssn,
        string title,
        string filekey        
    );

    address public owner;
  
    mapping (uint256 => bytes32) hashesById;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier noHashExistsYet(uint256 id) {
        require(hashesById[id] == &quot;&quot;);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function notarizeHash(uint256 id, string name, string email, bytes32 documentHash, string ssn, string title, string filekey) onlyOwner noHashExistsYet(id) public {
        hashesById[id] = documentHash;

        emit ProofCreated(id, name, email, documentHash, ssn, title, filekey);
    }

    function doesProofExist(uint256 id, bytes32 documentHash) public view returns (bool) {
        return hashesById[id] == documentHash;
    }
}