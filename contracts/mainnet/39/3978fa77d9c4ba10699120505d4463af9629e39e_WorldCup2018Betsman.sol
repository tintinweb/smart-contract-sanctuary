pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract Adminable is Ownable {
  mapping(address => bool) public admins;

  modifier onlyAdmin() {
    require(admins[msg.sender]);
    _;
  }

  function addAdmin(address user) onlyOwner public {
    require(user != address(0));
    admins[user] = true;
  }

  function removeAdmin(address user) onlyOwner public {
    require(user != address(0));
    admins[user] = false;
  }
}

contract WorldCup2018Betsman is Destructible, Adminable {

  using SafeMath for uint256;

  struct Bet {
    uint256 amount;
    uint8 result;
    bool isReverted;
    bool isFree;
    bool isClaimed;
  }

  struct Game {
    string team1;
    string team2;
    uint date;
    bool ended;
    uint256 firstWinResultSum;
    uint256 drawResultSum;
    uint256 secondWinResultSum;
    uint8 result;
  }

  struct User {
    uint freeBets;
    uint totalGames;
    uint256[] games;
    uint statisticBets;
    uint statisticBetsSum;
  }

  mapping (uint => Game) public games;
  mapping (uint => uint[]) public gamesByDayOfYear;
  
  mapping (address => mapping(uint => Bet)) public bets;
  mapping (address => User) public users;
  

  uint public lastGameId = 0;

  uint public minBet = 0.001 ether;
  uint public maxBet = 1 ether;
  uint public betsCountToUseFreeBet = 3;

  Game game;
  Bet bet;
  
  modifier biggerMinBet() { 
    require (msg.value >= minBet, "Bet value is lower min bet value."); 
    _; 
  }

  modifier lowerMaxBet() { 
    require (msg.value <= maxBet, "Bet value is bigger max bet value.");
    _; 
  }

  function hasBet(uint256 _gameId) view internal returns(bool){
    return bets[msg.sender][_gameId].amount > 0;
  }
  
  modifier hasUserBet(uint256 _gameId) { 
    require (hasBet(_gameId), "User did not bet this game."); 
    _; 
  }
  
  modifier hasNotUserBet(uint256 _gameId) { 
    require(!hasBet(_gameId), "User has already bet this game.");
    _; 
  }

  modifier hasFreeBets() { 
    require (users[msg.sender].freeBets > 0, "User does not have free bets."); 
    _; 
  }

  modifier isGameExist(uint256 _gameId) { 
    require(!(games[_gameId].ended), "Game does not exist.");
    _; 
  }

  modifier isGameNotStarted(uint256 _gameId) { 
    // stop making bets when 5 minutes till game start 
    // 300000 = 1000 * 60 * 5 - 5 minutes
    require(games[_gameId].date > now + 300000, "Game has started.");
    _; 
  }

  modifier isRightBetResult(uint8 _betResult) { 
    require (_betResult > 0 && _betResult < 4);
    _; 
  }
  
  function setMinBet(uint256 _minBet) external onlyAdmin {
    minBet = _minBet;
  }

  function setMaxBet(uint256 _maxBet) external onlyAdmin {
    maxBet = _maxBet;
  }

  function addFreeBet(address _gambler, uint _count) external onlyAdmin  {
    users[_gambler].freeBets += _count;
  }

  function addGame(string _team1, string _team2, uint _date, uint _dayOfYear) 
    external
    onlyAdmin
  {
    lastGameId += 1;
    games[lastGameId] = Game(_team1, _team2, _date, false, 0, 0, 0, 0);
    gamesByDayOfYear[_dayOfYear].push(lastGameId);
  }

  function setGameResult(uint _gameId, uint8 _result)
    external
    isGameExist(_gameId)
    isRightBetResult(_result)
    onlyAdmin
  {
    games[_gameId].ended = true;
    games[_gameId].result = _result;
  }

  function addBet(uint _gameId, uint8 _betResult, uint256 _amount, bool _isFree) internal{
    bets[msg.sender][_gameId] = Bet(_amount, _betResult, false, _isFree, false);
    if(_betResult == 1){
      games[_gameId].firstWinResultSum += _amount;
    } else if(_betResult == 2) {
      games[_gameId].drawResultSum += _amount;
    } else if(_betResult == 3) {
      games[_gameId].secondWinResultSum += _amount;
    }
    users[msg.sender].games.push(_gameId);
    users[msg.sender].totalGames += 1;
  }
  
  function betGame (
    uint _gameId,
    uint8 _betResult
  ) 
    external
    biggerMinBet
    lowerMaxBet
    isGameExist(_gameId)
    isGameNotStarted(_gameId)
    hasNotUserBet(_gameId)
    isRightBetResult(_betResult)
    payable
  {
    addBet(_gameId, _betResult, msg.value, false);
    users[msg.sender].statisticBets += 1;
    users[msg.sender].statisticBetsSum += msg.value;
  }

  function betFreeGame(
    uint _gameId,
    uint8 _betResult
  ) 
    hasFreeBets
    isGameExist(_gameId)
    isGameNotStarted(_gameId)
    hasNotUserBet(_gameId)
    isRightBetResult(_betResult)
    external 
  {
    require(users[msg.sender].statisticBets >= betsCountToUseFreeBet, "You need more bets to use free bet");
    users[msg.sender].statisticBets -= betsCountToUseFreeBet;
    users[msg.sender].freeBets -= 1;
    addBet(_gameId, _betResult, minBet, true);
  }

  function revertBet(uint _gameId)
    hasUserBet(_gameId)
    isGameNotStarted(_gameId)
    external 
  {
    bool isFree = bets[msg.sender][_gameId].isFree;
    require(!isFree, "You can not revert free bet");
    bool isReverted = bets[msg.sender][_gameId].isReverted;
    require(!isReverted, "You can not revert already reverted bet");
    uint256 amount = bets[msg.sender][_gameId].amount;
    uint256 betResult = bets[msg.sender][_gameId].result;
    if(betResult == 1){
      games[_gameId].firstWinResultSum -= amount;
    } else if(betResult == 2) {
      games[_gameId].drawResultSum -= amount;
    } else if(betResult == 3) {
      games[_gameId].secondWinResultSum -= amount;
    }
    bets[msg.sender][_gameId].isReverted = true;
    msg.sender.transfer(amount.mul(9).div(10)); // return 90% of bet
  }

  function claimPrize(uint _gameId) 
    hasUserBet(_gameId)
    public
  {
    address gambler = msg.sender;
    game = games[_gameId];
    bet = bets[gambler][_gameId];
    require(game.ended, "Game has not ended yet.");
    require(bet.result == game.result, "You did not win this game");
    require(!bet.isReverted, "You can not claim reverted bet");
    require(!bet.isClaimed, "You can not claim already claimed bet");
    bets[gambler][_gameId].isClaimed = true;
    uint winResultSum = 0;
    uint prize = 0;
    if(game.result == 1){
      winResultSum = game.firstWinResultSum;
      prize = game.drawResultSum + game.secondWinResultSum;
    } else if(game.result == 2) {
      winResultSum = game.drawResultSum;
      prize = game.firstWinResultSum + game.secondWinResultSum;
    } else if(game.result == 3) {
      winResultSum = game.secondWinResultSum;
      prize = game.firstWinResultSum + game.drawResultSum;
    }
    // prize = bet amount + (prize * (total result amount / bet amount)) * 80 %;
    uint gamblerPrize = prize.mul(bet.amount).mul(8).div(10).div(winResultSum);
    if(!bet.isFree){
      gamblerPrize = bet.amount + gamblerPrize;
    }
    gambler.transfer(gamblerPrize);
    winResultSum = 0;
    prize = 0;
    gamblerPrize = 0;
    delete game;
    delete bet;
  }

  function getGamblerGameIds(address _gambler) public constant returns (uint256[]){
    return users[_gambler].games;
  }

  function getGamesByDay(uint _dayOfYear) public constant returns (uint256[]){
    return gamesByDayOfYear[_dayOfYear];
  }

  function getGamblerBet(address _gambler, uint _gameId) public constant returns(uint, uint256, uint8, bool, bool, bool){
    Bet storage tempBet = bets[_gambler][_gameId];
    return (
      _gameId,
      tempBet.amount,
      tempBet.result,
      tempBet.isReverted,
      tempBet.isFree,
      tempBet.isClaimed
    );
  }

  function withdraw(uint amount) public onlyOwner {
    owner.transfer(amount);
  }
  
  constructor() public payable {
    addAdmin(msg.sender);
    games[1] = Game("RUS", "SAU", 1528984800000, false, 0, 0, 0, 0);
    gamesByDayOfYear[165] = [1];
    games[2] = Game("EGY", "URG", 1529060400000, false, 0, 0, 0, 0);
    games[3] = Game("MAR", "IRN", 1529071200000, false, 0, 0, 0, 0);
    games[4] = Game("POR", "SPA", 1529082000000, false, 0, 0, 0, 0);
    gamesByDayOfYear[166] = [2,3,4];
    games[5] = Game("FRA", "AUS", 1529139600000, false, 0, 0, 0, 0);
    games[6] = Game("ARG", "ISL", 1529150400000, false, 0, 0, 0, 0);
    games[7] = Game("PER", "DAN", 1529161200000, false, 0, 0, 0, 0);
    games[8] = Game("CRO", "NIG", 1529172000000, false, 0, 0, 0, 0);
    gamesByDayOfYear[167] = [5,6,7,8];
    lastGameId = 8;
  }
}