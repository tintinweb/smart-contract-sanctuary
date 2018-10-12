pragma solidity ^0.4.24;

// Zethr Token Bankroll interface
contract ZethrTokenBankroll{
    // Game request token transfer to player 
    function gameRequestTokens(address target, uint tokens) public;
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
    uint constant internal magnitude = 2**64;
    function getTier(uint divRate) internal pure returns (uint){
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
 
// Contract that contains the functions to interact with the bankroll system
contract ZethrBankrollBridge{
    // Must have an interface with the main Zethr token contract 
    ZethrInterface Zethr;
   
    // Store the bankroll addresses 
    // address[0] is main bankroll 
    // address[1] is tier1: 2-5% 
    // address[2] is tier2: 5-10, etc
    address[7] UsedBankrollAddresses; 

    // Mapping for easy checking
    mapping(address => bool) ValidBankrollAddress;
    
    // Set up the tokenbankroll stuff 
    function setupBankrollInterface(address ZethrMainBankrollAddress) internal {
        // Instantiate Zethr
        Zethr = ZethrInterface(0xb9ab8eed48852de901c13543042204c6c569b811);
        // Get the bankroll addresses from the main bankroll
        UsedBankrollAddresses = ZethrMainBankroll(ZethrMainBankrollAddress).gameGetTokenBankrollList();
        for(uint i=0; i<7; i++){
            ValidBankrollAddress[UsedBankrollAddresses[i]] = true;
        }
    }
    
    // Require a function to be called from a *token* bankroll 
    modifier fromBankroll(){
        require(ValidBankrollAddress[msg.sender], "msg.sender should be a valid bankroll");
        _;
    }
    
    // Request a payment in tokens to a user FROM the appropriate tokenBankroll 
    // Figure out the right bankroll via divRate 
    function RequestBankrollPayment(address to, uint tokens, uint userDivRate) internal {
        uint tier = ZethrTierLibrary.getTier(userDivRate);
        address tokenBankrollAddress = UsedBankrollAddresses[tier];
        ZethrTokenBankroll(tokenBankrollAddress).gameRequestTokens(to, tokens);
    }
}

// Contract that contains functions to move divs to the main bankroll
contract ZethrShell is ZethrBankrollBridge{
    
    // Dump ETH balance to main bankroll 
    function WithdrawToBankroll() public {
        address(UsedBankrollAddresses[0]).transfer(address(this).balance);
    }
    
    // Dump divs and dump ETH into bankroll 
    function WithdrawAndTransferToBankroll() public {
        Zethr.withdraw();
        WithdrawToBankroll();
    }
}

// Zethr game data setup
// Includes all necessary to run with Zethr 
contract Zethroll is ZethrShell {
  using SafeMath for uint;

  // Makes sure that player profit can&#39;t exceed a maximum amount,
  //  that the bet size is valid, and the playerNumber is in range.
  modifier betIsValid(uint _betSize, uint _playerNumber, uint divRate) {
     require(  calculateProfit(_betSize, _playerNumber) < getMaxProfit(divRate)
             && _betSize >= minBet
             && _playerNumber >= minNumber
             && _playerNumber <= maxNumber);
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
  uint public maxNumber = 90;
  uint public minNumber = 10;
  uint constant public houseEdgeDivisor = 1000;

  // Configurables
  bool public gamePaused;
  bool public canMining = true;
  uint public miningProfit = 100;
  uint public minBetMining = 1e18;
  address public owner;

  mapping (uint => uint) public contractBalance;
  mapping (uint => uint) public maxProfit;
  uint public houseEdge;
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
  
  constructor (address ZethrMainBankrollAddress) public {
    setupBankrollInterface(ZethrMainBankrollAddress);

    // Owner is deployer
    owner = msg.sender;

    // Init 990 = 99% (1% houseEdge)
    houseEdge = 990;

    // The maximum profit from each bet is 10% of the contract balance.
    ownerSetMaxProfitAsPercentOfHouse(200000);

    // Init min bet (1 ZTH)
    ownerSetMinBet(1e18);
    
    canMining = false;
    miningProfit = 100;
    minBetMining = 1e18;
  }

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
  function random(uint256 upper, uint256 blockn, address entropy) public view returns (uint256 randomNumber) {
    return maxRandom(blockn, entropy) % upper;
  }

  // Calculate the maximum potential profit
  function calculateProfit(uint _initBet, uint _roll)
    private
    view
    returns (uint)
  {
    return ((((_initBet * (100 - (_roll.sub(1)))) / (_roll.sub(1)) + _initBet)) * houseEdge / houseEdgeDivisor) - _initBet;
  }

  // I present a struct which takes only 20k gas
  struct playerRoll{
    uint192 tokenValue; // Token value in uint 
    uint48 blockn;      // Block number 48 bits 
    uint8 rollUnder;    // Roll under 8 bits
    uint8 divRate;      // Divrate, 8 bits 
  }

  // Mapping because a player can do one roll at a time
  mapping(address => playerRoll) public playerRolls;

  // The actual roll function
  function _playerRollDice(uint _rollUnder, TKN _tkn, uint userDivRate) private
    gameIsActive
    betIsValid(_tkn.value, _rollUnder, userDivRate)
  {
    require(_tkn.value < ((2 ** 192) - 1));   // Smaller than the storage of 1 uint192;
    require(block.number < ((2 ** 48) - 1));  // Current block number smaller than storage of 1 uint48
    require(userDivRate < (2 ** 8 - 1)); // This should never throw 
    // Note that msg.sender is the Token Contract Address
    // and "_from" is the sender of the tokens

    playerRoll memory roll = playerRolls[_tkn.sender];

    // Cannot bet twice in one block 
    require(block.number != roll.blockn);

    // If there exists a roll, finish it
    if (roll.blockn != 0) {
      _finishBet(_tkn.sender);
    }

    // Set struct block number, token value, and rollUnder values
    roll.blockn = uint48(block.number);
    roll.tokenValue = uint192(_tkn.value);
    roll.rollUnder = uint8(_rollUnder);
    roll.divRate = uint8(userDivRate);

    // Store the roll struct - 20k gas.
    playerRolls[_tkn.sender] = roll;

    // Provides accurate numbers for web3 and allows for manual refunds
    emit LogBet(_tkn.sender, _tkn.value, _rollUnder);
                 
    // Increment total number of bets
    totalBets += 1;

    // Total wagered
    totalZTHWagered += _tkn.value;
    
    // game mining
    if(canMining && roll.tokenValue >= minBetMining){
        uint miningAmout = SafeMath.div(SafeMath.mul(roll.tokenValue, miningProfit) , 10000);
        RequestBankrollPayment(_tkn.sender, miningAmout, roll.divRate);
    }
  }

  // Finished the current bet of a player, if they have one
  function finishBet() public
    gameIsActive
    returns (uint)
  {
    return _finishBet(msg.sender);
  }

  /*
   * Pay winner, update contract balance
   * to calculate new max bet, and send reward.
   */
  function _finishBet(address target) private returns (uint){
    playerRoll memory roll = playerRolls[target];
    require(roll.tokenValue > 0); // No re-entracy
    require(roll.blockn != block.number);
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
      uint mProfit = getMaxProfit(roll.divRate);
        if (profit > mProfit){
            profit = mProfit;
        }

      // Safely reduce contract balance by player profit
      subContractBalance(roll.divRate, profit);

      emit LogResult(target, result, rollUnder, profit, roll.tokenValue, true);

      // Update maximum profit
      setMaxProfit(roll.divRate);

      // Prevent re-entracy memes
      playerRolls[target] = playerRoll(uint192(0), uint48(0), uint8(0), uint8(0));

      // Transfer profit plus original bet
      RequestBankrollPayment(target, profit + roll.tokenValue, roll.divRate);
      return result;

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
      addContractBalance(roll.divRate, roll.tokenValue);
     
      playerRolls[target] = playerRoll(uint192(0), uint48(0), uint8(0), uint8(0));
      // No need to actually delete player roll here since player ALWAYS loses 
      // Saves gas on next buy 

      // Update maximum profit
      setMaxProfit(roll.divRate);
      
      return result;
    }
  }

  // TKN struct
  struct TKN {address sender; uint value;}

  // Token fallback to bet or deposit from bankroll
  function execute(address _from, uint _value, uint userDivRate, bytes _data) public fromBankroll gameIsActive returns (bool) {
      TKN memory _tkn;
      _tkn.sender = _from;
      _tkn.value = _value;
      uint8 chosenNumber = uint8(_data[0]);
      _playerRollDice(chosenNumber, _tkn, userDivRate);

    return true;
  }

  // Sets max profit
  function setMaxProfit(uint divRate) internal {
    //emit CurrentContractBalance(contractBalance);
    maxProfit[divRate] = (contractBalance[divRate] * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }
 
  // Gets max profit 
  function getMaxProfit(uint divRate) public view returns (uint){
      return (contractBalance[divRate] * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }
 
  // Subtracts from the contract balance tracking var 
  function subContractBalance(uint divRate, uint sub) internal {
      contractBalance[divRate] = contractBalance[divRate].sub(sub);
  }
 
  // Adds to the contract balance tracking var 
  function addContractBalance(uint divRate, uint add) internal {
      contractBalance[divRate] = contractBalance[divRate].add(add);
  }

  // Only owner adjust contract balance variable (only used for max profit calc)
  function ownerUpdateContractBalance(uint newContractBalance, uint divRate) public
  onlyOwner
  {
    contractBalance[divRate] = newContractBalance;
  }
  function ownerUpdateMinMaxNumber(uint newMinNumber, uint newMaxNumber) public
  onlyOwner
  {
    minNumber = newMinNumber;
    maxNumber = newMaxNumber;
  }
  // Only owner adjust contract balance variable (only used for max profit calc)
  function updateContractBalance(uint newContractBalance) public
  onlyOwner
  {
    contractBalance[2] = newContractBalance;
    setMaxProfit(2);
    contractBalance[5] = newContractBalance;
    setMaxProfit(5);
    contractBalance[10] = newContractBalance;
    setMaxProfit(10);
    contractBalance[15] = newContractBalance;
    setMaxProfit(15);
    contractBalance[20] = newContractBalance;
    setMaxProfit(20);
    contractBalance[25] = newContractBalance;
    setMaxProfit(25);
    contractBalance[33] = newContractBalance;
    setMaxProfit(33);
  }  
  // An EXTERNAL update of tokens should be handled here 
  // This is due to token allocation 
  // The game should handle internal updates itself (e.g. tokens are betted)
  function bankrollExternalUpdateTokens(uint divRate, uint newBalance) public fromBankroll {
      contractBalance[divRate] = newBalance;
      setMaxProfit(divRate);
  }

  // Only owner address can set maxProfitAsPercentOfHouse
  function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
  onlyOwner
  {
    // Restricts each bet to a maximum profit of 20% contractBalance
    require(newMaxProfitAsPercent <= 200000);
    maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
    setMaxProfit(2);
    setMaxProfit(5);
    setMaxProfit(10);
    setMaxProfit(15);
    setMaxProfit(20);
    setMaxProfit(25);
    setMaxProfit(33);
  }

  // Only owner address can set minBet
  function ownerSetMinBet(uint newMinimumBet) public
  onlyOwner
  {
    minBet = newMinimumBet;
  }

  // Only owner address can set emergency pause #1
  function ownerSetupBankrollInterface(address ZethrMainBankrollAddress) public
  onlyOwner
  {
    setupBankrollInterface(ZethrMainBankrollAddress);
  }
  function ownerPauseGame(bool newStatus) public
  onlyOwner
  {
    gamePaused = newStatus;
  }
  function ownerSetCanMining(bool newStatus) public
  onlyOwner
  {
    canMining = newStatus;
  }
  function ownerSetMiningProfit(uint newProfit) public
  onlyOwner
  {
    miningProfit = newProfit;
  }
  function ownerSetMinBetMining(uint newMinBetMining) public
  onlyOwner
  {
    minBetMining = newMinBetMining;
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

    selfdestruct(owner);
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