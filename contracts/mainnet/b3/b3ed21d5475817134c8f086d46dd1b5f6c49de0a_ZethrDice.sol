/*
  Zethr | https://zethr.io
  (c) Copyright 2018 | All Rights Reserved
  This smart contract was developed by the Zethr Dev Team and its source code remains property of the Zethr Project.
*/

pragma solidity ^0.4.24;

// File: contracts/Libraries/SafeMath.sol

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/Libraries/ZethrTierLibrary.sol

library ZethrTierLibrary {
  uint constant internal magnitude = 2 ** 64;

  // Gets the tier (1-7) of the divs sent based off of average dividend rate
  // This is an index used to call into the correct sub-bankroll to withdraw tokens
  function getTier(uint divRate) internal pure returns (uint8) {

    // Divide the average dividned rate by magnitude
    // Remainder doesn&#39;t matter because of the below logic
    uint actualDiv = divRate / magnitude;
    if (actualDiv >= 30) {
      return 6;
    } else if (actualDiv >= 25) {
      return 5;
    } else if (actualDiv >= 20) {
      return 4;
    } else if (actualDiv >= 15) {
      return 3;
    } else if (actualDiv >= 10) {
      return 2;
    } else if (actualDiv >= 5) {
      return 1;
    } else if (actualDiv >= 2) {
      return 0;
    } else {
      // Impossible
      revert();
    }
  }

  function getDivRate(uint _tier)
  internal pure
  returns (uint8)
  {
    if (_tier == 0) {
      return 2;
    } else if (_tier == 1) {
      return 5;
    } else if (_tier == 2) {
      return 10;
    } else if (_tier == 3) {
      return 15;
    } else if (_tier == 4) {
      return 20;
    } else if (_tier == 5) {
      return 25;
    } else if (_tier == 6) {
      return 33;
    } else {
      revert();
    }
  }
}

// File: contracts/ERC/ERC223Receiving.sol

