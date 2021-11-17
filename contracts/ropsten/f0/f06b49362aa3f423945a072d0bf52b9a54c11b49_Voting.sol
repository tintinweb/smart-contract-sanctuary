/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Voting {
    /* Contestant struct */
    struct Contenstant {
        address _address;
        uint256 _votesCasted;
    }

    /* Mapping contestant address -> contestant struct */
    mapping (address => Contenstant) private contestantVotes;
    
    /* Mapping voter -> contestant */
    mapping (address => address) private votesMapping;
    
    /* List of all the contestant addresses */
    address[] public contestants;

    /**
     * Register a contestant
     *          - register contestant by it's address
     */
    function register() public {
        Contenstant memory contenstantVotes = contestantVotes[msg.sender];
        
        require(
            contenstantVotes._address == address(0), 
            "Contestant already present!"
        );
        
        Contenstant memory contenstantToBeAdded = Contenstant({ _address: msg.sender, _votesCasted: 0 });
        contestantVotes[msg.sender] = contenstantToBeAdded;
        contestants.push(msg.sender);
    }
    
    /**
     * Cast votes to contestants
     * 
     * @param _contestant - address of the contestant
     */
    function castVote(address _contestant) public {
        require(
            _contestant != address(0),
            "Invalid contestant address"
        );
        
        Contenstant memory contenstantVotesObj = contestantVotes[_contestant];
        
        require(
            contenstantVotesObj._address != address(0),
            "Invalid contestant"
        );
        
        require(
            contenstantVotesObj._address != msg.sender,
            "Cannot cast vote to self"
        );
        
        require(
            votesMapping[msg.sender] == address(0),
            "Vote already casted"
        );
        
        votesMapping[msg.sender] = _contestant;
        contenstantVotesObj._votesCasted = contenstantVotesObj._votesCasted + 1;
        contestantVotes[_contestant] = contenstantVotesObj;
    }
    
    /**
     * Get the winner
     *
     * @return winning contestant address
     */
    function winner() public view returns (address) {
        uint256 maxVotes = 0;
        uint256 totalWinners = 0;
        
        if (contestants.length == 0) {
            return address(0);
        }else if (contestants.length == 1) {
            return contestants[0];
        }

        for (uint256 index = 0; index < contestants.length; index ++) {
            address contestantAddress = contestants[index];
            Contenstant memory contestantObj = contestantVotes[contestantAddress];
            if (contestantObj._votesCasted > maxVotes) {
                maxVotes = contestantObj._votesCasted;
            }
        }
        
        for (uint256 index = 0; index < contestants.length; index ++) {
            address contestantAddress = contestants[index];
            Contenstant memory contestantObj = contestantVotes[contestantAddress];
            if (contestantObj._votesCasted == maxVotes) {
                totalWinners += 1;
            }
        }
        
        return getWinner(maxVotes, totalWinners);
    }
    
    /**
     * Get winner util function
     *
     * @param _maxVotes - max no of votes of winner
     * @param _totalWinners - no of candidates received max no of votes
     */
    function getWinner(uint256 _maxVotes, uint256 _totalWinners) private view returns (address) {
        address winner_;

        address[] memory winnerCandidateAddresses = new address[](_totalWinners);
        uint256 counter = 0;
        for (uint256 index = 0; index < contestants.length; index ++) {
            address contestantAddress = contestants[index];
            Contenstant memory contestantObj = contestantVotes[contestantAddress];
            if (contestantObj._votesCasted == _maxVotes) {
                winnerCandidateAddresses[counter] = contestantObj._address;
                counter += 1;
            }
        }
        
        if (winnerCandidateAddresses.length > 1) {
            // Choose random
            uint256 randomNumber = getRandomNumber(_totalWinners);

            winner_ = winnerCandidateAddresses[randomNumber];
        } else {
            winner_ = winnerCandidateAddresses[0];
        }
        delete winnerCandidateAddresses;

        return winner_;  
    }
    
    
    /**
     * Remove casted vote
     *
     * @param _contestant - address of the contestant
     */
    function removeVote(address _contestant) public {
        require (
            _contestant != address(0),
            "Invalid contestant address"
        );

        address castedVoteToContestant = votesMapping[msg.sender];
        
        require (
            castedVoteToContestant == _contestant,
            "Invalid vote to remove"
        );
        
        Contenstant memory contestantObj = contestantVotes[_contestant];
        require (
            contestantObj._address != address(0),
            "Invalid contestant address"
        );
        
        require (
            contestantObj._votesCasted >= 1,
            "Cannot remove vote. Something went wrong"
        );
        
        votesMapping[msg.sender] = address(0);
        contestantObj._votesCasted = contestantObj._votesCasted - 1;
        contestantVotes[_contestant] = contestantObj;
    }
    
    /**
     * Get random number between [0 - no of candidates considered for winning]
     * 
     * @param _totalWinners - no of candidates with same max votes
     */
    function getRandomNumber(uint256 _totalWinners) private view returns (uint256) {
        return uint256(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp, 
                        block.difficulty
                    )
                )
            ) 
            % _totalWinners
        );
    }
}