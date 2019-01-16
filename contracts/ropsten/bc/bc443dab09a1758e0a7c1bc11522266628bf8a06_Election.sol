pragma solidity 0.4.25;
//SELT Token interface
contract SELTInterface{
    string public  name;
    uint256 public totalSupply;
    address public owner;
    function burn(uint256 _value) public returns (bool success);
}

contract Election {
    SELTInterface SELT;
    string public  TokenName;
    address public TokenAddress;
    uint public StartDate ;
    uint public EndDate ;

    // Model a Candidate
    struct Candidate {
        uint8 id;
        uint identifyID;
        uint voteCount;
    }
    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store Candidates
    // Fetch Candidate
    mapping(uint8 => Candidate) public candidates;
    // Store Candidates Count
    uint8 public candidatesCount = 0;
    //Store votes Count
    uint public TotalVote;
    event SomeOneVoted(address indexed _from, address indexed _to, uint8 votes);
    // voted event
    event votedEvent (
        uint indexed _candidateId
    );
    //Result event
    event ElectionResult(uint _identifyID, uint _voteCount);
    //check address
    modifier onlyValidAddress(address _to){
        require(_to != address(0x00));
        _;
    }
    //check owner
    modifier onlyValidOwner(address _from){
        require(_from == SELT.owner());
        _;
    }
    //Check token
    modifier onlyValidSenderIsAcceptToken(address _to){
        require(_to == TokenAddress);
        _;
    }
    //Check votes
    modifier onlyAccept5Vote(uint8 votes){
        require(countBit(votes) == 5);
        _;
    }
    constructor (
        address _ElecTokenAddress,
        uint _startDate,
        uint _endDate,
        uint maxCandidate,
        uint [] identifyIDs
    )
    public {
        require(identifyIDs.length <= maxCandidate);
        //use address of Pair-Token
        SELT = SELTInterface(_ElecTokenAddress);
        TokenName = SELT.name();
        TokenAddress = _ElecTokenAddress;
        StartDate = _startDate;
        EndDate = _endDate;
        for (uint i = 0; i < identifyIDs.length ; i++){
            addCandidate(identifyIDs[i]);
        }
    }

    function countBit(uint8 data) private pure returns (uint8 totalBits){
        totalBits = 0;
        while (data > 0)
        {
            totalBits += data & 1;
            data >>= 1;
        }
        return totalBits;
    }

    function addCandidate (uint _identifyID) private {
        candidates[candidatesCount] = Candidate(uint8(1) << candidatesCount, _identifyID, 0);
        candidatesCount ++;
    }

    function vote (uint8 _candidateid, address sender) private {
        // require that they haven&#39;t voted before
        //require(!voters[sender]);

        // record that voter has voted
        voters[sender] = true;

        // update candidate vote Count
        candidates[_candidateid].voteCount ++;

        // trigger voted event
        emit votedEvent(candidates[_candidateid].id);
    }
    // add onlyValidSenderIsToken
    function receiveApproval(address _from, uint8 votes
    )
    onlyValidSenderIsAcceptToken(msg.sender)
    onlyAccept5Vote(votes)
    public {
        require(StartDate <= now && now <= EndDate);
        require(SELT.burn( 1 ));
        for(uint8 i = 0 ; i < candidatesCount ; i++){
            if((votes & candidates[i].id) != 0){
                vote( i, _from );
            }
        }
        TotalVote += 1;
        emit SomeOneVoted(_from, this, votes);
    }
    function end()
    onlyValidOwner(msg.sender)
    public{
        require( now > EndDate);
        for(uint8 i=0; i< candidatesCount; i++){
            emit ElectionResult(candidates[i].identifyID, candidates[i].voteCount); // calling the event to display result in UI passing results
        }
    }
}