contract ERC223Receiving {
  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

// File: contracts/ZethrMultiSigWallet.sol

/* Zethr MultisigWallet
 *
 * Standard multisig wallet
 * Holds the bankroll ETH, as well as the bankroll 33% ZTH tokens.
*/ 
contract ZethrMultiSigWallet is ERC223Receiving {
  using SafeMath for uint;

  /*=================================
  =              EVENTS            =
  =================================*/

  event Confirmation(address indexed sender, uint indexed transactionId);
  event Revocation(address indexed sender, uint indexed transactionId);
  event Submission(uint indexed transactionId);
  event Execution(uint indexed transactionId);
  event ExecutionFailure(uint indexed transactionId);
  event Deposit(address indexed sender, uint value);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event WhiteListAddition(address indexed contractAddress);
  event WhiteListRemoval(address indexed contractAddress);
  event RequirementChange(uint required);
  event BankrollInvest(uint amountReceived);

  /*=================================
  =             VARIABLES           =
  =================================*/

  mapping (uint => Transaction) public transactions;
  mapping (uint => mapping (address => bool)) public confirmations;
  mapping (address => bool) public isOwner;
  address[] public owners;
  uint public required;
  uint public transactionCount;
  bool internal reEntered = false;
  uint constant public MAX_OWNER_COUNT = 15;

  /*=================================
  =         CUSTOM CONSTRUCTS       =
  =================================*/

  struct Transaction {
    address destination;
    uint value;
    bytes data;
    bool executed;
  }

  struct TKN {
    address sender;
    uint value;
  }

  /*=================================
  =            MODIFIERS            =
  =================================*/

  modifier onlyWallet() {
    if (msg.sender != address(this))
      revert();
    _;
  }

  modifier isAnOwner() {
    address caller = msg.sender;
    if (isOwner[caller])
      _;
    else
      revert();
  }

  modifier ownerDoesNotExist(address owner) {
    if (isOwner[owner]) 
      revert();
      _;
  }

  modifier ownerExists(address owner) {
    if (!isOwner[owner])
      revert();
    _;
  }

  modifier transactionExists(uint transactionId) {
    if (transactions[transactionId].destination == 0)
      revert();
    _;
  }

  modifier confirmed(uint transactionId, address owner) {
    if (!confirmations[transactionId][owner])
      revert();
    _;
  }

  modifier notConfirmed(uint transactionId, address owner) {
    if (confirmations[transactionId][owner])
      revert();
    _;
  }

  modifier notExecuted(uint transactionId) {
    if (transactions[transactionId].executed)
      revert();
    _;
  }

  modifier notNull(address _address) {
    if (_address == 0)
      revert();
    _;
  }

  modifier validRequirement(uint ownerCount, uint _required) {
    if ( ownerCount > MAX_OWNER_COUNT
      || _required > ownerCount
      || _required == 0
      || ownerCount == 0)
      revert();
    _;
  }


  /*=================================
  =         PUBLIC FUNCTIONS        =
  =================================*/

  /// @dev Contract constructor sets initial owners and required number of confirmations.
  /// @param _owners List of initial owners.
  /// @param _required Number of required confirmations.
  constructor (address[] _owners, uint _required)
    public
    validRequirement(_owners.length, _required)
  {
    // Add owners
    for (uint i=0; i<_owners.length; i++) {
      if (isOwner[_owners[i]] || _owners[i] == 0)
        revert();
      isOwner[_owners[i]] = true;
    }

    // Set owners
    owners = _owners;

    // Set required
    required = _required;
  }

  /** Testing only.
  function exitAll()
    public
  {
    uint tokenBalance = ZTHTKN.balanceOf(address(this));
    ZTHTKN.sell(tokenBalance - 1e18);
    ZTHTKN.sell(1e18);
    ZTHTKN.withdraw(address(0x0));
  }
  **/

  /// @dev Fallback function allows Ether to be deposited.
  function()
    public
    payable
  {

  }
    
  /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
  /// @param owner Address of new owner.
  function addOwner(address owner)
    public
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, required)
  {
    isOwner[owner] = true;
    owners.push(owner);
    emit OwnerAddition(owner);
  }

  /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
  /// @param owner Address of owner.
  function removeOwner(address owner)
    public
    onlyWallet
    ownerExists(owner)
    validRequirement(owners.length, required)
  {
    isOwner[owner] = false;
    for (uint i=0; i<owners.length - 1; i++)
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        break;
      }

    owners.length -= 1;
    if (required > owners.length)
      changeRequirement(owners.length);
    emit OwnerRemoval(owner);
  }

  /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
  /// @param owner Address of owner to be replaced.
  /// @param owner Address of new owner.
  function replaceOwner(address owner, address newOwner)
    public
    onlyWallet
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
  {
    for (uint i=0; i<owners.length; i++)
      if (owners[i] == owner) {
        owners[i] = newOwner;
        break;
      }

    isOwner[owner] = false;
    isOwner[newOwner] = true;
    emit OwnerRemoval(owner);
    emit OwnerAddition(newOwner);
  }

  /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
  /// @param _required Number of required confirmations.
  function changeRequirement(uint _required)
    public
    onlyWallet
    validRequirement(owners.length, _required)
  {
    required = _required;
    emit RequirementChange(_required);
  }

  /// @dev Allows an owner to submit and confirm a transaction.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @return Returns transaction ID.
  function submitTransaction(address destination, uint value, bytes data)
    public
    returns (uint transactionId)
  {
    transactionId = addTransaction(destination, value, data);
    confirmTransaction(transactionId);
  }

  /// @dev Allows an owner to confirm a transaction.
  /// @param transactionId Transaction ID.
  function confirmTransaction(uint transactionId)
    public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender)
  {
    confirmations[transactionId][msg.sender] = true;
    emit Confirmation(msg.sender, transactionId);
    executeTransaction(transactionId);
  }

  /// @dev Allows an owner to revoke a confirmation for a transaction.
  /// @param transactionId Transaction ID.
  function revokeConfirmation(uint transactionId)
    public
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
  {
    confirmations[transactionId][msg.sender] = false;
    emit Revocation(msg.sender, transactionId);
  }

  /// @dev Allows anyone to execute a confirmed transaction.
  /// @param transactionId Transaction ID.
  function executeTransaction(uint transactionId)
    public
    notExecuted(transactionId)
  {
    if (isConfirmed(transactionId)) {
      Transaction storage txToExecute = transactions[transactionId];
      txToExecute.executed = true;
      if (txToExecute.destination.call.value(txToExecute.value)(txToExecute.data))
        emit Execution(transactionId);
      else {
        emit ExecutionFailure(transactionId);
        txToExecute.executed = false;
      }
    }
  }

  /// @dev Returns the confirmation status of a transaction.
  /// @param transactionId Transaction ID.
  /// @return Confirmation status.
  function isConfirmed(uint transactionId)
    public
    constant
    returns (bool)
  {
    uint count = 0;
    for (uint i=0; i<owners.length; i++) {
      if (confirmations[transactionId][owners[i]])
        count += 1;
      if (count == required)
        return true;
    }
  }

  /*=================================
  =        OPERATOR FUNCTIONS       =
  =================================*/

  /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @return Returns transaction ID.
  function addTransaction(address destination, uint value, bytes data)
    internal
    notNull(destination)
    returns (uint transactionId)
  {
    transactionId = transactionCount;

    transactions[transactionId] = Transaction({
        destination: destination,
        value: value,
        data: data,
        executed: false
    });

    transactionCount += 1;
    emit Submission(transactionId);
  }

  /*
   * Web3 call functions
   */
  /// @dev Returns number of confirmations of a transaction.
  /// @param transactionId Transaction ID.
  /// @return Number of confirmations.
  function getConfirmationCount(uint transactionId)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<owners.length; i++)
      if (confirmations[transactionId][owners[i]])
        count += 1;
  }

  /// @dev Returns total number of transactions after filers are applied.
  /// @param pending Include pending transactions.
  /// @param executed Include executed transactions.
  /// @return Total number of transactions after filters are applied.
  function getTransactionCount(bool pending, bool executed)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<transactionCount; i++)
      if (pending && !transactions[i].executed || executed && transactions[i].executed)
        count += 1;
  }

  /// @dev Returns list of owners.
  /// @return List of owner addresses.
  function getOwners()
    public
    constant
    returns (address[])
  {
    return owners;
  }

  /// @dev Returns array with owner addresses, which confirmed transaction.
  /// @param transactionId Transaction ID.
  /// @return Returns array of owner addresses.
  function getConfirmations(uint transactionId)
    public
    constant
    returns (address[] _confirmations)
  {
    address[] memory confirmationsTemp = new address[](owners.length);
    uint count = 0;
    uint i;
    for (i=0; i<owners.length; i++)
      if (confirmations[transactionId][owners[i]]) {
        confirmationsTemp[count] = owners[i];
        count += 1;
      }

      _confirmations = new address[](count);

      for (i=0; i<count; i++)
        _confirmations[i] = confirmationsTemp[i];
  }

  /// @dev Returns list of transaction IDs in defined range.
  /// @param from Index start position of transaction array.
  /// @param to Index end position of transaction array.
  /// @param pending Include pending transactions.
  /// @param executed Include executed transactions.
  /// @return Returns array of transaction IDs.
  function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    constant
    returns (uint[] _transactionIds)
  {
    uint[] memory transactionIdsTemp = new uint[](transactionCount);
    uint count = 0;
    uint i;

    for (i=0; i<transactionCount; i++)
      if (pending && !transactions[i].executed || executed && transactions[i].executed) {
        transactionIdsTemp[count] = i;
        count += 1;
      }

      _transactionIds = new uint[](to - from);

    for (i=from; i<to; i++)
      _transactionIds[i - from] = transactionIdsTemp[i];
  }

  function tokenFallback(address /*_from*/, uint /*_amountOfTokens*/, bytes /*_data*/)
  public
  returns (bool)
  {
    return true;
  }
}

