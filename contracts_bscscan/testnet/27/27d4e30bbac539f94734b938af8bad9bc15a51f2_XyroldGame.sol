/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


contract XyroldGame {  
    
    struct Game{
        uint256 ID;
        uint256 date_created;
        address creator;
        address oponent;
        uint8 status;
        uint256 bet;
        address winner;
        mapping(address => uint8) scores;
        mapping(address => PlayDetails) details;
    }
    
    struct PlayDetails{
        uint8 round1;
        uint8 round2;
        uint8 round3;
    }
    
    uint8 constant ROCK = 1;
    uint8 constant PAPER = 2;
    uint8 constant SCISSORS = 3;
    uint256 public GameID = 1001;
    
    
    mapping(address => uint256[]) PlayedGames;
    mapping(address => uint256) Wins;
    mapping(uint256 => Game)  GamesPool;    

    
    address payable public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function createnewgame(uint8 _round1, uint8 _round2, uint8 _round3) external payable {
        
        require(msg.value > 0 ether && msg.value <= 1, "invalid bet amount");
        require(_round1 > 0 && _round1 < 4, "invalid choice value");
        require(_round2 > 0 && _round2 < 4, "invalid choice value");
        require(_round3 > 0 && _round3 < 4, "invalid choice value");

        address _creator = msg.sender;
        
        Game storage _game = GamesPool[GameID];
        _game.ID = GameID;
        _game.date_created = now;
        _game.creator = _creator;
        _game.bet = msg.value;
        _game.status = 1;
        
        //game details
        _game.details[_creator].round1 = _round1;
        _game.details[_creator].round2 = _round2;
        _game.details[_creator].round3 = _round3;
        
        PlayedGames[_creator].push(GameID);
        
        GameID++;
    }

    
    function playgame(uint256 _gameId, uint8 _round1, uint8 _round2, uint8 _round3) public payable {

        address _player = msg.sender;
        Game storage _game = GamesPool[_gameId];
         require(_round1 > 0 && _round1 < 4, "invalid choice value");
        require(_round2 > 0 && _round2 < 4, "invalid choice value");
        require(_round3 > 0 && _round3 < 4, "invalid choice value");
        require(_game.ID > 0, "invalid game ID");
        require(_game.status == 1, "game is over");
        require(_game.bet == msg.value, "amount didn't match");
        
        //game details
        _game.status = 0;
        _game.oponent = _player;
        _game.details[_player].round1 = _round1;
        _game.details[_player].round2 = _round2;
        _game.details[_player].round3 = _round3;
        
        PlayedGames[_player].push(GameID);
        
        processgamewinner(_gameId);
    }
   
    function processgamewinner(uint256 _gameId) internal returns (address) {
        Game storage _game = GamesPool[_gameId];
        address _p1 = _game.creator;
        address _p2  = _game.oponent;
        
        
        _game.scores[getroundwinner(_game.details[_p1].round1, _game.details[_p2].round1, _p1, _p2)] += 1;
        _game.scores[getroundwinner(_game.details[_p1].round2, _game.details[_p2].round2, _p1, _p2)] += 1;
        _game.scores[getroundwinner(_game.details[_p1].round3, _game.details[_p2].round3, _p1, _p2)] += 1;
        
        uint8 _p1_score = _game.scores[_p1];
        uint8 _p2_score = _game.scores[_p2];
        
        if(_p1_score == _p2_score){
            _game.winner = address(0);
            sendprize(_game.bet, payable(_p1));
            sendprize(_game.bet, payable(_p2));
        }else if(_p1_score > _p2_score){
            _game.winner = _p1;
            Wins[_p1] += 1;
            sendprize((_game.bet * 2), payable(_p1));
        }else{
            _game.winner = _p2;
            Wins[_p2] += 1;
            sendprize((_game.bet * 2), payable(_p2));
        }
        
        _game.status  = 0;
        
        
    }
    
    function getroundwinner(uint8 _p1_choice, uint8 _p2_choice, address _p1, address _p2) internal pure returns (address)
    {
       
        if(_p1_choice == _p2_choice) return address(0);
        else if (_p1_choice == ROCK && _p2_choice == PAPER) { return _p2; } 
        else if (_p2_choice == ROCK && _p1_choice == PAPER) { return _p1; } 
        else if (_p1_choice == SCISSORS && _p2_choice == PAPER) { return _p1; } 
        else if (_p2_choice == SCISSORS && _p1_choice == PAPER) { return _p2; } 
        else if (_p1_choice == ROCK && _p2_choice == SCISSORS) { return _p1; } 
        else if (_p2_choice == ROCK && _p1_choice == SCISSORS) { return _p2; }
        
    }

    
    
    function sendprize(uint256 _betamount, address payable _winner) internal {
        uint256 _prize = (_betamount * 95) / 100;
        uint256 _com = _betamount - _prize; //dev commission fee
        _winner.transfer(_prize);
        owner.transfer(_com);
    }
    
    
    function withdraw() public {
         require(msg.sender == owner, "invalid account");
         owner.transfer(address(this).balance);
         //emit Transfer(amount);
     }
    
    function MyGames(address _address) view public returns (uint[] memory GameIDs) {
        return PlayedGames[_address];
    }
    /*
    function GameDetails(uint _gameId) view public returns (uint256 ID, address player1, address player2, string memory p1_choice, string memory p2_choice, address winner) {
        CreateGame storage _getGame = GamesPool[_gameId];
        string memory _p1choice = getchoicename(_getGame.choices[_getGame.player1]);
        string memory _p2choice = getchoicename(_getGame.choices[_getGame.player2]);
        return (_getGame.ID, _getGame.player1, _getGame.player2, _p1choice , _p2choice, _getGame.winner);
    }
    
    
    function getchoicename(uint8 _choice) internal pure returns(string memory){
        if(_choice == rock){ return "ROCK"; }
        else if(_choice == paper){ return "PAPER"; }
        else { return "SCISSORS"; }
    }
    
    */
    
}