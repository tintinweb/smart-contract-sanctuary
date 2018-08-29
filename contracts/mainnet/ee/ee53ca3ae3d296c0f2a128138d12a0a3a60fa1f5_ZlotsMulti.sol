pragma solidity ^0.4.24;

/*
* ZETHR PRESENTS: SLOTS
*
* Written August 2018 by the Zethr team for zethr.io.
*
* Code framework written by Norsefire.
* EV calculations written by TropicalRogue.
* Audit and edits written by Klob.
* Multiroll framework written by Etherguy.
*
* Rolling Odds:
*   49.31%  Lose / 50.69% Win  
*   35.64%  Two Matching Icons
*       - 10.00% : 2.50x    Multiplier [Two Rockets]
*       - 15.00% : 1.33x    Multiplier [Two Gold  Pyramids]
*       - 15.00% : 1.00x    Multiplier [Two &#39;Z&#39; Symbols]
*       - 15.00% : 1.00x    Multiplier [Two &#39;T&#39; Symbols]
*       - 15.00% : 1.00x    Multiplier [Two &#39;H&#39; Symbols]
*       - 15.00% : 1.25x    Multiplier [Two Purple Pyramids]
*       - 15.00% : 2.00x    Multiplier [Two Ether Icons]
*   6.79%   One Of Each Pyramid
*       - 1.50x  Multiplier
*   2.94%   One Moon Icon
*       - 2.50x Multiplier
*   5.00%   Three Matching Icons
*       - 03.00% : 13.00x   Multiplier [Three Rockets]
*       - 05.00% : 09.00x   Multiplier [Three Gold  Pyramids]
*       - 27.67% : 03.00x   Multiplier [Three &#39;Z&#39; Symbols]
*       - 27.67% : 03.00x   Multiplier [Three &#39;T&#39; Symbols]
*       - 27.67% : 03.00x   Multiplier [Three &#39;H&#39; Symbols]
*       - 05.00% : 07.50x   Multiplier [Three Purple Pyramids]
*       - 04.00% : 11.00x   Multiplier [Three Ether Icons]
*   0.28%   Z T H Prize
*       - 20x Multiplier
*   0.03%   Two Moon Icons
*       - 50x  Multiplier
*   0.0001% Three Moon Grand Jackpot
*       - Jackpot Amount (variable)
*
*   From all of us at Zethr, thank you for playing!    
*
*/

// Zethr Token Bankroll interface
contract ZethrTokenBankroll{
  // Game request token transfer to player 
  function gameRequestTokens(address target, uint tokens) public;
  function gameTokenAmount(address what) public returns (uint);
}

// Zether Main Bankroll interface
contract ZethrMainBankroll{
  function gameGetTokenBankrollList() public view returns (address[7]);
}

// Zethr main contract interface
contract ZethrInterface{
  function withdraw() public;
}

// Library for figuring out the "tier" (1-7) of a dividend rate
library ZethrTierLibrary{

  function getTier(uint divRate) 
    internal 
    pure 
    returns (uint)
  {
    // Tier logic 
    // Returns the index of the UsedBankrollAddresses which should be used to call into to withdraw tokens 
        
    // We can divide by magnitude
    // Remainder is removed so we only get the actual number we want
    uint actualDiv = divRate; 
    if (actualDiv >= 30){
      return 6;
    } else if (actualDiv >= 25){
      return 5;
    } else if (actualDiv >= 20){
      return 4;
    } else if (actualDiv >= 15){
      return 3;
    } else if (actualDiv >= 10){
      return 2; 
    } else if (actualDiv >= 5){
      return 1;
    } else if (actualDiv >= 2){
      return 0;
    } else{
      // Impossible
      revert(); 
    }
  }
}

// Contract that contains the functions to interact with the ZlotsJackpotHoldingContract
contract ZlotsJackpotHoldingContract {
  function payOutWinner(address winner) public; 
  function getJackpot() public view returns (uint);
}
 
