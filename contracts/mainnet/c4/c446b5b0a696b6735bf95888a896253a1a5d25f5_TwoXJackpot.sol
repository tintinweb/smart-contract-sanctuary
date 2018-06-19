pragma solidity ^0.4.18;
/*
TwoXJackpot - A modification to TwoX that turns the 5% developer fee into a jackpot!
- Double your ether.
- 5% of purchase goes towards a jackpot.
- Any purchase of 1% of the JackPot total qualifies you.
- The last qualified address has a claim to the jackpot if no new qualified (1%) purchases in 6 hours.
- Claim must be made, any new purchase resets the timer and invalidate the previous claim.
- Admin can empty the jackpot if no new action and no claim in 30 days.
*/

contract TwoXJackpot {
  using SafeMath for uint256;

  // Address of the contract creator
  address public contractOwner;

  // FIFO queue
  BuyIn[] public buyIns;

  // The current BuyIn queue index
  uint256 public index;

  // Total invested for entire contract
  uint256 public contractTotalInvested;

  // Dev Fee (1%)
  uint256 public devFeeBalance;

  // Total of Jackpot
  uint256 public jackpotBalance;

  // Track amount of seed money put into jackpot.
  uint256 public seedAmount;

  // The last qualified address to get into the jackpot.
  address public jackpotLastQualified;

  // Timestamp of the last action.
  uint256 public lastAction;

  // Timestamp of Game Start
  uint256 public gameStartTime;

  // Total invested for a given address
  mapping (address => uint256) public totalInvested;

  // Total value for a given address
  mapping (address => uint256) public totalValue;

  // Total paid out for a given address
  mapping (address => uint256) public totalPaidOut;

  struct BuyIn {
    uint256 value;
    address owner;
  }

  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  modifier isStarted() {
      require(now >= gameStartTime);
      _;
  }

  function TwoXJackpot() public {
    contractOwner = msg.sender;
    gameStartTime = now + 24 hours;
  }

  //                 //
  // ADMIN FUNCTIONS //
  //                 //

  // return jackpot to contract creator if no purchases or claims in 30 days.
  function killme() public payable onlyContractOwner {
    require(now > lastAction + 30 days);
    seedAmount = 0;
    jackpotBalance = 0;
    contractOwner.transfer(jackpotBalance);
  }

  // Contract owner can seed the Jackpot, and get it back whenever Jackpot is paid. See claim() function
  function seed() public payable onlyContractOwner {
    seedAmount += msg.value;     // Amount owner gets back on payout.
    jackpotBalance += msg.value; // Increase the value of the jackpot by this much.
  }

  // Change the start time.
  function changeStartTime(uint256 _time) public payable onlyContractOwner {
    require(now < _time); // only allow changing it to something in the future.
    require(now < gameStartTime); // Only change a game that has not started, prevent abuse.
    gameStartTime = _time;
  }

  //                //
  // User Functions //
  //                //

  function purchase() public payable isStarted {

    uint256 purchaseMin = SafeMath.mul(msg.value, 20); // 5% Jackpot Min Purchase
    uint256 purchaseMax = SafeMath.mul(msg.value, 2); // 50% Jackpot Min Purchase

    require(purchaseMin >= jackpotBalance);
    require(purchaseMax <= jackpotBalance);

    // Take a 5% fee
    uint256 valueAfterTax = SafeMath.div(SafeMath.mul(msg.value, 95), 100);

    // Calculate the absolute number to put into pot. (5% total purchase)
    uint256 potFee = SafeMath.sub(msg.value, valueAfterTax);

    // Add it to the jackpot
    jackpotBalance += potFee;
    jackpotLastQualified = msg.sender;
    lastAction = now;

    // HNNNNNNGGGGGG
    uint256 valueMultiplied = SafeMath.mul(msg.value, 2);

    contractTotalInvested += msg.value;
    totalInvested[msg.sender] += msg.value;

    while (index < buyIns.length && valueAfterTax > 0) {
      BuyIn storage buyIn = buyIns[index];

      if (valueAfterTax < buyIn.value) {
        buyIn.owner.transfer(valueAfterTax);
        totalPaidOut[buyIn.owner] += valueAfterTax;
        totalValue[buyIn.owner] -= valueAfterTax;
        buyIn.value -= valueAfterTax;
        valueAfterTax = 0;
      } else {
        buyIn.owner.transfer(buyIn.value);
        totalPaidOut[buyIn.owner] += buyIn.value;
        totalValue[buyIn.owner] -= buyIn.value;
        valueAfterTax -= buyIn.value;
        buyIn.value = 0;
        index++;
      }
    }

    // if buyins have been exhausted, return the remaining
    // funds back to the investor
    if (valueAfterTax > 0) {
      msg.sender.transfer(valueAfterTax);
      valueMultiplied -= valueAfterTax;
      totalPaidOut[msg.sender] += valueAfterTax;
    }

    totalValue[msg.sender] += valueMultiplied;

    buyIns.push(BuyIn({
      value: valueMultiplied,
      owner: msg.sender
    }));
  }


  // Send the jackpot if no activity in 24 hours and claimant was the last person to generate activity.
  function claim() public payable isStarted {
    require(now > lastAction + 6 hours);
	require(jackpotLastQualified == msg.sender);

    uint256 seedPay = seedAmount;
    uint256 jpotPay = jackpotBalance - seedAmount;

    seedAmount = 0;
    contractOwner.transfer(seedPay); // Return the initial seed to owner.

    jackpotBalance = 0;
	msg.sender.transfer(jpotPay); // payout entire jackpot minus seed.
  }

  // Fallback, sending any ether will call purchase() while sending 0 will call claim()
  function () public payable {
    if(msg.value > 0) {
      purchase();
    } else {
      claim();
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