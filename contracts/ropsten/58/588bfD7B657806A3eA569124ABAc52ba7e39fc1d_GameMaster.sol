/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract GameMaster {

    constructor() {
        owner[msg.sender] = true; 
    }

    modifier onlyOwner {
        require(owner[msg.sender] == true);
        _;
    }

    modifier onlyProposer {
        require(player[msg.sender].isProposer == true);
        _;
    }

    modifier onlyRegistered {
        require(player[msg.sender].isRegistered == true);
        _;
    }

    struct Game {
        uint32 gameId;
        uint8 roundId;
        uint8 playerCount;
        Proposal proposalVote;
        uint8[] currentProposal; 
        bool isGameActive;
        bool isProposalActive;
        bool isVotingActive; 
    }

    struct Proposal {
        uint8 nVotesCast;
        uint8 nAccept;
        uint8 nReject;
    }

    struct Player {
        address playerAddress;
        uint payout;
        bool isRegistered;
        bool isProposer;
        bool hasVoted;
    }

    mapping(address => bool) owner;
    mapping(uint => Game) game;

    mapping(address => Player) player;
    mapping(uint => address) playerId;

    uint proposerId = 0; // placeholder for chainlink VRF
    uint maxPlayers = 4;
    uint i = 0;
    uint j = 0;

    mapping(uint => bool) private isGameActive;

    // function updateTimestamp() public {
    //     currentGame.lastUpdated = block.timestamp;
    // }

    function buyIn() external payable {
        require(player[msg.sender].isRegistered == false);
        require(isGameActive[game[i].gameId] == false);
        require(game[i].playerCount <= maxPlayers - 1);
        require(msg.value == 1 ether);

        player[msg.sender].isRegistered = true;
        player[msg.sender].playerAddress = msg.sender;
        playerId[game[i].playerCount] = msg.sender;

        game[i].playerCount += 1;

        if (game[i].playerCount >= maxPlayers) {
            initiateRound();
        }
    }

    function initiateRound() internal {
        game[i].isGameActive = true;
        selectProposer();
    }

    function selectProposer() internal {
        // First user for now, in future we will use chainlink VRF
        player[playerId[proposerId]].isProposer = true;
        game[i].isProposalActive = true;
    }

    function proposeDeal(uint8[] calldata _payout_distribution) 
        external 
        onlyProposer
    {
        require(game[i].isGameActive == true);
        require(game[i].isProposalActive == true);
        require(_payout_distribution.length == game[i].playerCount);

        game[i].currentProposal = _payout_distribution;

        for(uint c=0; c<=game[i].playerCount-1; c++) {
            player[playerId[c]].payout = _payout_distribution[c];
        }

        closeProposalPhase();
    }
    
    function closeProposalPhase() internal {
        game[i].isProposalActive = false;
        game[i].isVotingActive = true;
    }

    // _vote -> 0: false, 1: true
    function vote(bool _vote) external onlyRegistered {
        require(player[msg.sender].hasVoted == false);
        require(player[msg.sender].isProposer == false);
        
        player[msg.sender].hasVoted = true;

        if (_vote == true) {
            game[i].proposalVote.nAccept += 1;
        } else {
            game[i].proposalVote.nReject += 1;
        }

        game[i].proposalVote.nVotesCast += 1;

        if(game[i].proposalVote.nVotesCast >= game[i].playerCount-1) {
            determineVotingOutcome();
        }
    }

    function determineVotingOutcome() internal {
        if(game[i].proposalVote.nAccept > game[i].proposalVote.nReject) {
            distributeRewards();
        } else {
            removePlayer(proposerId);
            proposerId += 1;
            selectProposer();
            resetVoting();
        }
    }

    function resetVoting() internal {
        for (uint c=proposerId; c<game[i].playerCount+proposerId; c++) {
            player[playerId[c]].hasVoted = false;
        }

        game[i].proposalVote.nAccept = 0;
        game[i].proposalVote.nReject = 0;
        game[i].proposalVote.nVotesCast = 0;
    }

    function distributeRewards() internal {
        uint _amount;
        for(uint c=0; c<game[i].playerCount; c++) {
            _amount = player[playerId[c]].payout * 10 **18;
            payable(playerId[c]).transfer(_amount);
        }
    }

    function removePlayer(uint _playerId) internal {
        player[playerId[proposerId]].isProposer = false;
        player[playerId[_playerId]].isRegistered = false;
        player[playerId[_playerId]].payout = 0;
        game[i].playerCount -= 1;
    }

    function updateMaxPlayers(uint _amount) public onlyOwner {
        maxPlayers = _amount;
    }

    function currentProposer(address _address) public view returns(bool) {
        return player[_address].isProposer;
    }

    function checkActiveGame(uint _gameId) public view returns(bool) {
        return game[_gameId].isGameActive;
    }

    function countPlayers(uint _gameId) public view returns(uint) {
        return game[_gameId].playerCount;
    }

    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }

    function viewProposal(uint _gameId) public view returns(uint8 [] memory ) {
        return game[_gameId].currentProposal;
    }

    function showPlayerAtIndex(uint _playerId) public view returns(address) {
        return player[playerId[_playerId]].playerAddress;
    }
}