// File: contracts/Bankroll/Interfaces/ZethrTokenBankrollInterface.sol

// Zethr token bankroll function prototypes
contract ZethrTokenBankrollInterface is ERC223Receiving {
  uint public jackpotBalance;
  
  function getMaxProfit(address) public view returns (uint);
  function gameTokenResolution(uint _toWinnerAmount, address _winnerAddress, uint _toJackpotAmount, address _jackpotAddress, uint _originalBetSize) external;
  function payJackpotToWinner(address _winnerAddress, uint payoutDivisor) public;
}

// File: contracts/Bankroll/Interfaces/ZethrBankrollControllerInterface.sol

contract ZethrBankrollControllerInterface is ERC223Receiving {
  address public jackpotAddress;

  ZethrTokenBankrollInterface[7] public tokenBankrolls; 
  
  ZethrMultiSigWallet public multiSigWallet;

  mapping(address => bool) public validGameAddresses;

  function gamePayoutResolver(address _resolver, uint _tokenAmount) public;

  function isTokenBankroll(address _address) public view returns (bool);

  function getTokenBankrollAddressFromTier(uint8 _tier) public view returns (address);

  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

// File: contracts/Bankroll/ZethrGame.sol

/* Zethr Game Interface
 *
 * Contains the necessary functions to integrate with
 * the Zethr Token bankrolls & the Zethr game ecosystem.
 *
 * Token Bankroll Functions:
 *  - execute
 *
 * Player Functions:
 *  - finish
 *
 * Bankroll Controller / Owner Functions:
 *  - pauseGame
 *  - resumeGame
 *  - set resolver percentage
 *  - set controller address
 *
 * Player/Token Bankroll Functions:
 *  - resolvePendingBets
*/
contract ZethrGame {
  using SafeMath for uint;
  using SafeMath for uint56;

  // Default events:
  event Result (address player, uint amountWagered, int amountOffset);
  event Wager (address player, uint amount, bytes data);

  // Queue of pending/unresolved bets
  address[] pendingBetsQueue;
  uint queueHead = 0;
  uint queueTail = 0;

  // Store each player&#39;s latest bet via mapping
  mapping(address => BetBase) bets;

  // Bet structures must start with this layout
  struct BetBase {
    // Must contain these in this order
    uint56 tokenValue;    // Multiply by 1e14 to get tokens
    uint48 blockNumber;
    uint8 tier;
    // Game specific structures can add more after this
  }

  // Mapping of addresses to their *position* in the queue
  // Zero = they aren&#39;t in the queue
  mapping(address => uint) pendingBetsMapping;

  // Holds the bankroll controller info
  ZethrBankrollControllerInterface controller;

  // Is the game paused?
  bool paused;

  // Minimum bet should always be >= 1
  uint minBet = 1e18;

  // Percentage that a resolver gets when he resolves bets for the house
  uint resolverPercentage;

  // Every game has a name
  string gameName;

  constructor (address _controllerAddress, uint _resolverPercentage, string _name) public {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
    resolverPercentage = _resolverPercentage;
    gameName = _name;
  }

  /** @dev Gets the max profit of this game as decided by the token bankroll
    * @return uint The maximum profit
    */
  function getMaxProfit()
  public view
  returns (uint)
  {
    return ZethrTokenBankrollInterface(msg.sender).getMaxProfit(address(this));
  }

  /** @dev Pauses the game, preventing anyone from placing bets
    */
  function ownerPauseGame()
  public
  ownerOnly
  {
    paused = true;
  }

  /** @dev Resumes the game, allowing bets
    */
  function ownerResumeGame()
  public
  ownerOnly
  {
    paused = false;
  }

  /** @dev Sets the percentage of the bets that a resolver gets when resolving tokens.
    * @param _percentage The percentage as x/1,000,000 that the resolver gets
    */
  function ownerSetResolverPercentage(uint _percentage)
  public
  ownerOnly
  {
    require(_percentage <= 1000000);
    resolverPercentage = _percentage;
  }

  /** @dev Sets the address of the game controller
    * @param _controllerAddress The new address of the controller
    */
  function ownerSetControllerAddress(address _controllerAddress)
  public
  ownerOnly
  {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
  }

  // Every game should have a name
  /** @dev Sets the name of the game
    * @param _name The name of the game
    */
  function ownerSetGameName(string _name)
  ownerOnly
  public
  {
    gameName = _name;
  }

  /** @dev Gets the game name
    * @return The name of the game
    */
  function getGameName()
  public view
  returns (string)
  {
    return gameName;
  }

  /** @dev Resolve expired bets in the queue. Gives a percentage of the house edge to the resolver as ZTH
    * @param _numToResolve The number of bets to resolve.
    * @return tokensEarned The number of tokens earned
    * @return queueHead The new head of the queue
    */
  function resolveExpiredBets(uint _numToResolve)
  public
  returns (uint tokensEarned_, uint queueHead_)
  {
    uint mQueue = queueHead;
    uint head;
    uint tail = (mQueue + _numToResolve) > pendingBetsQueue.length ? pendingBetsQueue.length : (mQueue + _numToResolve);
    uint tokensEarned = 0;

    for (head = mQueue; head < tail; head++) {
      // Check the head of the queue to see if there is a resolvable bet
      // This means the bet at the queue head is older than 255 blocks AND is not 0
      // (However, if the address at the head is null, skip it, it&#39;s already been resolved)
      if (pendingBetsQueue[head] == address(0x0)) {
        continue;
      }

      if (bets[pendingBetsQueue[head]].blockNumber != 0 && block.number > 256 + bets[pendingBetsQueue[head]].blockNumber) {
        // Resolve the bet
        // finishBetfrom returns the *player* profit
        // this will be negative if the player lost and the house won
        // so flip it to get the house profit, if any
        int sum = - finishBetFrom(pendingBetsQueue[head]);

        // Tokens earned is a percentage of the loss
        if (sum > 0) {
          tokensEarned += (uint(sum).mul(resolverPercentage)).div(1000000);
        }

        // Queue-tail is always the "next" open spot, so queue head and tail will never overlap
      } else {
        // If we can&#39;t resolve a bet, stop going down the queue
        break;
      }
    }

    queueHead = head;

    // Send the earned tokens to the resolver
    if (tokensEarned >= 1e14) {
      controller.gamePayoutResolver(msg.sender, tokensEarned);
    }

    return (tokensEarned, head);
  }

  /** @dev Finishes the bet of the sender, if it exists.
    * @return int The total profit (positive or negative) earned by the sender
    */
  function finishBet()
  public
  hasNotBetThisBlock(msg.sender)
  returns (int)
  {
    return finishBetFrom(msg.sender);
  }

  /** @dev Resturns a random number
    * @param _blockn The block number to base the random number off of
    * @param _entropy Data to use in the random generation
    * @param _index Data to use in the random generation
    * @return randomNumber The random number to return
    */
  function maxRandom(uint _blockn, address _entropy, uint _index)
  private view
  returns (uint256 randomNumber)
  {
    return uint256(keccak256(
        abi.encodePacked(
          blockhash(_blockn),
          _entropy,
          _index
        )));
  }

  /** @dev Returns a random number
    * @param _upper The upper end of the range, exclusive
    * @param _blockn The block number to use for the random number
    * @param _entropy An address to be used for entropy
    * @param _index A number to get the next random number
    * @return randomNumber The random number
    */
  function random(uint256 _upper, uint256 _blockn, address _entropy, uint _index)
  internal view
  returns (uint256 randomNumber)
  {
    return maxRandom(_blockn, _entropy, _index) % _upper;
  }

  // Prevents the user from placing two bets in one block
  modifier hasNotBetThisBlock(address _sender)
  {
    require(bets[_sender].blockNumber != block.number);
    _;
  }

  // Requires that msg.sender is one of the token bankrolls
  modifier bankrollOnly {
    require(controller.isTokenBankroll(msg.sender));
    _;
  }

  // Requires that the game is not paused
  modifier isNotPaused {
    require(!paused);
    _;
  }

  // Requires that the bet given has max profit low enough
  modifier betIsValid(uint _betSize, uint _tier, bytes _data) {
    uint divRate = ZethrTierLibrary.getDivRate(_tier);
    require(isBetValid(_betSize, divRate, _data));
    _;
  }

  // Only an owner can call this method (controller is always an owner)
  modifier ownerOnly()
  {
    require(msg.sender == address(controller) || controller.multiSigWallet().isOwner(msg.sender));
    _;
  }

  /** @dev Places a bet. Callable only by token bankrolls
    * @param _player The player that is placing the bet
    * @param _tokenCount The total number of tokens bet
    * @param _divRate The dividend rate of the player
    * @param _data The game-specific data, encoded in bytes-form
    */
  function execute(address _player, uint _tokenCount, uint _divRate, bytes _data) public;

  /** @dev Resolves the bet of the supplied player.
    * @param _playerAddress The address of the player whos bet we are resolving
    * @return int The total profit the player earned, positive or negative
    */
  function finishBetFrom(address _playerAddress) internal returns (int);

  /** @dev Determines if a supplied bet is valid
    * @param _tokenCount The total number of tokens bet
    * @param _divRate The dividend rate of the bet
    * @param _data The game-specific bet data
    * @return bool Whether or not the bet is valid
    */
  function isBetValid(uint _tokenCount, uint _divRate, bytes _data) public view returns (bool);
}

// File: contracts/Games/ZethrDice.sol

/* The actual game contract.
 *
 * This contract contains the actual game logic,
 * including placing bets (execute), resolving bets,
 * and resolving expired bets.
*/
contract ZethrDice is ZethrGame {

  /****************************
   * GAME SPECIFIC
   ****************************/

  // Slots-specific bet structure
  struct Bet {
    // Must contain these in this order
    uint56 tokenValue;
    uint48 blockNumber;
    uint8 tier;
    // Game specific
    uint8 rollUnder;
    uint8 numRolls;
  }

  /****************************
   * FIELDS
   ****************************/

  uint constant private MAX_INT = 2 ** 256 - 1;
  uint constant public maxProfitDivisor = 1000000;
  uint constant public maxNumber = 100;
  uint constant public minNumber = 2;
  uint constant public houseEdgeDivisor = 1000;
  uint constant public houseEdge = 990;
  uint constant public minBet = 1e18;

  /****************************
   * CONSTRUCTOR
   ****************************/

  constructor (address _controllerAddress, uint _resolverPercentage, string _name)
  ZethrGame(_controllerAddress, _resolverPercentage, _name)
  public
  {
  }

  /****************************
   * USER METHODS
   ****************************/

  /** @dev Retrieve the results of the last roll of a player, for web3 calls.
    * @param _playerAddress The address of the player
    */
  function getLastRollOutput(address _playerAddress)
  public view
  returns (uint winAmount, uint lossAmount, uint[] memory output)
  {
    // Cast to Bet and read from storage
    Bet storage playerBetInStorage = getBet(_playerAddress);
    Bet memory playerBet = playerBetInStorage;

    // Safety check
    require(playerBet.blockNumber != 0);

    (winAmount, lossAmount, output) = getRollOutput(playerBet.blockNumber, playerBet.rollUnder, playerBet.numRolls, playerBet.tokenValue.mul(1e14), _playerAddress);

    return (winAmount, lossAmount, output);
  }

    event RollResult(
        uint    _blockNumber,
        address _target,
        uint    _rollUnder,
        uint    _numRolls,
        uint    _tokenValue,
        uint    _winAmount,
        uint    _lossAmount,
        uint[]  _output
    );

  /** @dev Retrieve the results of the spin, for web3 calls.
    * @param _blockNumber The block number of the spin
    * @param _numRolls The number of rolls of this bet
    * @param _tokenValue The total number of tokens bet
    * @param _target The address of the better
    * @return winAmount The total number of tokens won
    * @return lossAmount The total number of tokens lost
    * @return output An array of all of the results of a multispin
    */
  function getRollOutput(uint _blockNumber, uint8 _rollUnder, uint8 _numRolls, uint _tokenValue, address _target)
  public
  returns (uint winAmount, uint lossAmount, uint[] memory output)
  {
    output = new uint[](_numRolls);
    // Where the result sections start and stop

    // If current block for the first spin is older than 255 blocks, ALL rolls are losses
    if (block.number - _blockNumber > 255) {
      lossAmount = _tokenValue.mul(_numRolls);
    } else {
      uint profit = calculateProfit(_tokenValue, _rollUnder);

      for (uint i = 0; i < _numRolls; i++) {
        // Store the output
        output[i] = random(100, _blockNumber, _target, i) + 1;

        if (output[i] < _rollUnder) {
          // Player has won!
          winAmount += profit + _tokenValue;
        } else {
          lossAmount += _tokenValue;
        }
      }
    }
    emit RollResult(_blockNumber, _target, _rollUnder, _numRolls, _tokenValue, winAmount, lossAmount, output);
    return (winAmount, lossAmount, output);
  }

  /** @dev Retrieve the results of the roll, for contract calls.
    * @param _blockNumber The block number of the roll
    * @param _numRolls The number of rolls of this bet
    * @param _rollUnder The number the roll has to be under to win
    * @param _tokenValue The total number of tokens bet
    * @param _target The address of the better
    * @return winAmount The total number of tokens won
    * @return lossAmount The total number of tokens lost
    */
  function getRollResults(uint _blockNumber, uint8 _rollUnder, uint8 _numRolls, uint _tokenValue, address _target)
  public
  returns (uint winAmount, uint lossAmount)
  {
    // If current block for the first spin is older than 255 blocks, ALL rolls are losses
    if (block.number - _blockNumber > 255) {
      lossAmount = _tokenValue.mul(_numRolls);
    } else {
      uint profit = calculateProfit(_tokenValue, _rollUnder);

      for (uint i = 0; i < _numRolls; i++) {
        // Store the output
        uint output = random(100, _blockNumber, _target, i) + 1;

        if (output < _rollUnder) {
          winAmount += profit + _tokenValue;
        } else {
          lossAmount += _tokenValue;
        }
      }
    }

    return (winAmount, lossAmount);
  }

  /****************************
   * OWNER METHODS
   ****************************/

  /****************************
   * INTERNALS
   ****************************/

  // Calculate the maximum potential profit
  function calculateProfit(uint _initBet, uint _roll)
  internal view
  returns (uint)
  {
    return ((((_initBet * (100 - (_roll.sub(1)))) / (_roll.sub(1)) + _initBet)) * houseEdge / houseEdgeDivisor) - _initBet;
  }

  /** @dev Returs the bet struct of a player
    * @param _playerAddress The address of the player
    * @return Bet The bet of the player
    */
  function getBet(address _playerAddress)
  internal view
  returns (Bet storage)
  {
    // Cast BetBase to Bet
    BetBase storage betBase = bets[_playerAddress];

    Bet storage playerBet;
    assembly {
    // tmp is pushed onto stack and points to betBase slot in storage
      let tmp := betBase_slot

    // swap1 swaps tmp and playerBet pointers
      swap1
    }
    // tmp is popped off the stack

    // playerBet now points to betBase
    return playerBet;
  }

  /****************************
   * OVERRIDDEN METHODS
   ****************************/

  /** @dev Resolves the bet of the supplied player.
    * @param _playerAddress The address of the player whos bet we are resolving
    * @return totalProfit The total profit the player earned, positive or negative
    */
  function finishBetFrom(address _playerAddress)
  internal
  returns (int /*totalProfit*/)
  {
    // Memory vars to hold data as we compute it
    uint winAmount;
    uint lossAmount;

    // Cast to Bet and read from storage
    Bet storage playerBetInStorage = getBet(_playerAddress);
    Bet memory playerBet = playerBetInStorage;

    // Safety check
    require(playerBet.blockNumber != 0);
    playerBetInStorage.blockNumber = 0;

    // Iterate over the number of rolls and calculate totals:
    //  - player win amount
    //  - bankroll win amount
    (winAmount, lossAmount) = getRollResults(playerBet.blockNumber, playerBet.rollUnder, playerBet.numRolls, playerBet.tokenValue.mul(1e14), _playerAddress);

    // Figure out the token bankroll address
    address tokenBankrollAddress = controller.getTokenBankrollAddressFromTier(playerBet.tier);
    ZethrTokenBankrollInterface bankroll = ZethrTokenBankrollInterface(tokenBankrollAddress);

    // Call into the bankroll to do some token accounting
    bankroll.gameTokenResolution(winAmount, _playerAddress, 0, address(0x0), playerBet.tokenValue.mul(1e14).mul(playerBet.numRolls));

    // Grab the position of the player in the pending bets queue
    uint index = pendingBetsMapping[_playerAddress];

    // Remove the player from the pending bets queue by setting the address to 0x0
    pendingBetsQueue[index] = address(0x0);

    // Delete the player&#39;s bet by setting the mapping to zero
    pendingBetsMapping[_playerAddress] = 0;

    emit Result(_playerAddress, playerBet.tokenValue.mul(1e14), int(winAmount) - int(lossAmount));

    // Return all bet results + total *player* profit
    return (int(winAmount) - int(lossAmount));
  }

  /** @dev Places a bet. Callable only by token bankrolls
    * @param _player The player that is placing the bet
    * @param _tokenCount The total number of tokens bet
    * @param _tier The div rate tier the player falls in
    * @param _data The game-specific data, encoded in bytes-form
    */
  function execute(address _player, uint _tokenCount, uint _tier, bytes _data)
  isNotPaused
  bankrollOnly
  betIsValid(_tokenCount, _tier, _data)
  hasNotBetThisBlock(_player)
  public
  {
    Bet storage playerBet = getBet(_player);

    // Check for a player bet and resolve if necessary
    if (playerBet.blockNumber != 0) {
      finishBetFrom(_player);
    }

    uint8 rolls = uint8(_data[0]);
    uint8 rollUnder = uint8(_data[1]);

    // Set bet information
    playerBet.tokenValue = uint56(_tokenCount.div(rolls).div(1e14));
    playerBet.blockNumber = uint48(block.number);
    playerBet.tier = uint8(_tier);
    playerBet.rollUnder = rollUnder;
    playerBet.numRolls = rolls;

    // Add player to the pending bets queue
    pendingBetsQueue.length ++;
    pendingBetsQueue[queueTail] = _player;
    queueTail++;

    // Add the player&#39;s position in the queue to the pending bets mapping
    pendingBetsMapping[_player] = queueTail - 1;

    // Emit event
    emit Wager(_player, _tokenCount, _data);
  }

  /** @dev Determines if a supplied bet is valid
    * @param _tokenCount The total number of tokens bet
    * @param _data The game-specific bet data
    * @return bool Whether or not the bet is valid
    */
  function isBetValid(uint _tokenCount, uint /*_divRate*/, bytes _data)
  public view
  returns (bool)
  {
    uint8 rollUnder = uint8(_data[1]);

    return (calculateProfit(_tokenCount, rollUnder) < getMaxProfit()
    && _tokenCount >= minBet
    && rollUnder >= minNumber
    && rollUnder <= maxNumber);
  }
}