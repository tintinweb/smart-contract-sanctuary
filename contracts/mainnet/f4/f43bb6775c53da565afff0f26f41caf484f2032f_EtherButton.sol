pragma solidity 0.4.19;

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

/**
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="80f2e5ede3efc0b2">[email&#160;protected]</a>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

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
 * EtherButton
 *
 * A game of financial hot potato. Players pay to click EtherButton.
 * Each player is given 105% of their payment by each subsequent player.
 * A seven hour timer resets after every click. The round advances once the timer reaches zero.
 * 
 * Bonus:
 *  For every player payout, an additional 1% is stored as an end-of-round bonus.
 *  Each player is entitled to their bonus if they click EtherButton during the *next* round.
 *  0.500 ETH is given to the last player of every round and their bonus is unlocked immediately.
 *  Unclaimed bonuses are rolled into future rounds.
 **/
contract EtherButton is Ownable, ReentrancyGuard {
  // Use basic math operators which have integer overflow protection built into them.
  // Simplifies code greatly by reducing the need to constantly check inputs for overflow.
  using SafeMath for uint;

  // Best practices say to prefix events with Log to avoid confusion.
  // https://consensys.github.io/smart-contract-best-practices/recommendations/#differentiate-functions-and-events
  event LogClick(
    uint _id,
    uint _price,
    uint _previousPrice,
    uint _endTime,
    uint _clickCount,
    uint _totalBonus,
    address _activePlayer,
    uint _activePlayerClickCount,
    uint _previousRoundTotalBonus
  );
  event LogClaimBonus(address _recipient, uint _bonus);
  event LogPlayerPayout(address _recipient, uint _amount);
  event LogSendPaymentFailure(address _recipient, uint _amount);

  // Represent fractions as numerator/denominator because Solidity doesn&#39;t support decimals.
  // It&#39;s okay to use ".5 ether" because it converts to "500000000000000000 wei"
  uint public constant INITIAL_PRICE = .5 ether;
  uint public constant ROUND_DURATION = 7 hours;
  // 5% price increase is allocated to the player.
  uint private constant PLAYER_PROFIT_NUMERATOR = 5;
  uint private constant PLAYER_PROFIT_DENOMINATOR = 100;
  // 1% price increase is allocated to player bonuses.
  uint private constant BONUS_NUMERATOR = 1;
  uint private constant BONUS_DENOMINATOR = 100; 
  // 2.5% price increase is allocated to the owner.
  uint private constant OWNER_FEE_NUMERATOR = 25;
  uint private constant OWNER_FEE_DENOMINATOR = 1000;

  // EtherButton is comprised of many rounds. Each round contains
  // an isolated instance of game state.
  struct Round {
    uint id;
    uint price;
    uint previousPrice;
    uint endTime;
    uint clickCount;
    uint totalBonus;
    uint claimedBonus;
    address activePlayer;
    mapping (address => uint) playerClickCounts;
    mapping (address => bool) bonusClaimedList;
  }

  // A list of all the rounds which have been played as well as
  // the id of the current (active) round.
  mapping (uint => Round) public Rounds;
  uint public RoundId;

  /**
   * Create the contract with an initial &#39;Round 0&#39;. This round has already expired which will cause the first
   * player interaction to start Round 1. This is simpler than introducing athe concept of a &#39;paused&#39; round.
  **/
  function EtherButton() public {
    initializeRound();
    Rounds[RoundId].endTime = now.sub(1);
  }

  /**
   * Performs a single &#39;click&#39; of EtherButton.
   *
   * Advances the round if the previous round&#39;s endTime has passed. This needs to be done
   * just-in-time because code isn&#39;t able to execute on a timer - it needs funding.
   *
   * Refunds the player any extra money they may have sent. Pays the last player and the owner.
   * Marks the player as the active player so that they&#39;re next to be paid.
   *
   * Emits an event showing the current state of EtherButton and returns the state, too.
  **/
  function click() nonReentrant external payable {
    // Owner is not allowed to play.
    require(msg.sender != owner);

    // There&#39;s no way to advance the round exactly at a specific time because the contract only runs
    // when value is sent to it. So, round advancement must be done just-in-time whenever a player pays to click.
    // Only advance the round when a player clicks because the next round&#39;s timer will begin immediately.
    if (getIsRoundOver(RoundId)) {
      advanceRound(); 
    }

    Round storage round = Rounds[RoundId];

    // Safe-guard against spam clicks from a single player.
    require(msg.sender != round.activePlayer);
    // Safe-guard against underpayment.
    require(msg.value >= round.price);

    // Refund player extra value beyond price. If EtherButton is very popular then its price may
    // attempt to increase multiple times in a single block. In this situation, the first attempt
    // would be successful, but subsequent attempts would fail due to insufficient funding. 
    // To combat this issue, a player may send more value than necessary to
    // increase the chance of the price being payable with the amount of value they sent.
    if (msg.value > round.price) {
      sendPayment(msg.sender, msg.value.sub(round.price));
    }

    // Pay the active player and owner for each click past the first.
    if (round.activePlayer != address(0)) {
      // Pay the player first because that seems respectful.
      // Log the player payouts to show on the website.
      uint playerPayout = getPlayerPayout(round.previousPrice);
      sendPayment(round.activePlayer, playerPayout);
      LogPlayerPayout(round.activePlayer, playerPayout);

      // Pay the contract owner as fee for game creation. Thank you! <3
      sendPayment(owner, getOwnerFee(round.previousPrice));

      // Keep track of bonuses collected at same time as sending payouts to ensure financial consistency.
      round.totalBonus = round.totalBonus.add(getBonusFee(round.previousPrice));
    }

    // Update round state to reflect the additional click
    round.activePlayer = msg.sender;
    round.playerClickCounts[msg.sender] = round.playerClickCounts[msg.sender].add(1);
    round.clickCount = round.clickCount.add(1);
    round.previousPrice = round.price;
    // Increment the price by 8.50%
    round.price = getNextPrice(round.price);
    // Reset the round timer
    round.endTime = now.add(ROUND_DURATION);
    
    // Log an event with relevant information from the round&#39;s state.
    LogClick(
      round.id,
      round.price,
      round.previousPrice,
      round.endTime,
      round.clickCount,
      round.totalBonus,
      msg.sender,
      round.playerClickCounts[msg.sender],
      Rounds[RoundId.sub(1)].totalBonus
    );
  }

  /**
   * Provides bonus payments to players who wish to claim them.
   * Bonuses accrue over the course of a round for those playing in the round.
   * Bonuses may be claimed once the next round starts, but will remain locked until
   * players participate in that round. The last active player of the previous round
   * has their bonus unlocked immediately without need to play in the next round.
   **/
  function claimBonus() nonReentrant external {
    // NOTE: The only way to advance the round is to run the &#39;click&#39; method. When a round is over, it will have expired,
    // but RoundId will not have (yet) incremented. So, claimBonus needs to check the previous round. This allows EtherButton
    // to never enter a &#39;paused&#39; state, which is less code (aka more reliable) but it does have some edge cases.
    uint roundId = getIsRoundOver(RoundId) ? RoundId.add(1) : RoundId;
    uint previousRoundId = roundId.sub(1);
    bool isBonusClaimed = getIsBonusClaimed(previousRoundId, msg.sender);

    // If player has already claimed their bonus exit early to keep code simple and cheap to run.
    if (isBonusClaimed) {
      return;
    }

    // If a player can&#39;t claim their bonus because they haven&#39;t played during the current round
    // and they were not the last player in the previous round then exit as they&#39;re not authorized.
    bool isBonusUnlockExempt = getIsBonusUnlockExempt(previousRoundId, msg.sender);
    bool isBonusUnlocked = getPlayerClickCount(roundId, msg.sender) > 0;
    if (!isBonusUnlockExempt && !isBonusUnlocked) {
      return;
    }

    // If player is owed money from participation in previous round - send it.
    Round storage previousRound = Rounds[previousRoundId];
    uint playerClickCount = previousRound.playerClickCounts[msg.sender];
    uint roundClickCount = previousRound.clickCount;
    // NOTE: Be sure to multiply first to avoid decimal precision math.
    uint bonus = previousRound.totalBonus.mul(playerClickCount).div(roundClickCount);

    // If the current player is owed a refund from previous round fulfill that now.
    // This is better than forcing the player to make a separate requests for
    // bonuses and refund payouts.
    if (previousRound.activePlayer == msg.sender) {
      bonus = bonus.add(INITIAL_PRICE);
    }

    previousRound.bonusClaimedList[msg.sender] = true;
    previousRound.claimedBonus = previousRound.claimedBonus.add(bonus);
    sendPayment(msg.sender, bonus);

    // Let the EtherButton website know a bonus was claimed successfully so it may update.
    LogClaimBonus(msg.sender, bonus);
  }

  /**
   * Returns true once the given player has claimed their bonus for the given round.
   * Bonuses are only able to be claimed once per round per player.
   **/
  function getIsBonusClaimed(uint roundId, address player) public view returns (bool) {
    return Rounds[roundId].bonusClaimedList[player];
  }

  /**
   * Returns the number of times the given player has clicked EtherButton during the given round.
   **/
  function getPlayerClickCount(uint roundId, address player) public view returns (uint) {
    return Rounds[roundId].playerClickCounts[player];
  }

  /**
   * Returns true if the given player does not need to be unlocked to claim their bonus.
   * This is true when they were the last player to click EtherButton in the previous round.
   * That player deserves freebies for losing. So, they get their bonus unlocked early.
   **/
  function getIsBonusUnlockExempt(uint roundId, address player) public view returns (bool) {
    return Rounds[roundId].activePlayer == player;
  }

  /**
   * Returns true if enough time has elapsed since the active player clicked the
   * button to consider the given round complete.
   **/
  function getIsRoundOver(uint roundId) private view returns (bool) {
    return now > Rounds[roundId].endTime;
  }

  /**
   * Signal the completion of a round and the start of the next by moving RoundId forward one.
   * As clean-up before the round change occurs, join all unclaimed player bonuses together and move them
   * forward one round. Just-in-time initialize the next round&#39;s state once RoundId is pointing to it because
   * an unknown number of rounds may be played. So, it&#39;s impossible to initialize all rounds at contract creation.
   **/
  function advanceRound() private {
    if (RoundId > 1) {
      // Take all of the previous rounds unclaimed bonuses and roll them forward.
      Round storage previousRound = Rounds[RoundId.sub(1)];      
      // If the active player of the previous round didn&#39;t claim their refund then they lose the ability to claim it.
      // Their refund is also rolled into the bonuses for the next round.
      uint remainingBonus = previousRound.totalBonus.add(INITIAL_PRICE).sub(previousRound.claimedBonus);
      Rounds[RoundId].totalBonus = Rounds[RoundId].totalBonus.add(remainingBonus);
    }

    RoundId = RoundId.add(1);
    initializeRound();
  }

  /**
   * Sets the current round&#39;s default values. Initialize the price to 0.500 ETH,
   * the endTime to 7 hours past the current time and sets the round id. The round is
   * also started as the endTime is now ticking down.
   **/
  function initializeRound() private {
    Rounds[RoundId].id = RoundId;
    Rounds[RoundId].endTime = block.timestamp.add(ROUND_DURATION);
    Rounds[RoundId].price = INITIAL_PRICE;
  }

  /**
   * Sends an amount of Ether to the recipient. Returns true if it was successful.
   * Logs payment failures to provide documentation on attacks against the contract.
   **/
  function sendPayment(address recipient, uint amount) private returns (bool) {
    assert(recipient != address(0));
    assert(amount > 0);

    // It&#39;s considered good practice to require users to pull payments rather than pushing
    // payments to them. Since EtherButton pays the previous player immediately, it has to mitigate
    // a denial-of-service attack. A malicious contract might always reject money which is sent to it.
    // This contract could be used to disrupt EtherButton if an assumption is made that money will
    // always be sent successfully.
    // https://github.com/ConsenSys/smart-contract-best-practices/blob/master/docs/recommendations.md#favor-pull-over-push-for-external-calls
    // Intentionally not using recipient.transfer to prevent this DOS attack vector.
    bool result = recipient.send(amount);

    // NOTE: Initially, this was written to allow users to reclaim funds on failure.
    // This was removed due to concerns of allowing attackers to retrieve their funds. It is
    // not possible for a regular wallet to reject a payment.
    if (!result) {
      // Log the failure so attempts to compromise the contract are documented.
      LogSendPaymentFailure(recipient, amount);
    }

    return result;
  }

  /**
    Returns the next price to click EtherButton. The returned value should be 
    8.50% larger than the current price:
      - 5.00% is paid to the player.
      - 1.00% is paid as bonuses.
      - 2.50% is paid to the owner.
   **/
  function getNextPrice(uint price) private pure returns (uint) {
    uint playerFee = getPlayerFee(price);
    assert(playerFee > 0);

    uint bonusFee = getBonusFee(price);
    assert(bonusFee > 0);

    uint ownerFee = getOwnerFee(price);
    assert(ownerFee > 0);

    return price.add(playerFee).add(bonusFee).add(ownerFee);
  }

  /**
   * Returns 1.00% of the given price. Be sure to multiply before dividing to avoid decimals.
   **/
  function getBonusFee(uint price) private pure returns (uint) {
    return price.mul(BONUS_NUMERATOR).div(BONUS_DENOMINATOR);
  }

  /**
   * Returns 2.50% of the given price. Be sure to multiply before dividing to avoid decimals.
   **/
  function getOwnerFee(uint price) private pure returns (uint) {
    return price.mul(OWNER_FEE_NUMERATOR).div(OWNER_FEE_DENOMINATOR);
  }

  /**
   * Returns 5.00% of the given price. Be sure to multiply before dividing to avoid decimals.
   **/
  function getPlayerFee(uint price) private pure returns (uint) {
    return price.mul(PLAYER_PROFIT_NUMERATOR).div(PLAYER_PROFIT_DENOMINATOR);
  }

  /**
   * Returns the total amount of Ether the active player will receive. This is
   * 105.00% of their initial price paid.
   **/
  function getPlayerPayout(uint price) private pure returns (uint) {
    return price.add(getPlayerFee(price));
  }
}