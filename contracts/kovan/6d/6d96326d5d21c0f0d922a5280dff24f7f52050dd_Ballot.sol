/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later
/**
 * @file Ballot.sol
 * 
 * only owner can start the vote: startVote()
 * the blocknumber of previous block will be stored.
 * 
 * every user can vote: doVote()
 * it is not possible to vote twice.
 * 
 * only owner can end the vote: endVote() 
 * 
 * the votes will be calculated depending on the balance 
 * of tokens at the specific blocknumber. This will be a separate script.
 * 
 * @author Evgeny Usorov
 * @date created 26.03.2021
 */

pragma solidity ^0.8.3;

contract Ballot {

    address public ballotOfficialAddress;      
    
    // get block number with hash of previous block
    uint public blockNumberPrevious;

    // all proposals as 0 = NOVOTE, 1 = CAPITALX_FUND, 2 = NFTSTREAMZ, 3 = DEFI_NFT
    enum Proposals { NOVOTE, CAPITALX_FUND, NFTSTREAMZ, DEFI_NFT }
    
    // save all votes
    mapping(address => uint8) public votes;
    
    // save all voters adress to get balance later
    address[] public votersAdresses;
  
    enum State { Created, Voting, Ended }
	State public state;
	
	// creates a new ballot contract
	constructor() {
        ballotOfficialAddress = msg.sender;
        state = State.Created;
    }
    
    // only owner can do something
	modifier onlyOfficial() {
		require(msg.sender == ballotOfficialAddress);
		_;
	}

    // only access function if in state
    // prevents start voting againg later
    // prevents voting after the end of voting
	modifier inState(State _state) {
		require(state == _state);
		_;
	}

    // allow only to vote once
    modifier notAlreadyVoted() {
		require(votes[msg.sender]==0);
		_;
	}
	
	// emit events for start at blockNumberPrevious
    event voteStarted(uint blockNumberPrevious);
    event voteEnded();
    event voteDone(address voter, Proposals choice);
    
   
    // declare voting starts now
    function startVote()
        public
        inState(State.Created) 
        onlyOfficial //only owner can start vote
    {
        state = State.Voting;     
        blockNumberPrevious = block.number-1;
        emit voteStarted(blockNumberPrevious);
    }

    // voters vote by indicating their choice
    function doVote(Proposals _choice)
        public
        inState(State.Voting)
        notAlreadyVoted() //vote can by only once
    {

        votes[msg.sender] = uint8(_choice);
        votersAdresses.push(msg.sender);
        
        emit voteDone(msg.sender, _choice);
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

    function getTotalCount() public view returns (uint){
        
        return votersAdresses.length;
    }
    
    function getTotalAdresses() public view returns (address[] memory){

        return votersAdresses;
    }

}