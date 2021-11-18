// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract evs{
    string[] available_candidates;
    bool flag_IsVotingInProgress = false;
    address owner_address;
    uint256[] casted_votes;
    address[] voters;
    string voting_summary;
    uint256[] vote_count;
    string  result = "RESULT    :   ";
    string winner;

    constructor() public{
        owner_address = msg.sender;
    }
    modifier only_Owner(){
        require(msg.sender == owner_address, "This function is only available for owner");
        _;

    }

    function change_owner(address new_owner) only_Owner public{
        owner_address = new_owner;
    }

    function return_votingStatus() public view returns(bool){
        return flag_IsVotingInProgress;
    }

    function start_voting() only_Owner public{
        flag_IsVotingInProgress = true;

        
        

    }

   function cast_vote(uint256 candidate_id) public{
       require(flag_IsVotingInProgress == true , "Voting hasn't stated yet!");
        bool allow_voting = false;
    
    if (voters.length> 0){
       for (uint256 i = 0 ; i < voters.length ; i++){
            if(voters[i] == msg.sender){
                allow_voting = false;
            }
            else{
                allow_voting = true;
            }
       }
        
    
       
       require(allow_voting == true , "You have already casted the vote. You can only cast vote one time!");
        
    }
       
       voters.push(msg.sender);
        casted_votes.push(candidate_id);
   }
 
    function add_candidates(string[] memory arr) only_Owner public{
        require(flag_IsVotingInProgress == false , "You cannot add a new candidate during the voting process!");
        available_candidates = arr;
    }
    function return_Candidates() public view returns (string[] memory){
        return available_candidates;
    }
   
    
   function uint2str(uint _i) internal pure returns (string memory _uintAsString) { //converts the uint into string
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    
    
    function concate(string memory candidate,uint256  votes) internal view returns(string memory)
    {
    return string(abi.encodePacked(result," ",candidate," : ",uint2str(votes),"\n"));
    }
    
 
    function end_voting() only_Owner public{
        flag_IsVotingInProgress = false;

        for (uint256 x = 0; x<available_candidates.length ; x++){
            vote_count.push(0);
        }
        
        for (uint256 i = 0 ; i < casted_votes.length ; i ++){
            for (uint256 j = 0 ; j<available_candidates.length ; j++){
                if (casted_votes[i] == j+1){
                    vote_count[j] +=1;
                }
            }
        }

        
        for (uint256 i = 0 ; i < available_candidates.length ; i ++){
            result = concate(available_candidates[i],vote_count[i]);
            
        }

        
        
        
    }
    
    function return_stats() public view returns(string memory){
        require(flag_IsVotingInProgress == false,"Voting in progress!");
        return result;
    }
    
    function find_winner() only_Owner public {
        require(flag_IsVotingInProgress == false, "Voting in progress!");
        for(uint256 i = 1;i < vote_count.length; ++i)
    {
       if(vote_count[0] < vote_count[i])
           vote_count[0] = vote_count[i];
    }
    uint256 position;
    uint256 largestnum;
    largestnum = vote_count[0];
    for(uint256 i =1; i<vote_count.length; i++) {
      if(vote_count[i]>largestnum) {
         largestnum = vote_count[i];
         position = i;
      }
      
    
    }
    winner = available_candidates[position];

    
}

function announce_winner() public view returns (string memory){
    require (flag_IsVotingInProgress == false,"Voting is in progress!");
    return winner;
}
    
}