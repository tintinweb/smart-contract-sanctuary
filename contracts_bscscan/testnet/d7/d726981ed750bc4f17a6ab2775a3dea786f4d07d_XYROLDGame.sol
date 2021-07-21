/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity 0.6.0;

  contract XYROLDGame {  
    uint8 constant ROCK = 1;
    uint8 constant PAPER = 2;
    uint8 constant SCISSORS = 3;
    
    uint256 public GameID = 1001;
    
    struct CreateGame{
        uint256 ID;
        address player1;
        address player2;
        uint256 bet;
        address winner;
        uint8 round;
        mapping(address => uint8) choices;
    }
    
    mapping(address => uint256[]) public PlayedGames;
    
    mapping(address => CreateGame[]) public GameCreated;
    mapping(address => uint[]) public GameCreatedIDs;
    
    mapping(uint256 => CreateGame) GamesPool;    
    
    mapping(address => uint8) public choices;
    
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
        
        address _winner = evaluate(_playGame.player1, _oponent);
        _playGame.winner = _winner;
        
        uint256 _prize = (_playGame.bet * 90) / 100;
        uint256 _com = _playGame.bet - _prize;
        payable(_winner).transfer(_prize);
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
    
    
    function evaluate(address p1, address p2) internal view returns (address)
    {
        // if the choices are the same, the game is a draw, therefore returning 0x0000000000000000000000000000000000000000 as the winner
        if (choices[p1] == choices[p2]) {
            return address(0);
        }

        // paper beats rock bob/alice
        if (choices[p1] == ROCK && choices[p2] == PAPER) {
            return p2;
            // paper still beats rock (played in opposite alice/bob)
        } else if (choices[p2] == ROCK && choices[p1] == PAPER) {
            return p1;
        } else if (choices[p1] == SCISSORS && choices[p2] == PAPER) {
            return p1;
        } else if (choices[p2] == SCISSORS && choices[p1] == PAPER) {
            return p2;
        } else if (choices[p1] == ROCK && choices[p2] == SCISSORS) {
            return p1;
        } else if (choices[p2] == ROCK && choices[p1] == SCISSORS) {
            return p2;
        }
    }
}