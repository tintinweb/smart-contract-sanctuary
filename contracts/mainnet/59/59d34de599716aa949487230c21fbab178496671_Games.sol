pragma solidity ^0.4.18;
 
contract Officials {
    address public ceoAddress;
    address public cfoAddress;
    address public cgoAddress;
    
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    modifier onlyCGO() {
        require(msg.sender == cgoAddress);
        _;
    }
    
    modifier onlyOfficers() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cgoAddress 
        );
        _;
    }

    constructor() public {
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cgoAddress = msg.sender;
    }
    
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }
    
    function setCGO(address _newCGO) public onlyCEO {
        require(_newCGO != address(0));
        cgoAddress = _newCGO;
    }
     
    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }
    
}
 
contract Games is Officials{ 
    
    event Pause(bool paused);
    event Create(uint256 gameId, address creator, address challenger, uint256 bet, uint256 count);
    event Cancel(uint256 gameId);
    event Won(uint256 gameId, address winner);
    event Join(uint256 gameId, address challenger);
    
    bool public paused = true;
    uint256 public gameCount = 0;
    uint256 public minimumBet = 0.01 ether;
    uint8 devFee = 6; //6% dev fee;
    
    struct Game {
        address creator;
        address challenger;
        uint bet;
        uint count;
    }
    
    struct GameIndex {
        uint index;
        bool isPlaying;
    }
    
    mapping (address => GameIndex) public players;
    
    Game[] private games;
    
    function togglePaused() public onlyCEO {
        paused = !paused;
        emit Pause(paused);
    }
    
    modifier isUnpaused() {
        require(paused == false);
        _;
    }
    
    modifier isPlaying(address _gameCreator) {
        require(players[_gameCreator].isPlaying);
        _;
    }
    
    function setMinimumBet(uint _newMinBet) public onlyCEO {
        minimumBet = _newMinBet;
    }
    
    function createGame() public payable isUnpaused {
        /* Function Rules */
        // Only 1 Game Per initiator
        // Only 1 Game Per challenger
        require(msg.value >= minimumBet);
        require(!players[msg.sender].isPlaying);
        Game memory m = Game(msg.sender, 0, msg.value, gameCount);
        uint256 newGameId = games.push(m) - 1;
        gameCount++;
        
        players[msg.sender] = GameIndex(newGameId, true);
        
        emit Create(newGameId, m.creator, m.challenger, m.bet, m.count);
    }
    
    function cancelGame(address _gameCreator) public isPlaying(_gameCreator) {
        uint _gameId = players[_gameCreator].index;
        
        Game memory m = games[_gameId];
        require(msg.sender == m.creator || msg.sender == ceoAddress);
        require(m.challenger == 0);
        
        m.creator.transfer(m.bet);
        
        deleteGame(_gameId, m);
        
        emit Cancel(_gameId);
    }
    
    function revertGame(address _gameCreator) public onlyCEO isPlaying(_gameCreator) {
        uint _gameId = players[_gameCreator].index;

        Game memory m = games[_gameId];
        require(m.challenger != 0); //This is only for active games
        
        m.creator.transfer(m.bet);
        m.challenger.transfer(m.bet);
        
        deleteGame(_gameId, m);
        
        emit Cancel(_gameId);
    }
    
    function joinGame(address _gameCreator) public payable isUnpaused isPlaying(_gameCreator){
        uint _gameId = players[_gameCreator].index;
        require(!players[msg.sender].isPlaying);
        
        Game storage m = games[_gameId]; 
        require(msg.sender != m.creator);
        require(m.challenger == 0);
        require(msg.value == m.bet);
        
        m.challenger = msg.sender;
        players[msg.sender] = GameIndex(_gameId, true);
        
        emit Join(_gameId, m.challenger);
    }
    
    function declareWinner(address _gameCreator, bool _creatorWon) public onlyCGO isPlaying(_gameCreator){
        uint _gameId = players[_gameCreator].index;
        
        Game storage m = games[_gameId];
        uint256 devPayout = uint256(SafeMath.div(SafeMath.mul(m.bet, devFee), 100));
        uint256 payout = uint256(SafeMath.add(m.bet, SafeMath.sub(m.bet, devPayout)));
                
        address winner = m.creator;        
         
        if(!_creatorWon){
            winner = m.challenger;
        } 
        
        winner.transfer(payout);

        cfoAddress.transfer(devPayout);
        
        deleteGame(_gameId, m);
        
        emit Won(_gameId, winner);
    }
    
    function deleteGame(uint _gameId, Game _game) internal {
        if (games.length > 1) {
            games[_gameId] = games[games.length - 1];
            
            players[games[_gameId].creator].index = _gameId;
           
            if (games[_gameId].challenger != 0) {
                players[games[_gameId].challenger].index = _gameId;
            }
        }
        
        
        players[_game.creator].isPlaying = false;
        
        if (_game.challenger != 0) {
            players[_game.challenger].isPlaying = false;
        } 
        
        games.length--;
    }
    
    function totalGames() public view returns (uint256 total) {
        return games.length;
    }
    
    function getGameById(uint256 _gameId) public view returns (
        uint gameId,
        address creator,
        address challenger,
        uint bet,
        uint count
     ) {
        Game memory m = games[_gameId];
        gameId = _gameId;
        creator = m.creator;
        challenger = m.challenger;
        bet = m.bet;
        count = m.count;
     }
     
    function getGameByPlayer(address _player) public view isPlaying(_player) returns  (
        uint gameId,
        address creator,
        address challenger,
        uint bet,
        uint count
    ) {
        Game memory m = games[players[_player].index];
        gameId = players[_player].index;
        creator = m.creator;
        challenger = m.challenger;
        bet = m.bet;
        count = m.count;
    }
     
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}