/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity >=0.6.0 <0.9.0;

/*
 * Have you ever been on the TU Campus?
 * Everyone is invited to vote, 
 * but only final BLKCHN '21 participants' votes will be counted at the end.
 * => Please let us know your account
 *
 * SPDX-License-Identifier: Unlicense
 * https://unlicense.org/
 */
contract TuCampusVoting {
    struct Vote {
        bool hasVoted;
        
        bool isParticipant;
        bool hasBeenOnTuCampus;
    }
    
    mapping(address => Vote) public votes;
    mapping(address => bool) public participants; // eligible accounts
    address[] public voters; // all voters, no matter if eligible or not
    
    address payable public owner; // contract owner
    
    // Called only once during deployment
    constructor() {
        // Save contract owner address during deployment
        owner = payable(msg.sender);
    }

    // Reject coin transfers (if possible)
    fallback () external {
        revert();
    }
    
    // Save vote if not voted before
    function vote(bool _iHaveBeenOnTuCampusBefore) public returns (bool _success) {
        require(votes[msg.sender].hasVoted == false, "You can only vote once.");
        
        // save voter's address
        voters.push(msg.sender);
        
        // save voter's vote
        votes[msg.sender] = Vote(true, participants[msg.sender], _iHaveBeenOnTuCampusBefore);
        
        return true;
    }
    
    // Returns number of yes votes (depening on whether they are supposed to be eligible or not)
    function getYesVotes(bool _onlyEligible) public view returns (uint256 _yes) {
        for(uint256 i = 0; i < voters.length; i++) {
            Vote memory voteProp = votes[voters[i]];
            
            if(voteProp.hasBeenOnTuCampus && (voteProp.isParticipant || !_onlyEligible))
                _yes += 1;
        }
    }
    
    // Returns number of no votes (depening on whether they are supposed to be eligible or not)
    function getNoVotes(bool _onlyEligible) public view returns (uint256 _no) {
        for(uint256 i = 0; i < voters.length; i++) {
            Vote memory voteProp = votes[voters[i]];
            
            if(!voteProp.hasBeenOnTuCampus && (voteProp.isParticipant || !_onlyEligible))
                _no += 1;
        }
    }
    
    // Count how many voters votes, depdending on whether they are eligible participants or not
    function getNumberOfVotes(bool _onlyEligible) public view returns (uint256 _voters) {
        if(_onlyEligible) {
            for(uint256 i = 0; i < voters.length; i++) {
                Vote memory voteProp = votes[voters[i]];
                
                if(voteProp.isParticipant)
                    _voters += 1;
            }
        } else {
            return voters.length;
        }
    }
    
    // For the owner only: Add a participants' account and set previous vote to eligible
    function addParticipant(address _participant) public returns (bool _success) {
        require(msg.sender == owner, "Only the contract owner can add participants.");
        
        if(!participants[_participant]) {
            participants[_participant] = true;
            
            // Make past votes eligible
            if(votes[_participant].hasVoted && !votes[_participant].isParticipant)
                votes[_participant].isParticipant = true;
                
            return true;
        } else {
            // Participant already added
            return false;
        }
    }
    
    // For the owner only: Add participants' accounts and set previous votes to eligible (bulk)
    function addParticipants(address[] memory _participants) public returns (bool _success) {
        for(uint256 i = 0; i < _participants.length; i++) {
            if(!addParticipant(_participants[i])) {
                revert(); // Add no participant, in case of an unexpected error
                // return false; // Unreachable due to revert()
            }
        }
        
        return true;
    }
        
    
    /*
     * This method destructs the contract, so it cannot be called anymore.
     * selfdestruct() transfers all coin balances to the specified address.
     * It also frees all storage variables (votes, participants, owner),
     * so future calls cannot read the voting's results anymore.
     * => It helps keeping the blockchain clean
     */
    function kill() public {
        require(msg.sender == owner, "Only the contract owner can kill the contract, sorry.");
        selfdestruct(owner);
    }
}