/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract TopTrumpsGame {

    address payable owner;
    uint256 totalCards;
    mapping (address => bool) approvedServers;
    mapping (address => DeckData) challenges;

    address[] pendingChallenges;
    MatchData[] pendingMatches;
    MatchHistory[] matchHistory;

    struct MatchHistory {
        address creator;
        address player;
        address winner;
        string matchData;
    }

    struct MatchData {
        address creator;
        DeckData creatorDeck;
        address player;
        DeckData playerDeck;
        uint256 totalBounty;
    }

    struct DeckData {
        uint16[5] cards;
        uint8[5] stats;
        uint256 challengeAmount;
        bool activeChallenge;
    }

    constructor(uint256 _totalCards) {
        owner = payable(msg.sender);
        totalCards = _totalCards;
        approvedServers[msg.sender] = true;
    }

    function processMatch(
        uint256 index,
        bool creatorWon,
        string memory _matchDetails
        ) public {
        require (approvedServers[msg.sender] == true, "Sender not approved");
        require (index < pendingMatches.length, "Invalid index");
        MatchHistory memory newMatch;
        if (creatorWon) {
            newMatch.winner = pendingMatches[index].creator;
        } else {
            newMatch.winner = pendingMatches[index].player;
        }
        newMatch.creator = pendingMatches[index].creator;
        newMatch.player = pendingMatches[index].player;
        newMatch.matchData = _matchDetails;
        matchHistory.push(newMatch);
        removePendingMatch(index);
    }

    function getMatchHistoryCount() public view returns (uint256) {
        return matchHistory.length;
    }

    function getMatchHistoryByIndex(uint256 index) public view returns (MatchHistory memory) {
		require (index < matchHistory.length, "Out of bounds");
        return matchHistory[index];
    }

    function registerServer (
        address _serverAddress
    ) external {
        require(msg.sender == owner);
        require(_serverAddress != address(0));
        approvedServers[_serverAddress] = true;
    }

    function getChallenges () public view returns(address[] memory) {
        return pendingChallenges;
    }

    function getChallenge(address challenger) public view returns (DeckData memory) {
        require (challenges[challenger].activeChallenge == true, "No challenger at address");
        return challenges[challenger];
    }

    function registerChallenge (
        uint16[5] memory _cards,
        uint8[5] memory _stats
    ) public payable {
        require (challenges[msg.sender].activeChallenge == false, "Challenge already registered");
        require (msg.value > 0, "Require bounty greater than 0");
        require (_cards.length == totalCards, "Invalid number of cards");
        require (_stats.length == totalCards, "Invalid number of stats");
        challenges[msg.sender].cards = _cards;
        challenges[msg.sender].stats = _stats;
        challenges[msg.sender].activeChallenge = true;
        challenges[msg.sender].challengeAmount = msg.value;
        pendingChallenges.push(msg.sender);
    }

    function acceptChallenge (
        uint16[5] memory _cards,
        uint8[5] memory _stats,
        address _challengeAddress
    ) public payable {
        require (challenges[msg.sender].activeChallenge == false, "Challenge already registered");
        require (challenges[_challengeAddress].activeChallenge == true, "No challenger at address");
        bool pendingChallenge;
        for (uint256 i = 0; i < pendingChallenges.length; i++) {
            if (pendingChallenges[i] == _challengeAddress) {
                pendingChallenge = true;
                break;
            }
        }
        require (pendingChallenge == true, "No pending challenge at address");
        require (challenges[_challengeAddress].challengeAmount == msg.value, "Require bounty equal to challenge amount");
        require (_cards.length == totalCards, "Invalid number of cards");
        require (_stats.length == totalCards, "Invalid number of stats");

        MatchData memory newMatch;
        newMatch.creator = _challengeAddress;
        newMatch.creatorDeck = challenges[_challengeAddress];
        newMatch.player = msg.sender;
        DeckData memory deckData;
        deckData.cards = _cards;
        deckData.stats = _stats;
        newMatch.playerDeck = deckData;
        newMatch.totalBounty = challenges[_challengeAddress].challengeAmount + msg.value;
        pendingMatches.push(newMatch);

        delete challenges[_challengeAddress];
        removePendingChallenge(_challengeAddress);
    }

    function removeChallenge() public {
        require (challenges[msg.sender].activeChallenge == true, "No pending challenge");
        delete challenges[msg.sender];
        removePendingChallenge(msg.sender);
    }

    function removePendingChallenge(address _challenger) private { 
        for (uint256 i = 0; i < pendingChallenges.length; i++) {
            if (pendingChallenges[i] == _challenger) {
                pendingChallenges[i] = pendingChallenges[pendingChallenges.length - 1];
                pendingChallenges.pop();
                break;
            }
        }
    }

    function removePendingMatch(uint256 index) private { 
            pendingMatches[index] = pendingMatches[pendingMatches.length - 1];
            pendingMatches.pop();
    }
}