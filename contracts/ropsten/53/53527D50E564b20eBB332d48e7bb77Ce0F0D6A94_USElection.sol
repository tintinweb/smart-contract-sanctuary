// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";

contract USElection is Ownable{
    uint8 public constant BIDEN = 1;
    uint8 public constant TRUMP = 2;
    
    bool public electionEnded;
    
    event LogStateResult(uint winner, uint8 stateSeats, string state);
    event LogElectionEnded(uint winner);
    
    modifier onlyActiveElection() {
        require(!electionEnded, "The election has ended already!");
        _;
    }
    
    mapping(uint8 => uint8) public seats;
    mapping(string => bool) public resultSubmitted;
    
    struct StateResult {
        string name;
        uint votesBiden;
        uint votesTrump;
        uint8 stateSeats;
    }
    
    
    
    function submitStateResult(StateResult calldata result) public onlyOwner onlyActiveElection{
        require(result.stateSeats > 0, "States must have at least 1 seat!");
        require(result.votesBiden != result.votesTrump, "There cannot be a tie");
        require(!resultSubmitted[result.name], "This state result was already submitted!");
        uint8 winner;
        if(result.votesBiden > result.votesTrump){
            winner = BIDEN;
        }
        else{
            winner = TRUMP;
        }
        
        seats[winner] += result.stateSeats;
        resultSubmitted[result.name] = true;
        
        emit LogStateResult(winner, result.stateSeats, result.name);
    }
    function currentLeader() public view returns(uint8){
        if(seats[BIDEN] > seats[TRUMP]) {
            return BIDEN;
        }
        if(seats[TRUMP] > seats[BIDEN]) {
            return TRUMP;
        }
        return 0;
    }
    function endElecteion() public onlyOwner onlyActiveElection{
        electionEnded = true;
        emit LogElectionEnded(currentLeader());
        
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Not invoked by the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}