pragma solidity 0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title Beths base contract
 * @author clemlak (https://www.beths.co)
 * @notice Place bets using Ether, based on the "pari mutuel" principle
 * Only the owner of the contract can create bets, he can also take a cut on every payouts
 * @dev This is the base contract for our dapp, we manage here all the things related to the "house"
 */
contract BethsHouse is Ownable {
  /**
   * @notice Emitted when the house cut percentage is changed
   * @param newHouseCutPercentage The new percentage
   */
  event HouseCutPercentageChanged(uint newHouseCutPercentage);

  /**
   * @notice The percentage taken by the house on every game
   * @dev Can be changed later with the changeHouseCutPercentage() function
   */
  uint public houseCutPercentage = 10;

  /**
   * @notice Changes the house cut percentage
   * @dev To prevent abuses, the new percentage is checked
   * @param newHouseCutPercentage The new house cut percentage
   */
  function changeHouseCutPercentage(uint newHouseCutPercentage) external onlyOwner {
    // This prevents us from being too greedy ;)
    if (newHouseCutPercentage >= 0 && newHouseCutPercentage < 20) {
      houseCutPercentage = newHouseCutPercentage;
      emit HouseCutPercentageChanged(newHouseCutPercentage);
    }
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
 * @title We manage all the things related to our games here
 * @author Clemlak (https://www.beths.co)
 */
contract BethsGame is BethsHouse {
  /**
   * @notice We use the SafeMath library in order to prevent overflow errors
   * @dev Don&#39;t forget to use add(), sub(), ... instead of +, -, ...
   */
  using SafeMath for uint256;

  /**
   * @notice Emitted when a new game is opened
   * @param gameId The id of the corresponding game
   * @param teamA The name of the team A
   * @param teamB The name of the team B
   * @param description A small description of the game
   * @param frozenTimestamp The exact moment when the game will be frozen
   */
  event GameHasOpened(uint gameId, string teamA, string teamB, string description, uint frozenTimestamp);

  /**
   * @notice Emitted when a game is frozen
   * @param gameId The id of the corresponding game
   */
  event GameHasFrozen(uint gameId);

  /**
   * @notice Emitted when a game is closed
   * @param gameId The id of the corresponding game
   * @param result The result of the game (see: enum GameResults)
   */
  event GameHasClosed(uint gameId, GameResults result);

  /**
   * @notice All the different states a game can have (only 1 at a time)
   */
  enum GameStates { Open, Frozen, Closed }

  /**
   * @notice All the possible results (only 1 at a time)
   * @dev All new games are initialized with a NotYet result
   */
  enum GameResults { NotYet, TeamA, Draw, TeamB }

  /**
   * @notice This struct defines what a game is
   */
  struct Game {
    string teamA;
    uint amountToTeamA;
    string teamB;
    uint amountToTeamB;
    uint amountToDraw;
    string description;
    uint frozenTimestamp;
    uint bettorsCount;
    GameResults result;
    GameStates state;
    bool isHouseCutWithdrawn;
  }

  /**
  * @notice We store all our games in an array
  */
  Game[] public games;

  /**
   * @notice This function creates a new game
   * @dev Can only be called externally by the owner
   * @param teamA The name of the team A
   * @param teamB The name of the team B
   * @param description A small description of the game
   * @param frozenTimestamp A timestamp representing when the game will be frozen
   */
  function createNewGame(
    string teamA,
    string teamB,
    string description,
    uint frozenTimestamp
  ) external onlyOwner {
    // We push the new game directly into our array
    uint gameId = games.push(Game(
      teamA, 0, teamB, 0, 0, description, frozenTimestamp, 0, GameResults.NotYet, GameStates.Open, false
    )) - 1;

    emit GameHasOpened(gameId, teamA, teamB, description, frozenTimestamp);
  }

  /**
   * @notice We use this function to froze a game
   * @dev Can only be called externally by the owner
   * @param gameId The id of the corresponding game
   */
  function freezeGame(uint gameId) external onlyOwner whenGameIsOpen(gameId) {
    games[gameId].state = GameStates.Frozen;

    emit GameHasFrozen(gameId);
  }

  /**
   * @notice We use this function to close a game
   * @dev Can only be called by the owner when a game is frozen
   * @param gameId The id of a specific game
   * @param result The result of the game (see: enum GameResults)
   */
  function closeGame(uint gameId, GameResults result) external onlyOwner whenGameIsFrozen(gameId) {
    games[gameId].state = GameStates.Closed;
    games[gameId].result = result;

    emit GameHasClosed(gameId, result);
  }

  /**
   * @notice Returns some basic information about a specific game
   * @dev This function DOES NOT return the bets-related info, the current state or the result of the game
   * @param gameId The id of the corresponding game
   */
  function getGameInfo(uint gameId) public view returns (
    string,
    string,
    string
  ) {
    return (
      games[gameId].teamA,
      games[gameId].teamB,
      games[gameId].description
    );
  }

  /**
   * @notice Returns all the info related to the bets
   * @dev Use other functions for more info
   * @param gameId The id of the corresponding game
   */
  function getGameAmounts(uint gameId) public view returns (
    uint,
    uint,
    uint,
    uint,
    uint
  ) {
    return (
      games[gameId].amountToTeamA,
      games[gameId].amountToDraw,
      games[gameId].amountToTeamB,
      games[gameId].bettorsCount,
      games[gameId].frozenTimestamp
    );
  }

  /**
   * @notice Returns the state of a specific game
   * @dev Use other functions for more info
   * @param gameId The id of the corresponding game
   */
  function getGameState(uint gameId) public view returns (GameStates) {
    return games[gameId].state;
  }

  /**
   * @notice Returns the result of a specific game
   * @dev Use other functions for more info
   * @param gameId The id of the corresponding game
   */
  function getGameResult(uint gameId) public view returns (GameResults) {
    return games[gameId].result;
  }

  /**
   * @notice Returns the total number of games
   */
  function getTotalGames() public view returns (uint) {
    return games.length;
  }

  /**
   * @dev Compare 2 strings and returns true if they are identical
   * This function even work if a string is in memory and the other in storage
   * @param a The first string
   * @param b The second string
   */
  function compareStrings(string a, string b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  /**
   * @dev Prevent to interact if the game is not open
   * @param gameId The id of a specific game
   */
  modifier whenGameIsOpen(uint gameId) {
    require(games[gameId].state == GameStates.Open);
    _;
  }

  /**
   * @dev Prevent to interact if the game is not frozen
   * @param gameId The id of a specific game
   */
  modifier whenGameIsFrozen(uint gameId) {
    require(games[gameId].state == GameStates.Frozen);
    _;
  }

  /**
   * @dev Prevent to interact if the game is not closed
   * @param gameId The id of a specific game
   */
  modifier whenGameIsClosed(uint gameId) {
    require(games[gameId].state == GameStates.Closed);
    _;
  }
}


/**
 * @title We manage all the things related to our bets here
 * @author Clemlak (https://www.beths.co)
 */
contract BethsBet is BethsGame {
  /**
   * @notice Emitted when a new bet is placed
   * @param gameId The name of the corresponding game
   * @param result The result expected by the bettor (see: enum GameResults)
   * @param amount How much the bettor placed
   */
  event NewBetPlaced(uint gameId, GameResults result, uint amount);

  /**
   * @notice The minimum amount needed to place bet (in Wei)
   * @dev Can be changed later by the changeMinimumBetAmount() function
   */
  uint public minimumBetAmount = 1000000000;

  /**
   * @notice This struct defines what a bet is
   */
  struct Bet {
    uint gameId;
    GameResults result;
    uint amount;
    bool isPayoutWithdrawn;
  }

  /**
   * @notice We store all our bets in an array
   */
  Bet[] public bets;

  /**
   * @notice This links bets with bettors
   */
  mapping (uint => address) public betToAddress;

  /**
   * @notice This links the bettor to their bets
   */
  mapping (address => uint[]) public addressToBets;

  /**
   * @notice Changes the minimum amount needed to place a bet
   * @dev The amount is in Wei and must be greater than 0 (can only be changed by the owner)
   * @param newMinimumBetAmount The new amount
   */
  function changeMinimumBetAmount(uint newMinimumBetAmount) external onlyOwner {
    if (newMinimumBetAmount > 0) {
      minimumBetAmount = newMinimumBetAmount;
    }
  }

  /**
   * @notice Place a new bet
   * @dev This function is payable and we&#39;ll use the amount we receive as the bet amount
   * Bets can only be placed while the game is open
   * @param gameId The id of the corresponding game
   * @param result The result expected by the bettor (see enum GameResults)
   */
  function placeNewBet(uint gameId, GameResults result) public whenGameIsOpen(gameId) payable {
    // We check if the bet amount is greater or equal to our minimum
    if (msg.value >= minimumBetAmount) {
      // We push our bet in our main array
      uint betId = bets.push(Bet(gameId, result, msg.value, false)) - 1;

      // We link the bet with the bettor
      betToAddress[betId] = msg.sender;

      // We link the address with their bets
      addressToBets[msg.sender].push(betId);

      // Then we update our game
      games[gameId].bettorsCount = games[gameId].bettorsCount.add(1);

      // And we update the amount bet on the expected result
      if (result == GameResults.TeamA) {
        games[gameId].amountToTeamA = games[gameId].amountToTeamA.add(msg.value);
      } else if (result == GameResults.Draw) {
        games[gameId].amountToDraw = games[gameId].amountToDraw.add(msg.value);
      } else if (result == GameResults.TeamB) {
        games[gameId].amountToTeamB = games[gameId].amountToTeamB.add(msg.value);
      }

      // And finally we emit the corresponding event
      emit NewBetPlaced(gameId, result, msg.value);
    }
  }

  /**
   * @notice Returns an array containing the ids of the bets placed by a specific address
   * @dev This function is meant to be used with the getBetInfo() function
   * @param bettorAddress The address of the bettor
   */
  function getBetsFromAddress(address bettorAddress) public view returns (uint[]) {
    return addressToBets[bettorAddress];
  }

  /**
   * @notice Returns the info of a specific bet
   * @dev This function is meant to be used with the getBetsFromAddress() function
   * @param betId The id of the specific bet
   */
  function getBetInfo(uint betId) public view returns (uint, GameResults, uint, bool) {
    return (bets[betId].gameId, bets[betId].result, bets[betId].amount, bets[betId].isPayoutWithdrawn);
  }
}


/**
 * @title This contract handles all the functions related to the payouts
 * @author Clemlak (https://www.beths.co)
 * @dev This contract is still in progress
 */
contract BethsPayout is BethsBet {
  /**
   * @notice We use this function to withdraw the house cut from a game
   * @dev Can only be called externally by the owner when a game is closed
   * @param gameId The id of a specific game
   */
  function withdrawHouseCutFromGame(uint gameId) external onlyOwner whenGameIsClosed(gameId) {
    // We check if we haven&#39;t already withdrawn the cut
    if (!games[gameId].isHouseCutWithdrawn) {
      games[gameId].isHouseCutWithdrawn = true;
      uint houseCutAmount = calculateHouseCutAmount(gameId);
      owner.transfer(houseCutAmount);
    }
  }

  /**
   * @notice This function is called by a bettor to withdraw his payout
   * @dev This function can only be called externally
   * @param betId The id of a specific bet
   */
  function withdrawPayoutFromBet(uint betId) external whenGameIsClosed(bets[betId].gameId) {
    // We check if the bettor has won
    require(games[bets[betId].gameId].result == bets[betId].result);

    // If he won, but we want to be sure that he didn&#39;t already withdraw his payout
    if (!bets[betId].isPayoutWithdrawn) {
      // Everything seems okay, so now we give the bettor his payout
      uint payout = calculatePotentialPayout(betId);

      // We prevent the bettor to withdraw his payout more than once
      bets[betId].isPayoutWithdrawn = true;

      address bettorAddress = betToAddress[betId];

      // We send the payout
      bettorAddress.transfer(payout);
    }
  }

  /**
   * @notice Returns the "raw" pool amount (including the amount of the house cut)
   * @dev Can be called at any state of a game
   * @param gameId The id of a specific game
   */
  function calculateRawPoolAmount(uint gameId) internal view returns (uint) {
    return games[gameId].amountToDraw.add(games[gameId].amountToTeamA.add(games[gameId].amountToTeamB));
  }

  /**
   * @notice Returns the amount the house will take
   * @dev Can be called at any state of a game
   * @param gameId The id of a specific game
   */
  function calculateHouseCutAmount(uint gameId) internal view returns (uint) {
    uint rawPoolAmount = calculateRawPoolAmount(gameId);
    return houseCutPercentage.mul(rawPoolAmount.div(100));
  }

  /**
   * @notice Returns the total of the pool (minus the house part)
   * @dev This value will be used to calculate the bettors&#39; payouts
   * @param gameId the id of a specific game
   */
  function calculatePoolAmount(uint gameId) internal view returns (uint) {
    uint rawPoolAmount = calculateRawPoolAmount(gameId);
    uint houseCutAmount = calculateHouseCutAmount(gameId);

    return rawPoolAmount.sub(houseCutAmount);
  }

  /**
   * @notice Returns the potential payout from a bet
   * @dev Warning! This function DOES NOT check if the game is open/frozen/closed or if the bettor has won
   * @param betId The id of a specific bet
   */
  function calculatePotentialPayout(uint betId) internal view returns (uint) {
    uint betAmount = bets[betId].amount;

    uint poolAmount = calculatePoolAmount(bets[betId].gameId);

    uint temp = betAmount.mul(poolAmount);

    uint betAmountToWinningTeam = 0;

    if (games[bets[betId].gameId].result == GameResults.TeamA) {
      betAmountToWinningTeam = games[bets[betId].gameId].amountToTeamA;
    } else if (games[bets[betId].gameId].result == GameResults.TeamB) {
      betAmountToWinningTeam = games[bets[betId].gameId].amountToTeamB;
    } else if (games[bets[betId].gameId].result == GameResults.Draw) {
      betAmountToWinningTeam = games[bets[betId].gameId].amountToDraw;
    }

    return temp.div(betAmountToWinningTeam);
  }
}