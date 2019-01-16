pragma solidity ^0.4.24;
contract Voting {

    uint election_id;
    
    struct Voter {
        string name;
        string email;
        string phone_no;
        bool voted;  // if true, that person already voted
    }

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;
    
    struct Candidate {
        string name;
        uint voteCount;
    }
    
    struct ElectionSerial {
        uint id;
        mapping(uint => Election) elections;
        uint[] all_elections;
    }
    
    // Election info
    struct Election {
        uint id;
        string election_title;
        mapping(address => Candidate) candidates;
        mapping(address => Voter) voters;
        address[] all_candidates;
    }
    
    mapping(address => ElectionSerial) public election_serials;

    // Index of elections of organiser
    function getAllElectionsOfOrganiser(address owner_address) public view returns(uint[]) {
        return election_serials[owner_address].all_elections;
    }
    
    function createElection(string _election_title) public returns (uint) {
        election_id += 1;
        election_serials[msg.sender].elections[election_id].id = election_id;
        election_serials[msg.sender].elections[election_id].election_title = _election_title;
        election_serials[msg.sender].all_elections.push(election_id);
        return (election_id);
    }
    
    function getElection(address _organiser_address, uint _id) public view returns (uint, string, address[]) {
        return (election_serials[_organiser_address].elections[_id].id,
            election_serials[_organiser_address].elections[_id].election_title, 
            election_serials[_organiser_address].elections[_id].all_candidates);
    }
    
    // Set by organiser
    function createCandidateOnElection(uint _election_id, address _candidate_address, string _name) public {
        election_serials[msg.sender].elections[_election_id].candidates[_candidate_address].name = _name;
        election_serials[msg.sender].elections[_election_id].all_candidates.push(_candidate_address);
    }
    
    function getCandidateDetailOnElection(address _organiser_address, uint _election_id, address _candidate_address) public view returns (string, uint){
        return (election_serials[_organiser_address].elections[_election_id].candidates[_candidate_address].name,
            election_serials[_organiser_address].elections[_election_id].candidates[_candidate_address].voteCount);
    }
    
    function createVoterOnElection(uint _election_id, address _voter_address, string _name, string _email, string _phone_no) public {
        election_serials[msg.sender].elections[_election_id].voters[_voter_address].name = _name;
        election_serials[msg.sender].elections[_election_id].voters[_voter_address].email = _email;
        election_serials[msg.sender].elections[_election_id].voters[_voter_address].phone_no = _phone_no;
    }
    
    function getVoterOnElection(address _organiser_address, uint _election_id, address _voter_address) public view returns (string, string, string) {
        return (election_serials[_organiser_address].elections[_election_id].voters[_voter_address].name,
            election_serials[_organiser_address].elections[_election_id].voters[_voter_address].email,
            election_serials[_organiser_address].elections[_election_id].voters[_voter_address].phone_no);
    }
    
    function voteOnElection(address _organiser_address, address _candidate_address, uint _election_id) public {
    	require(election_serials[_organiser_address].elections[_election_id].voters[msg.sender].voted == false);
    	
        election_serials[_organiser_address].elections[_election_id].candidates[_candidate_address].voteCount += 1;
        election_serials[_organiser_address].elections[_election_id].voters[msg.sender].voted = true;
    }
    
}