// Contract that contains the functions to interact with the bankroll system
contract ZethrBankrollBridge {
  // Must have an interface with the main Zethr token contract 
  ZethrInterface Zethr;
   
  // Store the bankroll addresses 
  // address[0] is tier1: 2-5% 
  // address[1] is tier2: 5-10, etc
  address[7] UsedBankrollAddresses; 

  // Mapping for easy checking
  mapping(address => bool) ValidBankrollAddress;
    
  // Set up the tokenbankroll stuff 
  function setupBankrollInterface(address ZethrMainBankrollAddress) 
    internal 
  {
    // Instantiate Zethr
    Zethr = ZethrInterface(0xD48B633045af65fF636F3c6edd744748351E020D);

    // Get the bankroll addresses from the main bankroll
    UsedBankrollAddresses = ZethrMainBankroll(ZethrMainBankrollAddress).gameGetTokenBankrollList();
    for(uint i=0; i<7; i++){
      ValidBankrollAddress[UsedBankrollAddresses[i]] = true;
    }
  }
    
  // Require a function to be called from a *token* bankroll 
  modifier fromBankroll() {
    require(ValidBankrollAddress[msg.sender], "msg.sender should be a valid bankroll");
    _;
  }
    
  // Request a payment in tokens to a user FROM the appropriate tokenBankroll 
  // Figure out the right bankroll via divRate 
  function RequestBankrollPayment(address to, uint tokens, uint tier) 
    internal 
  {
    address tokenBankrollAddress = UsedBankrollAddresses[tier];
    ZethrTokenBankroll(tokenBankrollAddress).gameRequestTokens(to, tokens);
  }
    
  function getZethrTokenBankroll(uint divRate) 
    public 
    constant 
    returns (ZethrTokenBankroll)
  {
    return ZethrTokenBankroll(UsedBankrollAddresses[ZethrTierLibrary.getTier(divRate)]);
  }
}

// Contract that contains functions to move divs to the main bankroll
contract ZethrShell is ZethrBankrollBridge {

  // Dump ETH balance to main bankroll
  function WithdrawToBankroll() 
    public 
  {
    address(UsedBankrollAddresses[0]).transfer(address(this).balance);
  }

  // Dump divs and dump ETH into bankroll
  function WithdrawAndTransferToBankroll() 
    public 
  {
    Zethr.withdraw();
    WithdrawToBankroll();
  }
}

