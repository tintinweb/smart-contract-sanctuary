/**
 *Submitted for verification at Etherscan.io on 2021-12-11
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
        // uint32 gameId;
        uint8 roundId;
        uint8 playerCount;
        uint8 totalRegistered;
        uint8[] currentProposal; 
        Proposal proposalVote;
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
        uint payout;
        bool isRegistered;
        bool isProposer;
        bool hasVoted;
    }

    mapping(address => bool) owner;
    Game game;

    mapping(address => Player) player;
    address[] playerAddresses;

    uint proposerId = 0; // placeholder for chainlink VRF
    uint maxPlayers = 3;

    function buyIn() external payable {
        require(player[msg.sender].isRegistered == false);
        require(game.isGameActive == false);
        require(game.playerCount <= maxPlayers - 1);
        require(msg.value == 0.01 ether);

        registerPlayer(msg.sender);

        if (game.playerCount >= maxPlayers) {
            initiateRound();
        }
    }

    function registerPlayer(address _address) internal {
        player[_address].isRegistered = true;
        playerAddresses.push(_address);
        // playerAddresses[game.playerCount] = _address;

        game.playerCount += 1;
    }

    function initiateRound() internal {
        game.isGameActive = true;
        selectProposer();
        game.totalRegistered = game.playerCount;
    }

    function selectProposer() internal {
        // First user for now, in future we will use chainlink VRF
        player[playerAddresses[proposerId]].isProposer = true;
        game.isProposalActive = true;
    }

    function proposeDeal(uint8[] calldata _payout_distribution) 
        external 
        onlyProposer
    {
        require(game.isGameActive == true);
        require(game.isProposalActive == true);
        require(_payout_distribution.length == game.playerCount);

        game.currentProposal = _payout_distribution;

        for(uint c=game.totalRegistered-game.playerCount; c<game.totalRegistered; c++) {
            player[playerAddresses[c]].payout = _payout_distribution[c-(game.totalRegistered-game.playerCount)];
        }

        closeProposalPhase();
    }

    function closeProposalPhase() internal {
        game.isProposalActive = false;
        game.isVotingActive = true;
    }

    // _vote -> 0: false, 1: true
    function vote(bool _vote) external onlyRegistered {
        require(player[msg.sender].hasVoted == false);
        require(player[msg.sender].isProposer == false);
        
        player[msg.sender].hasVoted = true;

        if (_vote == true) {
            game.proposalVote.nAccept += 1;
        } else {
            game.proposalVote.nReject += 1;
        }

        game.proposalVote.nVotesCast += 1;

        if(game.proposalVote.nVotesCast >= game.playerCount-1) {
            determineVotingOutcome();
        }
    }

    function determineVotingOutcome() internal {
        if(game.proposalVote.nAccept > game.proposalVote.nReject) {
            distributeRewards();
            terminateGame();
        } else {
            removePlayer(playerAddresses[proposerId]);
            proposerId += 1;
            selectProposer();
            resetVoting();
        }
    }

    function resetVoting() internal {
        for (uint c=proposerId; c<game.playerCount+proposerId; c++) {
            player[playerAddresses[c]].hasVoted = false;
        }

        game.proposalVote.nAccept = 0;
        game.proposalVote.nReject = 0;
        game.proposalVote.nVotesCast = 0;
    }

    function distributeRewards() internal {
        uint _amount;
        for(uint c=game.totalRegistered-game.playerCount; c<game.totalRegistered; c++) {
            _amount = player[playerAddresses[c]].payout * 10 **18;
            payable(playerAddresses[c]).transfer(_amount);
        }
    }

    function removePlayer(address _address) internal {
        player[_address].isProposer = false;
        player[_address].isRegistered = false;
        player[_address].payout = 0;
        game.playerCount -= 1;
        
    }

    function removeAllPlayers() internal {
        for(uint i=game.totalRegistered-game.playerCount;i<game.totalRegistered; i++) {
            removePlayer(playerAddresses[i]);
        }
        delete(playerAddresses);
    }

    function terminateGame() internal {
        resetVoting();
        removeAllPlayers();
        proposerId = 0;
        delete(game);
    }

    function updateMaxPlayers(uint _amount) public onlyOwner {
        maxPlayers = _amount;
    }

    function currentProposer(address _address) public view returns(bool) {
        return player[_address].isProposer;
    }

    function checkActiveGame() public view returns(bool) {
        return game.isGameActive;
    }

    function countPlayers() public view returns(uint) {
        return game.playerCount;
    }

    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }

    function viewProposal() public view returns(uint8 [] memory ) {
        return game.currentProposal;
    }

    function showPlayerAtIndex(uint _playerId) public view returns(address) {
        return playerAddresses[_playerId];
    }
}