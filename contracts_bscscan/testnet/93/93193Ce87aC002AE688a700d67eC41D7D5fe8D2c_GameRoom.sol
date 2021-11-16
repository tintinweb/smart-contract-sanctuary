/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract GameRoom {
    
    struct Player {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
        
        address[] tables;
    }
    
    struct GameSession {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
        
        uint playerLimit;
        bytes1 winCombinations;
        uint256 pricePerTable;
        uint256[] results;
    }
    
    address public chairperson;

    mapping(address => Player) public players;

    uint public currentGameSession;
    GameSession[] public gameSessions;
    
    
    constructor() {
        chairperson = msg.sender;
        players[chairperson].weight = 1;

        createGameSession("poop test", 100, 0xb5, 1000);
        
        currentGameSession = 0;
    }
    
    function createGameSession(bytes32 _name, uint _playerLimit, bytes1 _winCombinations, uint256 _pricePerTable) public {
        require(msg.sender == chairperson, "Only chairperson can create game sessions.");
        gameSessions.push(GameSession({
            name: _name,
            voteCount: 0,
            playerLimit: _playerLimit,
            winCombinations: _winCombinations,
            pricePerTable: _pricePerTable,
            results: new uint[](54)
        }));
    }
    
    function joinGame(uint proposal) public {
        Player storage sender = players[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        gameSessions[proposal].voteCount += sender.weight;
    }
    
    
    function shuffle() external view returns(uint256[] memory){
        uint256[] memory numberArr = new uint[](54);
        for (uint256 i = 0; i < 54; i++) {
            numberArr[i] = i;
        }
        
        for (uint256 i = 0; i < numberArr.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (numberArr.length - i);
            uint256 temp = numberArr[n];
            numberArr[n] = numberArr[i];
            numberArr[i] = temp;
        }
        return numberArr;
    }
}