/**
 *Submitted for verification at polygonscan.com on 2021-12-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract LoanSharksUniversalVoter{
    //Voting Session Object
    struct VotingSession{
        string name;
        uint num_voting_items;
        string[] vote_options;
        uint[] votes;
        uint start_voting;
        uint end_voting;
        mapping(address => uint) voted;
    }
    
    //Public Voting Session Object (for viewing)
    struct PublicVotingSessionViewer{
        string name;
        uint num_voting_items;
        string[] vote_options;
        uint[] votes;
        uint start_voting;
        uint end_voting;
        bool live;
    }

    //Validator creates voting sessions
    address _validator;

    //Store voting session states
    uint next_voting_session = 0;
    mapping(uint => VotingSession) voting_sessions;

    constructor(){
        _validator = msg.sender;
    }

    //Create voting sessions (only validator)
    function create_voting_session(string memory u_name, uint u_num_voting_items, string[] memory u_vote_options, uint u_end_voting_seconds) public onlyValidator{
        VotingSession storage vs = voting_sessions[next_voting_session];
        vs.name = u_name;
        vs.num_voting_items = u_num_voting_items;
        vs.vote_options = u_vote_options;
        //Initialze voting array
        for(uint i=0; i < u_num_voting_items; i++){
            vs.votes.push(0);
        }
        vs.start_voting = block.timestamp;
        vs.end_voting = block.timestamp + u_end_voting_seconds;
        next_voting_session++;
    }

    //Get most recent voting session index
    function get_recent_session_index() public view returns (uint){
        return next_voting_session - 1;
    }   

    //Determine if session is live
    function session_is_live(uint index) public view returns (bool){
        return (voting_sessions[index].end_voting > block.timestamp) ? true : false;
    }

    //Get the state of a voting session
    function get_voting_session_by_index(uint index) public view returns(PublicVotingSessionViewer memory){
        return PublicVotingSessionViewer(
            voting_sessions[index].name,
            voting_sessions[index].num_voting_items,
            voting_sessions[index].vote_options,
            voting_sessions[index].votes,
            voting_sessions[index].start_voting,
            voting_sessions[index].end_voting,
            session_is_live(index)
        );
    }
    
    //Make a vote given a voting session index and voting index correlating to that spcific voting session index
    function vote(uint voting_session_index, uint voting_index) public {
        require(session_is_live(voting_session_index), "Voting session has ended.");
        require(voting_sessions[voting_session_index].voted[msg.sender] == 0, "Address has already voted.");
        voting_sessions[voting_session_index].votes[voting_index] += 1;
        voting_sessions[voting_session_index].voted[msg.sender] = 1;
    }

    //Change Validator
    function change_validator(address new_validator) public onlyValidator{
        _validator = new_validator;
    }

    //Validator modifier for creating voting sessions
    modifier onlyValidator() {
        require(_validator == msg.sender);
        _;
    }
}