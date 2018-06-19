pragma solidity ^0.4.21;

contract TwoXJackpot {
  using SafeMath for uint256;
  address public contractOwner;  // Address of the contract creator

  // BuyIn Object, holding information of each Buy In
  // Also used to store information about winners in each game
  struct BuyIn {
    uint256 value;
    address owner;
  }

  // Game Object, holding information of each Game played
  struct Game {
    BuyIn[] buyIns;            // FIFO queue
    address[] winners;         // Jackpot Winners addresses
    uint256[] winnerPayouts;   // Jackpot Winner Payouts
    uint256 gameTotalInvested; // Total Invested in game
    uint256 gameTotalPaidOut;  // Total Paid Out in game
    uint256 gameTotalBacklog;  // Total Amount waiting to payout
    uint256 index;             // The current BuyIn queue index

    mapping (address => uint256) totalInvested; // Total invested for a given address
    mapping (address => uint256) totalValue;    // Total value for a given address
    mapping (address => uint256) totalPaidOut;  // Total paid out for a given address
  }

  mapping (uint256 => Game) public games;  // Map game index to the game
  uint256 public gameIndex;    // The current Game Index

  // Timestamp of the last action.

  // Jackpot
  uint256 public jackpotBalance;        // Total balance of Jackpot (before re-seed deduction)
  address public jackpotLastQualified;  // Last Purchaser, in running for Jackpot claim
  address public jackpotLastWinner;     // Last Winner Address
  uint256 public jackpotLastPayout;     // Last Payout Amount (after re-seed deduction)
  uint256 public jackpotCount;          // Number of jackpots for sliding payout.


  // Timestamp of Game Start
  uint256 public gameStartTime;     // Game Start Time
  uint256 public roundStartTime;    // Round Start Time, used to pause the game
  uint256 public lastAction;        // Last Action Timestamp
  uint256 public timeBetweenGames = 24 hours;       // Time between games (4 Jackpots hit = 1 game)
  uint256 public timeBeforeJackpot = 30 minutes;    // Time between last purchase and jackpot payout (increases)
  uint256 public timeBeforeJackpotReset = timeBeforeJackpot; // To reset the jackpot timer
  uint256 public timeIncreasePerTx = 1 minutes;     // How much time to increment the jackpot for each buy
  uint256 public timeBetweenRounds = 5 minutes;  // Time between rounds (each Round has 5 minute timeout)


  // Buy In configuration logic
  uint256 public buyFee = 90;       // This ends up being a 10% fee towards Jackpot
  uint256 public minBuy = 50;       // Jackpot / 50 = 2% Min buy
  uint256 public maxBuy = 2;        // Jackpot / 2 = 50% Max buy
  uint256 public minMinBuyETH = 0.02 ether; // Min buy in should be more then 0.02 ETH
  uint256 public minMaxBuyETH = 0.5 ether; // Max buy in should be more then 0.5 ETH
  uint256[] public gameReseeds = [90, 80, 60, 20]; // How much money reseeds to the next round


  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  modifier isStarted() {
      require(now >= gameStartTime); // Check game started
      require(now >= roundStartTime); // Check round started
      _;
  }


  /**
   * Events
   */
  event Purchase(uint256 amount, address depositer);
  event Seed(uint256 amount, address seeder);

  function TwoXJackpot() public {
    contractOwner = msg.sender;
    gameStartTime = now + timeBetweenGames;
    lastAction = gameStartTime;
  }

  //                 //
  // ADMIN FUNCTIONS //
  //                 //

  // Change the start time for fair launch
  function changeStartTime(uint256 _time) public onlyContractOwner {
    require(now < _time); // only allow changing it to something in the future
    gameStartTime = _time;
    lastAction = gameStartTime; // Don&#39;t forget to update last action too :)
  }

  // Change the start time for fair launch
  function updateTimeBetweenGames(uint256 _time) public onlyContractOwner {
    timeBetweenGames = _time; // Time after Jackpot claim we allow new buys.
  }

  //                //
  // User Functions //
  //                //

  // Anyone can seed the jackpot, since its non-refundable. It will pay 10% forward to next game.
  // Beware, there is no way to get your seed back unless you win the jackpot.
  function seed() public payable {
    jackpotBalance += msg.value; // Increase the value of the jackpot by this much.
    //emit Seed event
    emit Seed(msg.value, msg.sender);
  }

  function purchase() public payable isStarted  {
    // Check if the game is still running
    if (now > lastAction + timeBeforeJackpot &&
      jackpotLastQualified != 0x0) {
      claim();
      // Next game/round will start, return back money to user
      if (msg.value > 0) {
        msg.sender.transfer(msg.value);
      }
      return;
    }

    // Check if JackPot is less then 1 ETH, then
    // use predefined minimum and maximum buy in values
    if (jackpotBalance <= 1 ether) {
      require(msg.value >= minMinBuyETH); // >= 0.02 ETH
      require(msg.value <= minMaxBuyETH); // <= 0.5 ETH
    } else {
      uint256 purchaseMin = SafeMath.mul(msg.value, minBuy);
      uint256 purchaseMax = SafeMath.mul(msg.value, maxBuy);
      require(purchaseMin >= jackpotBalance);
      require(purchaseMax <= jackpotBalance);
    }

    uint256 valueAfterTax = SafeMath.div(SafeMath.mul(msg.value, buyFee), 100);     // Take a 10% fee for Jackpot, example on 1ETH Buy:  0.9 = (1.0 * 90) / 100
    uint256 potFee = SafeMath.sub(msg.value, valueAfterTax);                        // Calculate the absolute number to put into pot.


    jackpotBalance += potFee;           // Add it to the jackpot
    jackpotLastQualified = msg.sender;  // You are now the rightly heir to the Jackpot...for now...
    lastAction = now;                   //  Reset jackpot timer
    timeBeforeJackpot += timeIncreasePerTx;                // Increase Jackpot Timer by 1 minute.
    uint256 valueMultiplied = SafeMath.mul(msg.value, 2);  // Double it

    // Update Global Investing Information
    games[gameIndex].gameTotalInvested += msg.value;
    games[gameIndex].gameTotalBacklog += valueMultiplied;

    // Update Game Investing Information
    games[gameIndex].totalInvested[msg.sender] += msg.value;
    games[gameIndex].totalValue[msg.sender] += valueMultiplied;

    // Push new Buy In information in our game list of buy ins
    games[gameIndex].buyIns.push(BuyIn({
      value: valueMultiplied,
      owner: msg.sender
    }));
    //Emit a deposit event.
    emit Purchase(msg.value, msg.sender);

    while (games[gameIndex].index < games[gameIndex].buyIns.length
            && valueAfterTax > 0) {

      BuyIn storage buyIn = games[gameIndex].buyIns[games[gameIndex].index];

      if (valueAfterTax < buyIn.value) {
        buyIn.owner.transfer(valueAfterTax);

        // Update game information
        games[gameIndex].gameTotalBacklog -= valueAfterTax;
        games[gameIndex].gameTotalPaidOut += valueAfterTax;

        // game paid out and value update
        games[gameIndex].totalPaidOut[buyIn.owner] += valueAfterTax;
        games[gameIndex].totalValue[buyIn.owner] -= valueAfterTax;
        buyIn.value -= valueAfterTax;
        valueAfterTax = 0;
      } else {
        buyIn.owner.transfer(buyIn.value);

        // Update game information
        games[gameIndex].gameTotalBacklog -= buyIn.value;
        games[gameIndex].gameTotalPaidOut += buyIn.value;

        // game paid out and value update
        games[gameIndex].totalPaidOut[buyIn.owner] += buyIn.value;
        games[gameIndex].totalValue[buyIn.owner] -= buyIn.value;
        valueAfterTax -= buyIn.value;
        buyIn.value = 0;
        games[gameIndex].index++;
      }
    }
  }


  // Claim the Jackpot
  function claim() public payable isStarted {
    require(now > lastAction + timeBeforeJackpot);
    require(jackpotLastQualified != 0x0); // make sure last jackpotLastQualified is not 0x0

    // Each game has 4 Jackpot payouts, increasing in payout percentage.
    // Funds owed to you do not reset between Jackpots, but will reset after 1 game (4 Jackpots)
    uint256 reseed = SafeMath.div(SafeMath.mul(jackpotBalance, gameReseeds[jackpotCount]), 100);
    uint256 payout = jackpotBalance - reseed;


    jackpotLastQualified.transfer(payout); // payout entire jackpot minus seed.
    jackpotBalance = reseed;
    jackpotLastWinner = jackpotLastQualified;
    jackpotLastPayout = payout;

    // Let&#39;s store now new winner in list of game winners
    games[gameIndex].winners.push(jackpotLastQualified);
    games[gameIndex].winnerPayouts.push(payout);

    // RESET all the settings
    timeBeforeJackpot = timeBeforeJackpotReset; // reset to 30 min on each round timer
    jackpotLastQualified = 0x0; // set last qualified to 0x0

    if(jackpotCount == gameReseeds.length - 1){
      // Reset all outstanding owed money after 4 claimed jackpots to officially restart the game.
      gameStartTime = now + timeBetweenGames;    // Restart the game in a specified period (24h)
      lastAction = gameStartTime; // Reset last action to the start of the game
      gameIndex += 1; // Next Game!
      jackpotCount = 0;  // Reset Jackpots back to 0 after game end.

    } else {
      lastAction = now + timeBetweenRounds;
      roundStartTime = lastAction;
      jackpotCount += 1;
    }
  }

  // Fallback, sending any ether will call purchase()
  function () public payable {
    purchase();
  }

  // PUBLIC METHODS TO RETRIEVE DATA IN UI
  // Return Current Jackpot Info
  // [ JackPotBalance, jackpotLastQualified, jackpotLastWinner, jackpotLastPayout,
  //  jackpotCount, gameIndex, gameStartTime, timeTillRoundEnd, roundStartTime]
  function getJackpotInfo() public view returns (uint256, address, address, uint256, uint256, uint256, uint256, uint256, uint256) {
    return (
        jackpotBalance,
        jackpotLastQualified,
        jackpotLastWinner,
        jackpotLastPayout,
        jackpotCount,
        gameIndex,
        gameStartTime,
        lastAction + timeBeforeJackpot,
        roundStartTime
      );
  }

  // Return player game info based on game index and player address
  // [ totalInvested, totalValue, totalPaidOut]
  function getPlayerGameInfo(uint256 _gameIndex, address _player) public view returns (uint256, uint256, uint256) {
    return (
        games[_gameIndex].totalInvested[_player],
        games[_gameIndex].totalValue[_player],
        games[_gameIndex].totalPaidOut[_player]
      );
  }

  // Get user game info connected to current game
  function getMyGameInfo() public view returns (uint256, uint256, uint256) {
    return getPlayerGameInfo(gameIndex, msg.sender);
  }

  // Return all the game constants, setting the game
  function getGameConstants() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256[]) {
    return (
        timeBetweenGames,
        timeBeforeJackpot,
        minMinBuyETH,
        minMaxBuyETH,
        minBuy,
        maxBuy,
        gameReseeds
      );
  }

  // Return game information based on game index
  function getGameInfo(uint256 _gameIndex) public view returns (uint256, uint256, uint256, address[], uint256[]) {
    return (
        games[_gameIndex].gameTotalInvested,
        games[_gameIndex].gameTotalPaidOut,
        games[_gameIndex].gameTotalBacklog,
        games[_gameIndex].winners,
        games[_gameIndex].winnerPayouts
      );
  }

  // Return current running game info
  function getCurrentGameInfo() public view returns (uint256, uint256, uint256, address[], uint256[]) {
    return getGameInfo(gameIndex);
  }

  // Return time when next game will start
  function getGameStartTime() public view returns (uint256) {
    return gameStartTime;
  }

  // Return end time for the jackpot round
  function getJackpotRoundEndTime() public view returns (uint256) {
    return lastAction + timeBeforeJackpot;
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