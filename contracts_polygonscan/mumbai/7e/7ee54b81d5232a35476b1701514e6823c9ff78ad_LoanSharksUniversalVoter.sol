/**
 *Submitted for verification at polygonscan.com on 2021-12-24
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
        int start_voting;
        int end_voting;
        mapping(address => uint ) voted;
    }
    
    //Public Voting Session Object (for viewing)
    struct PublicVotingSessionViewer{
        string name;
        uint num_voting_items;
        string[] vote_options;
        int start_voting;
        int end_voting;
    }

    //Validator creates voting sessions
    address _validator;

    //Store voting session states
    uint next_voting_session = 0;
    mapping(uint => VotingSession) voting_sessions;

    constructor(){
        _validator = msg.sender;
    }
    //Helper function
    function toString(uint256 _i) internal pure returns (string memory str){
        if (_i == 0)
        {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    //Create voting sessions (only validator)
    function create_voting_session(string memory u_name, uint u_num_voting_items, string[] memory u_vote_options, int u_end_voting_seconds) public onlyValidator{
        VotingSession storage vs = voting_sessions[next_voting_session];
        vs.name = u_name;
        vs.num_voting_items = u_num_voting_items;
        vs.vote_options = u_vote_options;
        //Initialze voting array
        for(uint i=0; i < u_num_voting_items; i++){
            vs.votes.push(0);
        }
        vs.start_voting = int(block.timestamp);
        vs.end_voting = int(block.timestamp) + u_end_voting_seconds;
        next_voting_session++;
    }

    //Get all voting sessions
    function get_all_voting_sessions() public view returns(PublicVotingSessionViewer[] memory){
        require(next_voting_session > 0, "No Voting Sessions initialized.");
        PublicVotingSessionViewer[] memory t_out = new PublicVotingSessionViewer[](next_voting_session-1);
        for(uint i = 0; i < next_voting_session; i++){
            t_out[i] = PublicVotingSessionViewer(
                voting_sessions[i].name,
                voting_sessions[i].num_voting_items,
                voting_sessions[i].vote_options,
                voting_sessions[i].start_voting,
                voting_sessions[i].end_voting
            );
        }
        return t_out;
    }

    //Vote for an index given
    function vote(uint voting_session_index, uint voting_index) public {
        require(0 == voting_sessions[voting_session_index].voted[msg.sender], "Address has already voted.");
        voting_sessions[voting_session_index].votes[voting_index] += 1;
        voting_sessions[voting_session_index].voted[msg.sender] = 1;
    }

    modifier onlyValidator() {
        require(_validator == msg.sender);
        _;
    }

}