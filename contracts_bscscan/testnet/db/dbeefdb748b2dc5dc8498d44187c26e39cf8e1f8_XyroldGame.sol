/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
contract XyroldGame {  
    
    struct Game{
        uint256 ID;
        //uint256 date_created;
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
    
    uint256[] public OpenGamesID;
    uint256[] public ClosedGamesID;
    
    //mapping(address => uint256[]) PlayedGames;
    //mapping(address => uint256) Wins;
    mapping(uint256 => Game)  GamesPool;    
    
    address payable public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    event CreateGame(address indexed creator, uint indexed gameId, uint amount, uint date);
    event PlayGame(address oponent, address creator, uint indexed  gameId, uint date);
    event GameWinner(address indexed winner, address indexed loser, uint gameId, uint amount, uint date);
    
    function createnewgame(uint8 _round1, uint8 _round2, uint8 _round3) external payable {
        
        require(msg.value > 0 ether && msg.value <= 1 ether, "invalid bet amount");
        require(_round1 > 0 && _round1 < 4, "invalid choice value");
        require(_round2 > 0 && _round2 < 4, "invalid choice value");
        require(_round3 > 0 && _round3 < 4, "invalid choice value");

        address _creator = msg.sender;
        
        Game storage _game = GamesPool[GameID];
        _game.ID = GameID;
        //_game.date_created = now;
        _game.creator = _creator;
        _game.bet = msg.value;
        _game.status = 1;
        
        //game details
        _game.details[_creator].round1 = _round1;
        _game.details[_creator].round2 = _round2;
        _game.details[_creator].round3 = _round3;
        
        //PlayedGames[_creator].push(GameID);
        
        OpenGamesID.push(GameID);
        GameID++;
        
        emit CreateGame(_creator, _game.ID, _game.bet, now);
    }
    
    
    function playgame(uint256 _gameId, uint8 _round1, uint8 _round2, uint8 _round3) public payable {

        address _player = msg.sender;
        Game storage _game = GamesPool[_gameId];
        require(_round1 > 0 && _round1 < 4, "invalid choice value");
        require(_round2 > 0 && _round2 < 4, "invalid choice value");
        require(_round3 > 0 && _round3 < 4, "invalid choice value");
        require(_game.creator != _player, "you are the creator");
        require(_game.ID > 0, "invalid game ID");
        require(_game.status == 1, "game is over");
        require(_game.bet == msg.value, "amount didn't match");
        
        emit PlayGame(_player, _game.creator, _game.ID, now);
        
        //game details
        _game.status = 0;
        _game.oponent = _player;
        _game.details[_player].round1 = _round1;
        _game.details[_player].round2 = _round2;
        _game.details[_player].round3 = _round3;
        
        ClosedGamesID.push(_gameId);
        
        //PlayedGames[_player].push(_gameId);
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
            
           // Wins[_p1] += 1;
            sendprize((_game.bet * 2), payable(_p1));
            emit GameWinner(_p1, _p2,  _game.ID, (_game.bet * 2), now);
        }else{
            _game.winner = _p2;
            //Wins[_p2] += 1;
            sendprize((_game.bet * 2), payable(_p2));
            emit GameWinner(_p2,  _p1, _game.ID, (_game.bet * 2), now);
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
    /*
    function MyGames(address _address) view public returns (uint[] memory GameIDs) {
        return PlayedGames[_address];
    }
    */
    
    function GameInfo(uint _gameId) view public returns (uint256 ID, address player1, address player2, uint8 _p1_score , uint8 _p2_score, address winner, uint256 prize, string memory status) {
        Game storage _getGame = GamesPool[_gameId];
        string memory _status = "Closed";
        if(_getGame.status == 1){
            _status = "Open";
        }
        return (_getGame.ID, _getGame.creator, _getGame.oponent, _getGame.scores[_getGame.creator], _getGame.scores[_getGame.oponent],  _getGame.winner, (_getGame.bet * 2), _status);
    }
    
    function RoundChoices(uint _gameId, address _player) view public returns (uint256 ID,  string memory round1, string memory round2, string memory round3) {
        Game storage _getGame = GamesPool[_gameId];
        if(_getGame.status == 1){
        
            return (_getGame.ID, "xxx", "xxx","xxx");
        }
        return (_getGame.ID,  getchoicename(_getGame.details[_player].round1), getchoicename(_getGame.details[_player].round2),  getchoicename(_getGame.details[_player].round3));
    }
    
    function getchoicename(uint8 _choice) internal pure returns(string memory){
        if(_choice == ROCK){ return "ROCK"; }
        else if(_choice == PAPER){ return "PAPER"; }
        else { return "SCISSORS"; }
    }
    
    function cancelgame(uint256 _gameId) public{
        address _player = msg.sender;
        Game storage _game = GamesPool[_gameId];
        require(_game.ID > 0, "invalid game ID");
        require(_game.status == 1, "game is over");
        require(_game.creator == _player, "you are not the creator");
        
        _game.status = 3; //cancelled
        payable(_player).transfer(_game.bet);
    }
    
    
}