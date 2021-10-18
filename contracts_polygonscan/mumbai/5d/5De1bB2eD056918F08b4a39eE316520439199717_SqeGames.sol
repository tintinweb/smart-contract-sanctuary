/**
 *Submitted for verification at polygonscan.com on 2021-10-17
*/

// File: contracts/4_SqeGames.sol

//Always use latest.
pragma solidity ^0.8.9;

contract SqeGames {
    
    address public owner;
    bool public paused;
    
    constructor() {
        owner = msg.sender;
    }
    
    function setPaused(bool _paused) public {
        require(msg.sender == owner, "You are not the owner");
        paused = _paused;
    }

    struct Player {
        string email;
        uint tickets;
        uint lives;
        uint[] badges;
        uint currentBadge;
        uint currentGame;
    }
    
    mapping (address => Player) players;
    address[] public playerAccts;
    
    function createPlayer(address _address, string memory _email, uint _tickets, uint _lives, uint[] memory _badges, uint _currentBadge, uint _currentGame) public {
        require(paused == false, "Contract Paused");
        Player memory player = Player(_email, _tickets, _lives, _badges, _currentBadge, _currentGame);
        players[_address] = player;

        player.email = _email;
        player.tickets = _tickets;
        player.lives = _lives;
        player.badges = _badges;
        player.currentBadge = _currentBadge;
        player.currentGame = _currentGame;
        
        playerAccts.push(_address);
        playerAccts.length -1;

    }
    
    function getPlayers() view public returns(address[] memory) {
        require(paused == false, "Contract Paused");
        return playerAccts;
    }
    
    function getPlayer(address _address) view public returns (string memory, uint, uint, uint[] memory, uint, uint) {
        require(paused == false, "Contract Paused");
        return (players[_address].email, players[_address].tickets, players[_address].lives, players[_address].badges, players[_address].currentBadge, players[_address].currentGame);
    }
    
    function countPlayers() view public returns (uint) {
        require(paused == false, "Contract Paused");
        return playerAccts.length;
    }
}