pragma solidity ^0.4.23;

contract ProofOfExistence {
    
    event ProofCreated(
        uint256 indexed id,
        string name,
        string email,
        uint256 phone,
        bytes32 documentHash
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

    function notarizeHash(uint256 id, string name, string email, uint256 phone, bytes32 documentHash) onlyOwner noHashExistsYet(id) public {
        hashesById[id] = documentHash;

        emit ProofCreated(id, name, email, phone, documentHash);
    }

    function doesProofExist(uint256 id, string name, string email, uint256 phone, bytes32 documentHash) public view returns (bool) {
        return hashesById[id] == documentHash;
    }
}