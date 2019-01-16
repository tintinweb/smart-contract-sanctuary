pragma solidity 0.5.0;

contract Election {

    // r07741032 HW4 in NTU IOT
    
    struct Candidate {
        uint256 id;
        string name;
        address addr;
        uint256 voteCount;
    }

    address public owner;

    mapping(address => bool) public voted;
    mapping(uint => Candidate) public candidates;
    uint256 public candidatesCount;
    
    uint256 public startTime;
    uint256 public endTime;
    bool public initialized;

    event Voted (uint256 indexed candidateId);
    event CandidateAdded(string name);
    event Finalized(uint256 indexed id, string name, address addr, uint256 voteCount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function initialize(uint256 _startTime, uint256 _endTime) public {
        require(msg.sender == owner && !initialized);
        
        startTime = _startTime;
        endTime = _endTime;
        initialized = true;
    }

    function addCandidate(string memory _name, address _addr) public {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _addr, 0);
        
        emit CandidateAdded(_name);
    }

    function vote(uint256 _candidateId) public {
        require(!voted[msg.sender]);
        require(now > startTime && now < endTime);
        require(_candidateId != 0 && _candidateId <= candidatesCount);

        voted[msg.sender] = true;
        candidates[_candidateId].voteCount++;

        emit Voted(_candidateId);
    }
    
    function finalize() public {
        require(now > endTime);
        
        for(uint256 i = 1; i <= candidatesCount; i++) {
            emit Finalized(candidates[i].id, candidates[i].name, candidates[i].addr, candidates[i].voteCount);
        }
    }
}