/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
/**
 * @file Ballot.sol
 * @author Evgeny Usorov
 * @date created 26.03.2021
 */

pragma solidity ^0.8.3;

contract Ballot {

    address public ballotOfficialAddress;      

    Vote[] public votesArray;
    
    struct Vote {
        address voter;
        uint8 choice;
    }
    
    enum State { Created, Voting, Ended }
	State public state;
	
	//creates a new ballot contract
	constructor() {
        ballotOfficialAddress = msg.sender;

        state = State.Created;
    }
    

	modifier onlyOfficial() {
		require(msg.sender ==ballotOfficialAddress);
		_;
	}

	modifier inState(State _state) {
		require(state == _state);
		_;
	}

    event voteStarted();
    event voteEnded();
    event voteDone(address voter);
    
   
    //declare voting starts now
    function startVote()
        public
        inState(State.Created)
        onlyOfficial
    {
        state = State.Voting;     
        emit voteStarted();
    }

    //voters vote by indicating their choice
    function doVote(uint8 _choice)
        public
        inState(State.Voting)
    {

        votesArray.push(Vote({voter: msg.sender, choice: _choice}));
        
        emit voteDone(msg.sender);
    }
    
    //end votes
    function endVote()
        public
        inState(State.Voting)
        onlyOfficial
    {
        state = State.Ended;
        emit voteEnded();
    }

    function getTotal() public view returns (uint){
        
        return votesArray.length;
    }
    
    function getTotalArray() public view returns (Vote[] memory){

        return votesArray;
    }

}