pragma solidity ^0.4.23;

/*
* Zethroll.
*
* Adapted from PHXRoll, written in March 2018 by TechnicalRise:
*   https://www.reddit.com/user/TechnicalRise/
*
* Gas golfed by Etherguy
* Audited & commented by Klob
*/

contract ZTHReceivingContract {
  /**
   * @dev Standard ERC223 function that will handle incoming token transfers.
   *
   * @param _from  Token sender address.
   * @param _value Amount of tokens.
   * @param _data  Transaction metadata.
   */
  function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}


contract ZTHInterface {
  function getFrontEndTokenBalanceOf(address who) public view returns (uint);
  function transfer(address _to, uint _value) public returns (bool);
  function approve(address spender, uint tokens) public returns (bool);
}

contract Zethroll is ZTHReceivingContract {
  using SafeMath for uint;

  // Makes sure that player profit can&#39;t exceed a maximum amount,
  //  that the bet size is valid, and the playerNumber is in range.
  modifier betIsValid(uint _betSize, uint _playerNumber) {
     require( calculateProfit(_betSize, _playerNumber) < maxProfit
             && _betSize >= minBet
             && _playerNumber > minNumber
             && _playerNumber < maxNumber);
    _;
  }

  // Requires game to be currently active
  modifier gameIsActive {
    require(gamePaused == false);
    _;
  }

  // Requires msg.sender to be owner
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  // Constants
  uint constant private MAX_INT = 2 ** 256 - 1;
  uint constant public maxProfitDivisor = 1000000;
  uint constant public maxNumber = 100;
  uint constant public minNumber = 2;
  uint constant public houseEdgeDivisor = 1000;

  // Configurables
  bool public gamePaused;

  address public owner;
  address public ZethrBankroll;
  address public ZTHTKNADDR;

  ZTHInterface public ZTHTKN;

  uint public contractBalance;
  uint public houseEdge;
  uint public maxProfit;
  uint public maxProfitAsPercentOfHouse;
  uint public minBet = 0;

  // Trackers
  uint public totalBets;
  uint public totalZTHWagered;

  // Events

  // Logs bets + output to web3 for precise &#39;payout on win&#39; field in UI
  event LogBet(address sender, uint value, uint rollUnder);

  // Outputs to web3 UI on bet result
  // Status: 0=lose, 1=win, 2=win + failed send, 3=refund, 4=refund + failed send
  event LogResult(address player, uint result, uint rollUnder, uint profit, uint tokensBetted, bool won);

  // Logs owner transfers
  event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);

  // Logs changes in maximum profit
  event MaxProfitChanged(uint _oldMaxProfit, uint _newMaxProfit);

  // Logs current contract balance
  event CurrentContractBalance(uint _tokens);
  
  constructor (address zthtknaddr, address zthbankrolladdr) public {
    // Owner is deployer
    owner = msg.sender;

    // Initialize the ZTH contract and bankroll interfaces
    ZTHTKN = ZTHInterface(zthtknaddr);
    ZTHTKNADDR = zthtknaddr;

    // Set the bankroll
    ZethrBankroll = zthbankrolladdr;

    // Init 990 = 99% (1% houseEdge)
    houseEdge = 990;

    // The maximum profit from each bet is 10% of the contract balance.
    ownerSetMaxProfitAsPercentOfHouse(10000);

    // Init min bet (1 ZTH)
    ownerSetMinBet(1e18);

    // Allow &#39;unlimited&#39; token transfer by the bankroll
    ZTHTKN.approve(zthbankrolladdr, MAX_INT);
  }

  function() public payable {} // receive zethr dividends

  // Returns a random number using a specified block number
  // Always use a FUTURE block number.
  function maxRandom(uint blockn, address entropy) public view returns (uint256 randomNumber) {
    return uint256(keccak256(
        abi.encodePacked(
        blockhash(blockn),
        entropy)
      ));
  }

  // Random helper
  function random(uint256 upper, uint256 blockn, address entropy) internal view returns (uint256 randomNumber) {
    return maxRandom(blockn, entropy) % upper;
  }

  // Calculate the maximum potential profit
  function calculateProfit(uint _initBet, uint _roll)
    private
    view
    returns (uint)
  {
    return ((((_initBet * (101 - (_roll.sub(1)))) / (_roll.sub(1)) + _initBet)) * houseEdge / houseEdgeDivisor) - _initBet;
  }

  // I present a struct which takes only 20k gas
  struct playerRoll{
    uint200 tokenValue; // Token value in uint 
    uint48 blockn;      // Block number 48 bits 
    uint8 rollUnder;    // Roll under 8 bits
  }

  // Mapping because a player can do one roll at a time
  mapping(address => playerRoll) public playerRolls;

  function _playerRollDice(uint _rollUnder, TKN _tkn) private
    gameIsActive
    betIsValid(_tkn.value, _rollUnder)
  {
    require(_tkn.value < ((2 ** 200) - 1));   // Smaller than the storage of 1 uint200;
    require(block.number < ((2 ** 48) - 1));  // Current block number smaller than storage of 1 uint48

    // Note that msg.sender is the Token Contract Address
    // and "_from" is the sender of the tokens

    // Check that this is a ZTH token transfer
    require(_zthToken(msg.sender));

    playerRoll memory roll = playerRolls[_tkn.sender];

    // Cannot bet twice in one block 
    require(block.number != roll.blockn);

    // If there exists a roll, finish it
    if (roll.blockn != 0) {
      _finishBet(false, _tkn.sender);
    }

    // Set struct block number, token value, and rollUnder values
    roll.blockn = uint40(block.number);
    roll.tokenValue = uint200(_tkn.value);
    roll.rollUnder = uint8(_rollUnder);

    // Store the roll struct - 20k gas.
    playerRolls[_tkn.sender] = roll;

    // Provides accurate numbers for web3 and allows for manual refunds
    emit LogBet(_tkn.sender, _tkn.value, _rollUnder);
                 
    // Increment total number of bets
    totalBets += 1;

    // Total wagered
    totalZTHWagered += _tkn.value;
  }

  // Finished the current bet of a player, if they have one
  function finishBet() public
    gameIsActive
  {
    _finishBet(true, msg.sender);
  }

  /*
   * Pay winner, update contract balance
   * to calculate new max bet, and send reward.
   */
  function _finishBet(bool delete_it, address target) private {
    playerRoll memory roll = playerRolls[target];
    require(roll.tokenValue > 0); // No re-entracy

    // If the block is more than 255 blocks old, we can&#39;t get the result
    // Also, if the result has already happened, fail as well
    uint result;
    if (block.number - roll.blockn > 255) {
      result = 1000; // Cant win 
    } else {
      // Grab the result - random based ONLY on a past block (future when submitted)
      result = random(100, roll.blockn, target) + 1;
    }

    uint rollUnder = roll.rollUnder;

    if (result < rollUnder) {
      // Player has won!

      // Safely map player profit
      uint profit = calculateProfit(roll.tokenValue, rollUnder);

      // Safely reduce contract balance by player profit
      contractBalance = contractBalance.sub(profit);

      emit LogResult(target, result, rollUnder, profit, roll.tokenValue, true);

      // Update maximum profit
      setMaxProfit();

      if (delete_it){
        // Prevent re-entracy memes
        delete playerRolls[target];
      }

      // Transfer profit plus original bet
      ZTHTKN.transfer(target, profit + roll.tokenValue);

    } else {
      /*
      * Player has lost
      * Update contract balance to calculate new max bet
      */
      emit LogResult(target, result, rollUnder, profit, roll.tokenValue, false);

      /*
      *  Safely adjust contractBalance
      *  SetMaxProfit
      */
      contractBalance = contractBalance.add(roll.tokenValue);

      // No need to actually delete player roll here since player ALWAYS loses 
      // Saves gas on next buy 

      // Update maximum profit
      setMaxProfit();
    }
  }

  // TKN struct
  struct TKN {address sender; uint value;}

  // Token fallback to bet or deposit from bankroll
  function tokenFallback(address _from, uint _value, bytes _data) public returns (bool) {
    if (_from == ZethrBankroll) {
      // Update the contract balance
      contractBalance = contractBalance.add(_value);

      // Update the maximum profit
      uint oldMaxProfit = maxProfit;
      setMaxProfit();

      emit MaxProfitChanged(oldMaxProfit, maxProfit);
      return true;

    } else {
      TKN memory _tkn;
      _tkn.sender = _from;
      _tkn.value = _value;
      uint chosenNumber = uint(_data[0]);
      _playerRollDice(chosenNumber, _tkn);
    }

    return true;
  }

  /*
  * Sets max profit
  */
  function setMaxProfit() internal {
    emit CurrentContractBalance(contractBalance);
    maxProfit = (contractBalance * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }

  // Only owner adjust contract balance variable (only used for max profit calc)
  function ownerUpdateContractBalance(uint newContractBalance) public
  onlyOwner
  {
    contractBalance = newContractBalance;
  }

  // Only owner address can set maxProfitAsPercentOfHouse
  function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
  onlyOwner
  {
    // Restricts each bet to a maximum profit of 20% contractBalance
    require(newMaxProfitAsPercent <= 200000);
    maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
    setMaxProfit();
  }

  // Only owner address can set minBet
  function ownerSetMinBet(uint newMinimumBet) public
  onlyOwner
  {
    minBet = newMinimumBet;
  }

  // Only owner address can transfer ZTH
  function ownerTransferZTH(address sendTo, uint amount) public
  onlyOwner
  {
    // Safely update contract balance when sending out funds
    contractBalance = contractBalance.sub(amount);

    // update max profit
    setMaxProfit();
    require(ZTHTKN.transfer(sendTo, amount));
    emit LogOwnerTransfer(sendTo, amount);
  }

  // Only owner address can set emergency pause #1
  function ownerPauseGame(bool newStatus) public
  onlyOwner
  {
    gamePaused = newStatus;
  }

  // Only owner address can set bankroll address
  function ownerSetBankroll(address newBankroll) public
  onlyOwner
  {
    ZTHTKN.approve(ZethrBankroll, 0);
    ZethrBankroll = newBankroll;
    ZTHTKN.approve(newBankroll, MAX_INT);
  }

  // Only owner address can set owner address
  function ownerChangeOwner(address newOwner) public
  onlyOwner
  {
    owner = newOwner;
  }

  // Only owner address can selfdestruct - emergency
  function ownerkill() public
  onlyOwner
  {
    ZTHTKN.transfer(owner, contractBalance);
    selfdestruct(owner);
  }
  
  function dumpdivs() public{
      ZethrBankroll.transfer(address(this).balance);
  }

  function _zthToken(address _tokenContract) private view returns (bool) {
    return _tokenContract == ZTHTKNADDR;
    // Is this the ZTH token contract?
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
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}