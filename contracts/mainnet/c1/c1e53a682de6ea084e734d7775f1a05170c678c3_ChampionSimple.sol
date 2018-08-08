pragma solidity ^0.4.18;

// zeppelin-solidity: 1.8.0

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ChampionSimple is Ownable {
  using SafeMath for uint;

  event LogDistributeReward(address addr, uint reward);
  event LogParticipant(address addr, uint choice, uint betAmount);
  event LogModifyChoice(address addr, uint oldChoice, uint newChoice);
  event LogRefund(address addr, uint betAmount);
  event LogWithdraw(address addr, uint amount);
  event LogWinChoice(uint choice, uint reward);

  uint public minimumBet = 5 * 10 ** 16;
  uint public deposit = 0;
  uint public totalBetAmount = 0;
  uint public startTime;
  uint public winChoice;
  uint public winReward;
  uint public numberOfBet;
  bool public betClosed = false;

  struct Player {
    uint betAmount;
    uint choice;
  }

  address [] public players;
  mapping(address => Player) public playerInfo;
  mapping(uint => uint) public numberOfChoice;
  mapping(uint => mapping(address => bool)) public addressOfChoice;
  mapping(address => bool) public withdrawRecord;
 
  modifier beforeTimestamp(uint timestamp) {
    require(now < timestamp);
    _;
  }

  modifier afterTimestamp(uint timestamp) {
    require(now >= timestamp);
    _;
  }

  /**
   * @dev the construct function
   * @param _startTime the deadline of betting
   * @param _minimumBet the minimum bet amount
   */
  function ChampionSimple(uint _startTime, uint _minimumBet) payable public {
    require(_startTime > now);
    deposit = msg.value;
    startTime = _startTime;
    minimumBet = _minimumBet;
  }

  /**
   * @dev find a player has participanted or not
   * @param player the address of the participant
   */
  function checkPlayerExists(address player) public view returns (bool) {
    if (playerInfo[player].choice == 0) {
      return false;
    }
    return true;
  }

  /**
   * @dev to bet which team will be the champion
   * @param choice the choice of the participant(actually team id)
   */
  function placeBet(uint choice) payable beforeTimestamp(startTime) public {
    require(choice > 0);
    require(!checkPlayerExists(msg.sender));
    require(msg.value >= minimumBet);

    playerInfo[msg.sender].betAmount = msg.value;
    playerInfo[msg.sender].choice = choice;
    totalBetAmount = totalBetAmount.add(msg.value);
    numberOfBet = numberOfBet.add(1);
    players.push(msg.sender);
    numberOfChoice[choice] = numberOfChoice[choice].add(1);
    addressOfChoice[choice][msg.sender] = true;
    LogParticipant(msg.sender, choice, msg.value);
  }

  /**
   * @dev allow user to change their choice before a timestamp
   * @param choice the choice of the participant(actually team id)
   */
  function modifyChoice(uint choice) beforeTimestamp(startTime) public {
    require(choice > 0);
    require(checkPlayerExists(msg.sender));

    uint oldChoice = playerInfo[msg.sender].choice;
    numberOfChoice[oldChoice] = numberOfChoice[oldChoice].sub(1);
    numberOfChoice[choice] = numberOfChoice[choice].add(1);
    playerInfo[msg.sender].choice = choice;

    addressOfChoice[oldChoice][msg.sender] = false;
    addressOfChoice[choice][msg.sender] = true;
    LogModifyChoice(msg.sender, oldChoice, choice);
  }

  /**
   * @dev close who is champion bet with the champion id
   */
  function saveResult(uint teamId) onlyOwner public {
    winChoice = teamId;
    betClosed = true;
    winReward = deposit.add(totalBetAmount).div(numberOfChoice[winChoice]);
    LogWinChoice(winChoice, winReward);
  }

  /**
   * @dev every user can withdraw his reward
   */
  function withdrawReward() public {
    require(betClosed);
    require(!withdrawRecord[msg.sender]);
    require(winChoice > 0);
    require(winReward > 0);
    require(addressOfChoice[winChoice][msg.sender]);

    msg.sender.transfer(winReward);
    withdrawRecord[msg.sender] = true;
    LogDistributeReward(msg.sender, winReward);
  }

  /**
   * @dev anyone could recharge deposit
   */
  function rechargeDeposit() payable public {
    deposit = deposit.add(msg.value);
  }

  /**
   * @dev get player bet information
   * @param addr indicate the bet address
   */
  function getPlayerBetInfo(address addr) view public returns (uint, uint) {
    return (playerInfo[addr].choice, playerInfo[addr].betAmount);
  }

  /**
   * @dev get the bet numbers of a specific choice
   * @param choice indicate the choice
   */
  function getNumberByChoice(uint choice) view public returns (uint) {
    return numberOfChoice[choice];
  }

  /**
   * @dev if there are some reasons lead game postpone or cancel
   *      the bet will also cancel and refund every bet
   */
  function refund() onlyOwner public {
    for (uint i = 0; i < players.length; i++) {
      players[i].transfer(playerInfo[players[i]].betAmount);
      LogRefund(players[i], playerInfo[players[i]].betAmount);
    }
  }

  /**
   * @dev get the players
   */
  function getPlayers() view public returns (address[]) {
    return players;
  }

  /**
   * @dev dealer can withdraw the remain ether if distribute exceeds max length
   */
  function withdraw() onlyOwner public {
    uint _balance = address(this).balance;
    owner.transfer(_balance);
    LogWithdraw(owner, _balance);
  }
}