// Zethr game data setup
// Includes all necessary to run with Zethr
contract ZlotsMulti is ZethrShell {
  using SafeMath for uint;

  // ---------------------- Events

  // Might as well notify everyone when the house takes its cut out.
  event HouseRetrievedTake(
    uint timeTaken,
    uint tokensWithdrawn
  );

  // Fire an event whenever someone places a bet.
  event TokensWagered(
    address _wagerer,
    uint _wagered
  );

  event LogResult(
    address _wagerer,
    uint _result,
    uint _profit,
    uint _wagered,
    uint _category,
    bool _win
  );

  // Result announcement events (to dictate UI output!)
  event Loss(address _wagerer, uint _block);                  // Category 0
  event ThreeMoonJackpot(address _wagerer, uint _block);      // Category 1
  event TwoMoonPrize(address _wagerer, uint _block);          // Category 2
  event ZTHPrize(address _wagerer, uint _block);              // Category 3
  event ThreeZSymbols(address _wagerer, uint _block);         // Category 4
  event ThreeTSymbols(address _wagerer, uint _block);         // Category 5
  event ThreeHSymbols(address _wagerer, uint _block);         // Category 6
  event ThreeEtherIcons(address _wagerer, uint _block);       // Category 7
  event ThreePurplePyramids(address _wagerer, uint _block);   // Category 8
  event ThreeGoldPyramids(address _wagerer, uint _block);     // Category 9
  event ThreeRockets(address _wagerer, uint _block);          // Category 10
  event OneMoonPrize(address _wagerer, uint _block);          // Category 11
  event OneOfEachPyramidPrize(address _wagerer, uint _block); // Category 12
  event TwoZSymbols(address _wagerer, uint _block);           // Category 13
  event TwoTSymbols(address _wagerer, uint _block);           // Category 14
  event TwoHSymbols(address _wagerer, uint _block);           // Category 15
  event TwoEtherIcons(address _wagerer, uint _block);         // Category 16
  event TwoPurplePyramids(address _wagerer, uint _block);     // Category 17
  event TwoGoldPyramids(address _wagerer, uint _block);       // Category 18
  event TwoRockets(address _wagerer, uint _block);            // Category 19    
  event SpinConcluded(address _wagerer, uint _block);         // Debug event

  // ---------------------- Modifiers

  // Makes sure that player porfit can&#39;t exceed a maximum amount
  // We use the max win here - 50x
  modifier betIsValid(uint _betSize, uint divRate, uint8 spins) {
    require(_betSize.div(spins).mul(50) <= getMaxProfit(divRate));
    require(_betSize.div(spins) >= minBet);
    _;
  }

  // Requires the game to be currently active
  modifier gameIsActive {
    require(gamePaused == false);
    _;
  }

  // Require msg.sender to be owner
  modifier onlyOwner {
    require(msg.sender == owner); 
    _;
  }

  // Requires msg.sender to be bankroll
  modifier onlyBankroll {
    require(msg.sender == bankroll);
    _;
  }

  // Requires msg.sender to be owner or bankroll
  modifier onlyOwnerOrBankroll {
    require(msg.sender == owner || msg.sender == bankroll);
    _;
  }

  // ---------------------- Variables

  // Configurables
  uint constant public maxProfitDivisor = 1000000;
  uint constant public houseEdgeDivisor = 1000;
  mapping (uint => uint) public maxProfit;
  uint public maxProfitAsPercentOfHouse;
  uint public minBet = 1e18;
  address public zlotsJackpot;
  address private owner;
  address private bankroll;
  bool gamePaused;

  // Trackers
  uint  public totalSpins;
  uint  public totalZTHWagered;
  mapping (uint => uint) public contractBalance;
    
  // Is betting allowed? (Administrative function, in the event of unforeseen bugs)
  bool public gameActive;

  // Bankroll & token addresses
  address private ZTHTKNADDR;
  address private ZTHBANKROLL;

  // ---------------------- Functions 

  // Constructor; must supply bankroll address
  constructor(address BankrollAddress) 
    public 
  {
    // Set up the bankroll interface
    setupBankrollInterface(BankrollAddress); 

    // Owner is deployer
    owner = msg.sender;

    // Default max profit to 5% of contract balance
    ownerSetMaxProfitAsPercentOfHouse(50000);

    // Set starting variables
    bankroll      = ZTHBANKROLL;
    gameActive  = true;

    // Init min bet (1 ZTH)
    ownerSetMinBet(1e18);
  }

  // Zethr dividends gained are accumulated and sent to bankroll manually
  function() public payable {  }

  // If the contract receives tokens, bundle them up in a struct and fire them over to _spinTokens for validation.
  struct TKN { address sender; uint value; }
  function execute(address _from, uint _value, uint divRate, bytes _data) 
    public 
    fromBankroll 
    returns (bool)
  {
      TKN memory _tkn;
      _tkn.sender = _from;
      _tkn.value = _value;
      _spinTokens(_tkn, divRate, uint8(_data[0]));
      return true;
  }

  struct playerSpin {
    uint192 tokenValue; // Token value in uint
    uint48 blockn;      // Block number 48 bits
    uint8 tier;
    uint8 spins;
    uint divRate;
  }

  // Mapping because a player can do one spin at a time
  mapping(address => playerSpin) public playerSpins;

  // Execute spin.
  function _spinTokens(TKN _tkn, uint divRate, uint8 spins) 
    private 
    betIsValid(_tkn.value, divRate, spins)
  {
    require(gameActive);
    require(block.number <= ((2 ** 48) - 1));  // Current block number smaller than storage of 1 uint56
    require(_tkn.value <= ((2 ** 192) - 1));
    address _customerAddress = _tkn.sender;
    uint    _wagered         = _tkn.value;

    playerSpin memory spin = playerSpins[_tkn.sender];
 
    // We update the contract balance *before* the spin is over, not after
    // This means that we don&#39;t have to worry about unresolved rolls never resolving
    // (we also update it when a player wins)
    addContractBalance(divRate, _wagered);

    // Cannot spin twice in one block
    require(block.number != spin.blockn);

    // If there exists a spin, finish it
    if (spin.blockn != 0) {
      _finishSpin(_tkn.sender);
    }

    // Set struct block number and token value
    spin.blockn = uint48(block.number);
    spin.tokenValue = uint192(_wagered.div(spins));
    spin.tier = uint8(ZethrTierLibrary.getTier(divRate));
    spin.divRate = divRate;
    spin.spins = spins;

    // Store the roll struct - 40k gas.
    playerSpins[_tkn.sender] = spin;

    // Increment total number of spins
    totalSpins += spins;

    // Total wagered
    totalZTHWagered += _wagered;

    emit TokensWagered(_customerAddress, _wagered);
  }

  // Finish the current spin of a player, if they have one
  function finishSpin() 
    public
    gameIsActive
    returns (uint[])
  {
    return _finishSpin(msg.sender);
  }

  // Stores the data for the roll (spin)
  struct rollData {
    uint win;
    uint loss; 
    uint jp;
  }

  // Pay winners, update contract balance, send rewards where applicable.
  function _finishSpin(address target)
    private 
    returns (uint[])
  {
    playerSpin memory spin = playerSpins[target];

    require(spin.tokenValue > 0); // No re-entrancy
    require(spin.blockn != block.number);
        
    uint[] memory output = new uint[](spin.spins);
    rollData memory outcomeTrack = rollData(0,0,0);
    uint category = 0;
    uint profit;
    uint playerDivrate = spin.divRate;
        
    for(uint i=0; i<spin.spins; i++) {
        
      // If the block is more than 255 blocks old, we can&#39;t get the result
      // Also, if the result has already happened, fail as well
      uint result;
      if (block.number - spin.blockn > 255) {
        result = 1000000; // Can&#39;t win: default to largest number
        output[i] = 1000000;
      } else {
        // Generate a result - random based ONLY on a past block (future when submitted).
        // Case statement barrier numbers defined by the current payment schema at the top of the contract.
        result = random(1000000, spin.blockn, target, i) + 1;
        output[i] = result;
      }

      if (result > 506856) {
        // Player has lost. Womp womp.

        // Add one percent of player loss to the jackpot
        // (do this by requesting a payout to the jackpot)
        outcomeTrack.loss += spin.tokenValue/100;

        emit Loss(target, spin.blockn);
        emit LogResult(target, result, profit, spin.tokenValue, category, false);
      } else if (result < 2) {
        // Player has won the three-moon mega jackpot!
      
        // Get profit amount via jackpot
        profit = ZlotsJackpotHoldingContract(zlotsJackpot).getJackpot();
        category = 1;
    
        // Emit events
        emit ThreeMoonJackpot(target, spin.blockn);
        emit LogResult(target, result, profit, spin.tokenValue, category, true);

        outcomeTrack.jp += 1;

      } else {
        if (result < 299) {
          // Player has won a two-moon prize!
          profit = SafeMath.mul(spin.tokenValue, 50);
          category = 2;
          emit TwoMoonPrize(target, spin.blockn);
        } else if (result < 3128) {
          // Player has won the Z T H prize!
          profit = SafeMath.mul(spin.tokenValue, 20);
          category = 3;
          emit ZTHPrize(target, spin.blockn);
        } else if (result < 16961) {
          // Player has won a three Z symbol prize!
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 30), 10);
          category = 4;
          emit ThreeZSymbols(target, spin.blockn);
        } else if (result < 30794) {
          // Player has won a three T symbol prize!
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 30), 10);
          category = 5;
          emit ThreeTSymbols(target, spin.blockn);
        } else if (result < 44627) {
          // Player has won a three H symbol prize!
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 30), 10);
          category = 6;
          emit ThreeHSymbols(target, spin.blockn);
        } else if (result < 46627) {
          // Player has won a three Ether icon prize!
          profit = SafeMath.mul(spin.tokenValue, 11);
          category = 7;
          emit ThreeEtherIcons(target, spin.blockn);
        } else if (result < 49127) {
          // Player has won a three purple pyramid prize!
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 75), 10);
          category = 8;
          emit ThreePurplePyramids(target, spin.blockn);
        } else if (result < 51627) {
          // Player has won a three gold pyramid prize!
          profit = SafeMath.mul(spin.tokenValue, 9);
          category = 9;
          emit ThreeGoldPyramids(target, spin.blockn);
        } else if (result < 53127) {
          // Player has won a three rocket prize!
          profit = SafeMath.mul(spin.tokenValue, 13);
          category = 10;
          emit ThreeRockets(target, spin.blockn);
        } else if (result < 82530) {
          // Player has won a one moon prize!
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 25),10);
          category = 11;
          emit OneMoonPrize(target, spin.blockn);
        } else if (result < 150423) {
          // Player has won a each-coloured-pyramid prize!
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 15),10);
          category = 12;
          emit OneOfEachPyramidPrize(target, spin.blockn);
        } else if (result < 203888) {
          // Player has won a two Z symbol prize!
          profit = spin.tokenValue;
          category = 13;
          emit TwoZSymbols(target, spin.blockn);
        } else if (result < 257353) {
          // Player has won a two T symbol prize!
          profit = spin.tokenValue;
          category = 14;
          emit TwoTSymbols(target, spin.blockn);
        } else if (result < 310818) {
          // Player has won a two H symbol prize!
          profit = spin.tokenValue;
          category = 15;
          emit TwoHSymbols(target, spin.blockn);
        } else if (result < 364283) {
          // Player has won a two Ether icon prize!
          profit = SafeMath.mul(spin.tokenValue, 2);
          category = 16;
          emit TwoEtherIcons(target, spin.blockn);
        } else if (result < 417748) {
          // Player has won a two purple pyramid prize!
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 125), 100);
          category = 17;
          emit TwoPurplePyramids(target, spin.blockn);
        } else if (result < 471213) {
          // Player has won a two gold pyramid prize!
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 133), 100);
          category = 18;
          emit TwoGoldPyramids(target, spin.blockn);
        } else {
          // Player has won a two rocket prize!
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 25), 10);
          category = 19;
          emit TwoRockets(target, spin.blockn);
        }

        uint newMaxProfit = getNewMaxProfit(playerDivrate, outcomeTrack.win);
        if (profit > newMaxProfit){
          profit = newMaxProfit;
        }

        emit LogResult(target, result, profit, spin.tokenValue, category, true);
        outcomeTrack.win += profit;
      }
    }

    playerSpins[target] = playerSpin(uint192(0), uint48(0), uint8(0), uint8(0),  uint(0));
    if (outcomeTrack.jp > 0) {
      for (i = 0; i < outcomeTrack.jp; i++) {
        // In the weird case a player wins two jackpots, we of course pay them twice 
        ZlotsJackpotHoldingContract(zlotsJackpot).payOutWinner(target);
      }
    }

    if (outcomeTrack.win > 0) {
      RequestBankrollPayment(target, outcomeTrack.win, spin.tier);
    }

    if (outcomeTrack.loss > 0) {
      // This loss is the loss to pay to the jackpot account 
      // The delta in contractBalance is already updated in a pending bet.
      RequestBankrollPayment(zlotsJackpot, outcomeTrack.loss, spin.tier);
    }
            
    emit SpinConcluded(target, spin.blockn);
    return output;
  }   

  // Returns a random number using a specified block number
  // Always use a FUTURE block number.
  function maxRandom(uint blockn, address entropy, uint index) 
    private 
    view
    returns (uint256 randomNumber) 
  {
    return uint256(keccak256(
        abi.encodePacked(
          blockhash(blockn),
          entropy,
          index
    )));
  }

  // Random helper
  function random(uint256 upper, uint256 blockn, address entropy, uint index)
    internal 
    view 
    returns (uint256 randomNumber)
  {
    return maxRandom(blockn, entropy, index) % upper;
  }

  // Sets max profit (internal)
  function setMaxProfit(uint divRate) 
    internal 
  {
    maxProfit[divRate] = (contractBalance[divRate] * maxProfitAsPercentOfHouse) / maxProfitDivisor; 
  } 

  // Gets max profit  
  function getMaxProfit(uint divRate) 
    public 
    view 
    returns (uint) 
  {
    return (contractBalance[divRate] * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }

  function getNewMaxProfit(uint divRate, uint currentWin) 
    public 
    view 
    returns (uint) 
  {
    return ((contractBalance[divRate] - currentWin) * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }

  // Subtracts from the contract balance tracking var
  function subContractBalance(uint divRate, uint sub) 
    internal 
  {
    contractBalance[divRate] = contractBalance[divRate].sub(sub);
  }

  // Adds to the contract balance tracking var
  function addContractBalance(uint divRate, uint add) 
    internal 
  {
    contractBalance[divRate] = contractBalance[divRate].add(add);
  }

  // An EXTERNAL update of tokens should be handled here
  // This is due to token allocation
  // The game should handle internal updates itself (e.g. tokens are betted)
  function bankrollExternalUpdateTokens(uint divRate, uint newBalance) 
    public 
    fromBankroll 
  {
    contractBalance[divRate] = newBalance;
    setMaxProfit(divRate);
  }

  // Set the new max profit as percent of house - can be as high as 20%
  // (1,000,000 = 100%)
  function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) 
    public
    onlyOwner
  {
    // Restricts each bet to a maximum profit of 50% contractBalance
    require(newMaxProfitAsPercent <= 500000);
    maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
    setMaxProfit(2);
    setMaxProfit(5);
    setMaxProfit(10);
    setMaxProfit(15); 
    setMaxProfit(20);
    setMaxProfit(25);
    setMaxProfit(33);
  }

  // Only owner can set minBet   
  function ownerSetMinBet(uint newMinimumBet) 
    public
    onlyOwner
  {
    minBet = newMinimumBet;
  }

  // Only owner can set zlotsJackpot address
  function ownerSetZlotsAddress(address zlotsAddress) 
    public
    onlyOwner
  {
    zlotsJackpot = zlotsAddress;
  }

  // If, for any reason, betting needs to be paused (very unlikely), this will freeze all bets.
  function pauseGame() 
    public 
    onlyOwnerOrBankroll 
  {
    gameActive = false;
  }

  // The converse of the above, resuming betting if a freeze had been put in place.
  function resumeGame() 
    public 
    onlyOwnerOrBankroll 
  {
    gameActive = true;
  }

  // Administrative function to change the owner of the contract.
  function changeOwner(address _newOwner) 
    public 
    onlyOwnerOrBankroll 
  {
    owner = _newOwner;
  }

  // Administrative function to change the Zethr bankroll contract, should the need arise.
  function changeBankroll(address _newBankroll) 
    public 
    onlyOwnerOrBankroll 
  {
    bankroll = _newBankroll;
  }

  // Is the address that the token has come from actually ZTH?
  function _zthToken(address _tokenContract) 
    private 
    view 
    returns (bool) 
  {
    return _tokenContract == ZTHTKNADDR;
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
  function mul(uint a, uint b) 
    internal 
    pure 
    returns (uint) 
  {
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
  function div(uint a, uint b) 
    internal 
    pure 
    returns (uint) 
  {
    uint c = a / b;
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint a, uint b) 
    internal 
    pure 
    returns (uint) 
  {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint a, uint b) 
    internal 
    pure returns (uint) 
  {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}