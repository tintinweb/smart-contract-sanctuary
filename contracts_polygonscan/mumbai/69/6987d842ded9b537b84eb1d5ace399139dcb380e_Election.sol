/**
 *Submitted for verification at polygonscan.com on 2022-01-06
*/

pragma solidity ^0.5.0;


contract Election {
   
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        address delegate; 
        uint256 weight; 
        uint256 voteTowards;
    }
   
    struct Candidate {
        uint256 ID;
        string name; 
        string proposal; 
    }
    mapping(uint => address) private voterID; 
    mapping(address => Voter) private voters; 
    mapping(uint256 => Candidate) private candidates; 
    mapping(uint256 => uint256) private voteCount; 

    address public admin; 

    enum State {CREATED, ONGOING, CONCLUDED}
   

    State  electionState; 
    string public description;
    uint256 public candidate_count; 
    uint256 public voter_count;
   
    modifier checkAdmin(address owner) {
        require(
            owner == admin,
            "Only the election admin has access to this function."
        );
        _;
    }

    //modifiers to check for the states of the election
    modifier checkIfCreated() {
        require(
            electionState == State.CREATED,
            "The election is either ongoing or has concluded."
        );
        _;
    }

    modifier checkIfOngoing() {
        require(
            electionState == State.ONGOING,
            "Election is not active or ongoing currently."
        );
        _;
    }

    modifier checkIfComplete() {
        require(electionState == State.CONCLUDED, "The election has not concluded yet.");
        _;
    }

    modifier checkNotComplete() {
        require(electionState != State.CONCLUDED, "The election has concluded.");
        _;
    }

    //modifier to check if a voter is a valid voter
    modifier checkIfVoterValid(address owner) {
        require(
            !voters[owner].hasVoted,
            "Voter has already voted."
        );
        require(
            voters[owner].weight > 0,
            "Voter has not been registered or already delegated their vote."
        );
        _;
    }

    //modifier to check if the candidate being voted for is a valid candidate
    modifier checkIfCandidateValid(uint256 _candidateId) {
        require(
            _candidateId > 0 && _candidateId <= candidate_count,
            "Invalid candidate."
        );
        _;
    }

    //modifier to check if the person is not an admin
    modifier checkNotAdmin(address owner) {
        require(
            owner != admin,
            "The election admin is not allowed to access this function."
        );
        _;
    }

    //modifier to check if the voter is not yet registered for the addVoter function
    modifier checkNotRegistered(address voter) {
        require(
            !voters[voter].hasVoted && voters[voter].weight == 0 && !voters[voter].isRegistered,
            "Voter has already been registered."
        );
        _;
    }

    //events to be logged into the blockchain
    event AddedAVoter(address voter);
    event VotedSuccessfully(uint256 candidateId);
    event DelegatedSuccessfully(address delegate);
    event ElectionStart(State election_state);
    event ElectionEnd(State election_state);
    event AddedACandidate(uint candidateID, string candidateName, string candidateProposal);

    // Initialization
    constructor(address owner, string memory desc) public {
        admin = owner;
        electionState = State.CREATED; // Setting Eection state to CREATED
        description = desc;
    }
 
    function checkState() public view returns (string memory state)
    {
        if(electionState == State.CREATED)
        return "CREATED";
        else if(electionState == State.ONGOING)
        return "ONGOING";
        else if(electionState == State.CONCLUDED)
        return "CONCLUDED";
    }
    // To Add a candidate
    // Only admin can add and
    // candidate can be added only before election starts
    function addCandidate(string memory _name, string memory _proposal, address owner)
        public
        checkAdmin(owner)
        checkIfCreated
    {
        candidate_count++;
        candidates[candidate_count].ID = candidate_count;
        candidates[candidate_count].name = _name;
        candidates[candidate_count].proposal = _proposal;
        voteCount[candidate_count] = 0;
        emit AddedACandidate(candidate_count, _name, _proposal);
    }

    // To add a voter
    // only admin can add
    // can add only before election starts
    // can add a voter only one time
    function addVoter(address _voter, address owner)
        public
        checkAdmin(owner)
        checkNotAdmin(_voter)
        checkIfCreated
        checkNotRegistered(_voter)
    {
        voter_count++;
        voterID[voter_count] = _voter;
        voters[_voter].weight = 1;
        voters[_voter].isRegistered = true;
        emit AddedAVoter(_voter);
    }

    // setting Election state to ONGOING
    // by admin
    function startElection(address owner) public checkAdmin(owner) checkIfCreated {
        electionState = State.ONGOING;
        emit ElectionStart(electionState);
    }

    // To display candidates
    function displayCandidate(uint256 _ID)
        public
        view
        returns (
            uint256 id,
            string memory name,
            string memory proposal
        )
    {
        return (
            candidates[_ID].ID,
            candidates[_ID].name,
            candidates[_ID].proposal
        );
    }

    //Show winner of election
    function showWinner()
        public
        view
        checkIfComplete
        returns (string memory name, uint256 id, uint256 votes)
    {
        uint256 max;
        uint256 maxIndex;
        string memory winner;
        for (uint256 i = 1; i <= candidate_count; i++) {
            if (voteCount[i] > max) {
                winner = candidates[i].name;
                maxIndex = i;
                max = voteCount[i];
            }
        }
        return (winner,maxIndex, max) ;
    }

    // to delegate the vote
    // only during election is going on
    // and by a voter who has not yet voted
    function delegateVote(address _delegate, address owner)
        public
        checkNotComplete
        checkIfVoterValid(owner)
        checkIfVoterValid(_delegate)
        checkNotAdmin(_delegate)
        checkNotAdmin(owner)
    {
        require(_delegate != owner, "Self delegation is not allowed.");
        address to = _delegate;
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // To prevent infinite loop
            if (to == owner) {
                revert();
            }
        }
        voters[owner].delegate = to;
        emit DelegatedSuccessfully(_delegate);
        voters[owner].hasVoted = true;
        
        if (voters[to].hasVoted) {
            // if delegate has already voted
            // voters vote is directly added to candidates vote count
            voteCount[voters[to].voteTowards] += voters[owner].weight;
            voters[owner].weight = 0;
        } else {
            voters[to].weight += voters[owner].weight;
            voters[owner].weight = 0;
        }
    }

    // to cast the vote
    function vote(uint256 _ID, address owner)
        public
        checkIfOngoing
        checkIfVoterValid(owner)
        checkIfCandidateValid(_ID)
    {
        voters[owner].hasVoted = true;
        voters[owner].voteTowards = _ID;
        voteCount[_ID] += voters[owner].weight;
        voters[owner].weight = 0;
        emit VotedSuccessfully(_ID);
    }

    // Setting Election state to STOP
    // by admin
    function endElection(address owner) public checkAdmin(owner) {
        electionState = State.CONCLUDED;
        emit ElectionEnd(electionState);
    }

    // to display result
    function showResults(uint256 _ID)
        public
        view
        checkIfComplete
        checkIfCandidateValid(_ID)
        returns (
            uint256 id,
            string memory name,
            uint256 count
        )
    {
        return (_ID, candidates[_ID].name, voteCount[_ID]);
    }

    function getVoter(uint ID, address owner)  public view checkAdmin(owner)
    returns (
        uint256 id,
        address voterAddress,
        address delegate,
        uint256 weight
    )
    {
        return (
            ID,
            voterID[ID],
            voters[voterID[ID]].delegate,
            voters[voterID[ID]].weight
        );
    }

    function voterProfile(address voterAddress) public view 
    returns (
        uint256 id,
        address delegate,
        uint256 weight,
        uint256 votedTowards,
        string memory name
        )
    {
         
        for(uint256 i = 1; i<= voter_count; i++)
        {
            if(voterAddress == voterID[i])
            {
                return (
                    i,
                    voters[voterID[i]].delegate,
                    voters[voterID[i]].weight,
                    voters[voterID[i]].voteTowards,
                    candidates[voters[voterID[i]].voteTowards].name
                    );
            }
        }
    }

}