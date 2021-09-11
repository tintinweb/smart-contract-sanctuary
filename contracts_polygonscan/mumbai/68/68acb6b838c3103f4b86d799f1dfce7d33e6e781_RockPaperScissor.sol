/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

pragma solidity ^0.5.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address private owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
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
    require(owner != newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract RockPaperScissor is Ownable {

    using SafeMath for uint256;

    uint constant private JACKPOT_MIN = 100000000000000000;
    uint constant private JACKPOT_MAX = 200000000000000000;

    address payable private _contractOwner;
    
    struct GameResult {
        address player;
        uint8 result;  // 0:Tie, 1:Player Win, 2:Player Lose
        uint8 betOption;  // 1:scissor, 2:rock, 3:paper
        uint8 bankerOption;  // 1:scissor, 2:rock, 3:paper
    }
    
    struct JackpotRecord {
        address player;
        uint gameId;
        uint256 amount;
    }

    GameResult[] public _gameResults;
    JackpotRecord[] public _jackpotRecords;

    bool private _isServing = true;
    uint private _currentGameId = 0;
    uint private _nonce = 0;
    mapping(uint => address) private gameIdToPlayer;
    mapping(uint => uint) private gameIdToBetOption;
    mapping(address => uint) private playerGameCount;
    mapping(address => uint) private playerTieCount;
    mapping(address => uint) private playerWinCount;
    mapping(address => uint) private playerLossCount;
    mapping(address => uint) private playerLastGameId;
    uint256 private _jackpotValue = 0;
    uint256 private _jackpotPool = JACKPOT_MIN;
    mapping(uint => uint256) private gameIdToJackpotAmount;
    mapping(address => uint) private playerJackpotCount;
    mapping(address => uint256) private playerJackpotTotalAmount;

    event gameResult(string result,address player,uint playerOption,uint bankerOption);  // 1:scissor, 2:rock, 3:paper
    event hitJackpot(address player,uint gameId,uint256 amount);
    uint _bankerOption;  // 1:scissor, 2:rock, 3:paper

    constructor() payable public {
        _contractOwner = msg.sender;
        refreshJackpotThreshold();
    }

    function refreshJackpotThreshold() private {
        _jackpotValue = JACKPOT_MIN + (uint256(keccak256(abi.encodePacked(_jackpotValue,now))) % 1000000)*100000000000;
    }
    
    function getJackpotThreshold() public view onlyOwner returns(uint256 threshold){
        return _jackpotValue;
    }
    
    function getJackpotPool() public view returns(uint256 poolValue){
        return _jackpotPool;
    }
    
    function getJackpotStatistic(address player) public view returns(uint count, uint256 totalAmount){
        return (playerJackpotCount[player], playerJackpotTotalAmount[player]);
    }

    function recordResultAndPay(address payable player,uint betOption, uint bankerOption, uint256 jackpotAmount) private {
        require(player != address(0));
        require(betOption >= 1 && betOption <= 3);
        require(bankerOption >= 1 && bankerOption <= 3);

        uint8 result = 0;  // 0:Tie, 1:Player Win, 2:Player Lose

        if(bankerOption == 1 && betOption == 3) {  // banker win
            playerLossCount[player]++;
            result = 2;
            if(jackpotAmount > 0) player.transfer(jackpotAmount);
        }
        else if(bankerOption == 2 && betOption == 1) {  // banker win
            playerLossCount[player]++;
            result = 2;
            if(jackpotAmount > 0) player.transfer(jackpotAmount);
        }
        else if(bankerOption == 3 && betOption == 2) {  // banker win
            playerLossCount[player]++;
            result = 2;
            if(jackpotAmount > 0) player.transfer(jackpotAmount);
        }
        else if(bankerOption == 1 && betOption == 2) {  // player win
            result = 1;
            playerWinCount[player]++;
            player.transfer(0.019 ether + jackpotAmount);
        }
        else if(bankerOption == 2 && betOption == 3) {  // player win
            result = 1;
            playerWinCount[player]++;
            player.transfer(0.019 ether + jackpotAmount);
        }
        else if(bankerOption == 3 && betOption == 1) {  // player win
            result = 1;
            playerWinCount[player]++;
            player.transfer(0.019 ether + jackpotAmount);
        }
        else if(bankerOption == betOption) {  // Tie
            result = 0;
            playerTieCount[player]++;
            //  Transfer 0.1 ether to player
            player.transfer(0.0095 ether + jackpotAmount);
        }
        else{
            revert();
        }

        _gameResults.push(GameResult(player,result,uint8(betOption),uint8(bankerOption)));
        playerGameCount[player]++;

          // 0:Tie, 1:Player Win, 2:Player Lose
        if(result == 0) emit gameResult("Tie",player,betOption,bankerOption);
        else if(result == 1) emit gameResult("Player Win",player,betOption,bankerOption);
        else if(result == 2) emit gameResult("Player Lose",player,betOption,bankerOption);
        
        if(jackpotAmount > 0){
            _jackpotRecords.push(JackpotRecord(player,_currentGameId,jackpotAmount));
            gameIdToJackpotAmount[_currentGameId] = jackpotAmount;
            playerJackpotCount[player]++;
            playerJackpotTotalAmount[player] = playerJackpotTotalAmount[player].add(jackpotAmount);
            emit hitJackpot(player,_currentGameId,jackpotAmount);
        }
        
        if(address(this).balance <= 0.22 ether){
            //selfdestruct(_contractOwner);
            _isServing = false;
        }
    }

    function getBankerOption() private returns(uint bankerOption) {
        bankerOption = (uint(keccak256(abi.encodePacked(_currentGameId,_nonce,now))) % 3) + 1;
        _nonce++;
        return bankerOption;
    }
    
    function bet(uint betOption) payable public returns(uint8, uint, uint) {  // return result, betOption, bankerOption
        require(_isServing == true,"Out of Service!");
        require(msg.value == 0.01 ether,"You can only bet 0.01 ether!");
        require(betOption >= 1 && betOption <= 3,"Bet option should be between 1~3!");

        uint8 result = 0;
        bool isHitJackpot = false;
        uint256 jackpotAmount = 0;

        // Record the player data
        gameIdToBetOption[_currentGameId] = betOption;
        gameIdToPlayer[_currentGameId] = msg.sender;

        // contribute to jackpot pool and check if hit jackpot
        _jackpotPool += msg.value/10;
        if(_jackpotPool >= _jackpotValue){
            isHitJackpot = true;
            jackpotAmount = _jackpotValue;
        }

        // Get banker option
        uint bankerOption = getBankerOption();
        
        // Record game result and pay
        recordResultAndPay(msg.sender,betOption,bankerOption,jackpotAmount);

        playerLastGameId[msg.sender] = _currentGameId;
        result = _gameResults[_currentGameId].result;

        _bankerOption = bankerOption;
        _currentGameId++;
        _nonce += ((uint(keccak256(abi.encodePacked(_currentGameId,_nonce,now))) % 10) + 1);
        
        if(isHitJackpot == true) {
            refreshJackpotThreshold();
            _jackpotPool = JACKPOT_MIN;
        }
        
        return (result,betOption,bankerOption);
    }

    function getLastGame(address player) view public returns(uint, uint8, uint8, uint8, uint256) {
        require(player != address(0));

        if(playerGameCount[player] == 0){
            return (0,0,0,0,0);
        }

        uint gameId = playerLastGameId[player];
        return(playerLastGameId[player],_gameResults[gameId].result,_gameResults[gameId].betOption,_gameResults[gameId].bankerOption,gameIdToJackpotAmount[gameId]);
    }
    
    function playerGameRecords(address player) view public returns(uint[] memory gameIdArray) {
        gameIdArray = new uint[](playerGameCount[player]);
        uint index = 0;
        for(uint i=0; i<_gameResults.length; i++) {
            if(_gameResults[i].player == player) {
                gameIdArray[index] = i;
                index++;
            }
        }
        return gameIdArray;
    }

    function playerGameStatistic(address player) view public returns(uint tie, uint win, uint lose) {
        return (playerTieCount[player],playerWinCount[player],playerLossCount[player]);
    }
    
    // Following functions are only for owner
    function ownerAddMoney() payable public {
        require(msg.sender == _contractOwner,"Only contract owner can do it!");
    }

    function ownerSubMoney(uint256 amount) payable public {  // Only accessable for contract owner
        require(msg.sender == _contractOwner,"Only contract owner can do it!");
        require(amount < address(this).balance);

        _contractOwner.transfer(amount);
        //selfdestruct(_contractOwner);
    }
    
    function isOnService() public view onlyOwner returns(bool isServing) {
        return _isServing;
    }
    
    function setService(bool serve) public onlyOwner {
        _isServing = serve;
    }
}