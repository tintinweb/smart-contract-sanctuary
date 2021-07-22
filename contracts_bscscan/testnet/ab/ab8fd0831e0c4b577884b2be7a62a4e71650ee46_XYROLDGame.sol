/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity 0.6.0;

  contract XYROLDGame {  
    
    struct CreateGame{
        uint256 ID;
        address player1;
        address player2;
        uint256 bet;
        address winner;
        uint8 totalround;
        uint8 currentround;
        uint8 status;
        mapping(address => uint8) choices;
    }
    
    uint8 constant ROCK = 1;
    uint8 constant PAPER = 2;
    uint8 constant SCISSORS = 3;
    uint256 public GameID = 1001;
    
    mapping(address => uint256[]) PlayedGames;
    mapping(address => CreateGame[])  GameCreated;
    mapping(address => uint[])  GameCreatedIDs;
    mapping(uint256 => CreateGame) GamesPool;    
    
    address payable public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function creategame(uint8 _choice) external payable {
        require(msg.value > 0 ether, "invalid bet amount");
        address _creator = msg.sender;
        CreateGame storage _newGame = GamesPool[GameID];
        _newGame.ID = GameID;
        _newGame.player1 = _creator;
        _newGame.bet = msg.value;
        _newGame.choices[_creator] = _choice;
        
        GamesPool[GameID] = _newGame;
        GameCreated[_creator].push(_newGame);
        GameCreatedIDs[_creator].push(GameID);
        
        PlayedGames[_creator].push(GameID);
        
        GameID++;
    }
    
    
    function playgame(uint256 _gameId, uint8 _choice) public payable returns (bool){
        
        CreateGame storage _playGame = GamesPool[_gameId];
        require(_playGame.ID > 0, "invalid game ID");
        require(_playGame.player1 != msg.sender, "you are the game owner");
        require(_playGame.player2 == address(0), "the game is done");
        require(_playGame.bet == msg.value, "invalid bet amount");
        
        address _oponent = msg.sender;
        _playGame.player2 = _oponent;
        //_playGame.bet += msg.value;
        _playGame.choices[_oponent] = _choice;
        
        PlayedGames[_oponent].push(_gameId);
        
        address _winner = evaluate(_playGame.player1, _oponent, _gameId);
        if(_winner != address(0)){
            sendprize(_playGame.bet, payable(_winner));
            _playGame.winner = _winner;
        }
        
    }
    
    function sendprize(uint256 _betamount, address payable _winner) internal {
        uint256 _prize = (_betamount * 90) / 100;
        uint256 _com = _betamount - _prize;
        _winner.transfer(_prize);
        owner.transfer(_com);
    }
    function withdraw() public {
         require(msg.sender == owner, "invalid account");
         owner.transfer(address(this).balance);
         //emit Transfer(amount);
 
     }
    
    function MyGames(address _address) view public returns (uint[] memory GameIDs) {
        return GameCreatedIDs[_address];
    }
    
    function GameDetails(uint _gameId) view public returns (uint256 ID, address player1, address player2, uint8 p1_choice, uint8 p2_choice, address winner) {
        CreateGame storage _getGame = GamesPool[_gameId];
        
        return (_getGame.ID, _getGame.player1, _getGame.player2, _getGame.choices[_getGame.player1], _getGame.choices[_getGame.player2], _getGame.winner);
    }
    
    
    function evaluate(address _p1, address _p2, uint256 _gameId) internal view returns (address)
    {
        uint8 _p1_choice = GamesPool[_gameId].choices[_p1];
        uint8 _p2_choice = GamesPool[_gameId].choices[_p2];
        
        if (_p1_choice == _p2_choice) {
            return address(0);
        }

        if (_p1_choice == ROCK && _p2_choice == PAPER) {
            return _p2;
        } else if (_p2_choice == ROCK && _p1_choice == PAPER) {
            return _p1;
        } else if (_p1_choice == SCISSORS && _p2_choice == PAPER) {
            return _p1;
        } else if (_p2_choice == SCISSORS && _p1_choice == PAPER) {
            return _p2;
        } else if (_p1_choice == ROCK && _p2_choice == SCISSORS) {
            return _p1;
        } else if (_p2_choice == ROCK && _p1_choice == SCISSORS) {
            return _p2;
        }
    }
}