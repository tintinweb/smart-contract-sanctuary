/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// SPDX-License-Identifier: GPL-3.0-or-later
/**
 * @file Ballot.sol
 * 
 * Only owner can start the vote: startVote() for specific 
 * token smart contract adress.
 * The blocknumber of previous block will be stored.
 * 
 * Every user can vote: doVote()
 * It is not possible to vote twice.
 * 
 * Only owner can end the vote: endVote() 
 * 
 * The votes will be calculated depending on the balance 
 * of tokens. With function getTotalBalancePerProposal we 
 * get all balances per proposal.
 * 
 * To prevent voting from different accounts, we calculate balance 
 * at the specific blocknumber. This will be a separate script.
 * It is than possible to compare an see who is cheating :) 
 * 
 * @author Evgeny Usorov
 * @date created 26.03.2021
 */

pragma solidity ^0.8.3;

contract Ballot {

    address public tokenSmartContractAddress;
    address public ballotOfficialAddress;      
    
    // get block number with hash of previous block
    uint public blockNumberPrevious;

    // all proposals as 0 = NOVOTE, 1 = proposal 1 , 2, proposal 2
    string[] public proposalsArray;
    
    // save all votes
    mapping(address => uint8) public votes;
    
    // save all voters adress to get balance later
    address[] public votersAdresses;
    
    // save balances 
    mapping(address => uint) public votersBalances;
  
    enum State { Created, Voting, Ended }
	State public state;
	
	// creates a new ballot contract
	constructor() {
        ballotOfficialAddress = msg.sender;
        state = State.Created;
        proposalsArray.push('NOVOTE'); // init 0 =no vote
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
	
	// allow only values 1 .. number of proposals
    modifier allowedValues(uint8 choice) {
		require(choice > 0 && choice < proposalsArray.length);
		_;
	}
	
	// emit events for start at blockNumberPrevious
    event voteStarted(uint blockNumberPrevious);
    event voteEnded();
    event voteDone(address voter, uint8 choice);
    
   
    function addProposal(string memory proposalName)
        public
        inState(State.Created) 
        onlyOfficial //only owner can add proposals
    {
        
        proposalsArray.push(proposalName);
    }
    
    // declare voting starts now
    function startVote(address TokenAddress)
        public
        inState(State.Created) 
        onlyOfficial //only owner can start vote
    {
        state = State.Voting;     
        blockNumberPrevious = block.number-1;
        tokenSmartContractAddress = TokenAddress;
        emit voteStarted(blockNumberPrevious);
    }

    // voters vote by indicating their choice
    function doVote(uint8 choice)
        public
        inState(State.Voting)
        allowedValues(choice)
        // notAlreadyVoted() //vote can by only once
    {

        votes[msg.sender] = choice;
        votersAdresses.push(msg.sender);
        uint tokenBalance = ERC20Interface(tokenSmartContractAddress).balanceOf(msg.sender);
        votersBalances[msg.sender] = tokenBalance;
        
        emit voteDone(msg.sender, choice);
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
    

    // get balances for every proposal
    // this don't prevent to vote twice from different wallets
    // to prevent this we have to run script to get balances
    // of the addresses at specific blocknumber. 
    // Which is now not possible within solidity
    function getTotalBalancePerProposal() public 
    // inState(State.Ended) // results only after vote ended
    view 
    returns (uint[] memory){
    
        // 0 is included 
        uint[] memory totalVotesArray = new uint[](proposalsArray.length);
    
        for (uint i=0; i<votersAdresses.length; i++) {
            uint8 choice = votes[votersAdresses[i]];
            if (choice > 0 ){
                uint balance = votersBalances[votersAdresses[i]];
            
                totalVotesArray[choice] += balance;
            }
        }

        return totalVotesArray;
    }
}


// interface for getting balance of the token holders
abstract contract  ERC20Interface {
    function balanceOf(address whom) view virtual public returns (uint);
}