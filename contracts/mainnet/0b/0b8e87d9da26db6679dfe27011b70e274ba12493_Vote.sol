pragma solidity ^0.4.23;

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Vote is Ownable {
    // Candidate registered
    event CandidateRegistered(uint candidateId, string candidateName, string candidateDescription);
    // Vote cast
    event VoteCast(uint candidateId);

    struct Candidate {
        uint candidateId;
        string candidateName;
        string candidateDescription;
    }

    uint internal salt;
    string public voteName;
    uint public totalVotes;

    // mapping of candidate IDs to votes
    mapping (uint => uint) public voteCount;
    // mapping of scerets to vote status
    mapping (bytes32 => bool) internal canVote;
    // counter/mapping of candidates
    uint public nextCandidateId = 1;
    mapping (uint => Candidate) public candidateDirectory;

    constructor(uint _salt, string _voteName, bytes32[] approvedHashes) public {
        salt = _salt;
        voteName = _voteName;
        totalVotes = approvedHashes.length;
        for (uint i; i < approvedHashes.length; i++) {
            canVote[approvedHashes[i]] = true;
        }
    }

    // Allows the owner to register new candidates
    function registerCandidate(string candidateName, string candidateDescription) public onlyOwner {
        uint candidateId = nextCandidateId++;
        candidateDirectory[candidateId] = Candidate(candidateId, candidateName, candidateDescription);
        emit CandidateRegistered(candidateId, candidateName, candidateDescription);
    }

    // get candidate information by id
    function candidateInformation(uint candidateId) public view returns (string name, string description) {
        Candidate storage candidate = candidateDirectory[candidateId];
        return (candidate.candidateName, candidate.candidateDescription);
    }

    // Users can only vote by providing a secret uint s.t. candidateDirectory[keccak256(uint, salt)] == true
    function castVote(uint secret, uint candidateId) public {
        bytes32 claimedApprovedHash = keccak256(secret, salt); // keccak256(secret) vulnerable to a rainbow table attack
        require(canVote[claimedApprovedHash], "Provided secret was not correct.");
        canVote[claimedApprovedHash] = false;
        voteCount[candidateId] += 1;

        emit VoteCast(candidateId);
    }
}