/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

/**
 *Submitted for verification at Etherscan.io on 2018-02-18
*/

pragma solidity ^0.4.19;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/ownership/HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <[email protected]π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be send to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
*/
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

// File: contracts/AxiePresale.sol

contract AxiePresale is HasNoEther, Pausable {
  using SafeMath for uint256;

  // No Axies can be adopted after this end date: Friday, March 16, 2018 11:59:59 PM GMT.
  uint256 constant public PRESALE_END_TIMESTAMP = 1521244799;

  uint8 constant public CLASS_BEAST = 0;
  uint8 constant public CLASS_AQUATIC = 2;
  uint8 constant public CLASS_PLANT = 4;

  uint256 constant public INITIAL_PRICE_INCREMENT = 1600 szabo; // 0.0016 Ether
  uint256 constant public INITIAL_PRICE = INITIAL_PRICE_INCREMENT;
  uint256 constant public REF_CREDITS_PER_AXIE = 5;

  mapping (uint8 => uint256) public currentPrices;
  mapping (uint8 => uint256) public priceIncrements;

  mapping (uint8 => uint256) public totalAxiesAdopted;
  mapping (address => mapping (uint8 => uint256)) public axiesAdopted;

  mapping (address => uint256) public referralCredits;
  mapping (address => uint256) public axiesRewarded;
  uint256 public totalAxiesRewarded;

  event AxiesAdopted(
    address indexed adopter,
    uint8 indexed clazz,
    uint256 quantity,
    address indexed referrer
  );

  event AxiesRewarded(address indexed receiver, uint256 quantity);

  event AdoptedAxiesRedeemed(address indexed receiver, uint8 indexed clazz, uint256 quantity);
  event RewardedAxiesRedeemed(address indexed receiver, uint256 quantity);

  function AxiePresale() public {
    priceIncrements[CLASS_BEAST] = priceIncrements[CLASS_AQUATIC] = //
      priceIncrements[CLASS_PLANT] = INITIAL_PRICE_INCREMENT;

    currentPrices[CLASS_BEAST] = currentPrices[CLASS_AQUATIC] = //
      currentPrices[CLASS_PLANT] = INITIAL_PRICE;
  }

  function axiesPrice(
    uint256 beastQuantity,
    uint256 aquaticQuantity,
    uint256 plantQuantity
  )
    public
    view
    returns (uint256 totalPrice)
  {
    uint256 price;

    (price,,) = _axiesPrice(CLASS_BEAST, beastQuantity);
    totalPrice = totalPrice.add(price);

    (price,,) = _axiesPrice(CLASS_AQUATIC, aquaticQuantity);
    totalPrice = totalPrice.add(price);

    (price,,) = _axiesPrice(CLASS_PLANT, plantQuantity);
    totalPrice = totalPrice.add(price);
  }

  function adoptAxies(
    uint256 beastQuantity,
    uint256 aquaticQuantity,
    uint256 plantQuantity,
    address referrer
  )
    public
    payable
    whenNotPaused
  {
    require(now <= PRESALE_END_TIMESTAMP);

    require(beastQuantity <= 3);
    require(aquaticQuantity <= 3);
    require(plantQuantity <= 3);

    address adopter = msg.sender;
    address actualReferrer = 0x0;

    // An adopter cannot be his/her own referrer.
    if (referrer != adopter) {
      actualReferrer = referrer;
    }

    uint256 value = msg.value;
    uint256 price;

    if (beastQuantity > 0) {
      price = _adoptAxies(
        adopter,
        CLASS_BEAST,
        beastQuantity,
        actualReferrer
      );

      require(value >= price);
      value -= price;
    }

    if (aquaticQuantity > 0) {
      price = _adoptAxies(
        adopter,
        CLASS_AQUATIC,
        aquaticQuantity,
        actualReferrer
      );

      require(value >= price);
      value -= price;
    }

    if (plantQuantity > 0) {
      price = _adoptAxies(
        adopter,
        CLASS_PLANT,
        plantQuantity,
        actualReferrer
      );

      require(value >= price);
      value -= price;
    }

    msg.sender.transfer(value);

    // The current referral is ignored if the referrer's address is 0x0.
    if (actualReferrer != 0x0) {
      uint256 numCredit = referralCredits[actualReferrer]
        .add(beastQuantity)
        .add(aquaticQuantity)
        .add(plantQuantity);

      uint256 numReward = numCredit / REF_CREDITS_PER_AXIE;

      if (numReward > 0) {
        referralCredits[actualReferrer] = numCredit % REF_CREDITS_PER_AXIE;
        axiesRewarded[actualReferrer] = axiesRewarded[actualReferrer].add(numReward);
        totalAxiesRewarded = totalAxiesRewarded.add(numReward);
        AxiesRewarded(actualReferrer, numReward);
      } else {
        referralCredits[actualReferrer] = numCredit;
      }
    }
  }

  function redeemAdoptedAxies(
    address receiver,
    uint256 beastQuantity,
    uint256 aquaticQuantity,
    uint256 plantQuantity
  )
    public
    onlyOwner
    returns (
      uint256 /* remainingBeastQuantity */,
      uint256 /* remainingAquaticQuantity */,
      uint256 /* remainingPlantQuantity */
    )
  {
    return (
      _redeemAdoptedAxies(receiver, CLASS_BEAST, beastQuantity),
      _redeemAdoptedAxies(receiver, CLASS_AQUATIC, aquaticQuantity),
      _redeemAdoptedAxies(receiver, CLASS_PLANT, plantQuantity)
    );
  }

  function redeemRewardedAxies(
    address receiver,
    uint256 quantity
  )
    public
    onlyOwner
    returns (uint256 remainingQuantity)
  {
    remainingQuantity = axiesRewarded[receiver] = axiesRewarded[receiver].sub(quantity);

    if (quantity > 0) {
      // This requires that rewarded Axies are always included in the total
      // to make sure overflow won't happen.
      totalAxiesRewarded -= quantity;

      RewardedAxiesRedeemed(receiver, quantity);
    }
  }

  /**
   * @dev Calculate price of Axies from the same class.
   * @param clazz The class of Axies.
   * @param quantity Number of Axies to be calculated.
   */
  function _axiesPrice(
    uint8 clazz,
    uint256 quantity
  )
    private
    view
    returns (uint256 totalPrice, uint256 priceIncrement, uint256 currentPrice)
  {
    priceIncrement = priceIncrements[clazz];
    currentPrice = currentPrices[clazz];

    uint256 nextPrice;

    for (uint256 i = 0; i < quantity; i++) {
      totalPrice = totalPrice.add(currentPrice);
      nextPrice = currentPrice.add(priceIncrement);

      if (nextPrice / 100 finney != currentPrice / 100 finney) {
        priceIncrement >>= 1;
      }

      currentPrice = nextPrice;
    }
  }

  /**
   * @dev Adopt some Axies from the same class.
   * @param adopter Address of the adopter.
   * @param clazz The class of adopted Axies.
   * @param quantity Number of Axies to be adopted, this should be positive.
   * @param referrer Address of the referrer.
   */
  function _adoptAxies(
    address adopter,
    uint8 clazz,
    uint256 quantity,
    address referrer
  )
    private
    returns (uint256 totalPrice)
  {
    (totalPrice, priceIncrements[clazz], currentPrices[clazz]) = _axiesPrice(clazz, quantity);

    axiesAdopted[adopter][clazz] = axiesAdopted[adopter][clazz].add(quantity);
    totalAxiesAdopted[clazz] = totalAxiesAdopted[clazz].add(quantity);

    AxiesAdopted(
      adopter,
      clazz,
      quantity,
      referrer
    );
  }

  /**
   * @dev Redeem adopted Axies from the same class.
   * @param receiver Address of the receiver.
   * @param clazz The class of adopted Axies.
   * @param quantity Number of adopted Axies to be redeemed.
   */
  function _redeemAdoptedAxies(
    address receiver,
    uint8 clazz,
    uint256 quantity
  )
    private
    returns (uint256 remainingQuantity)
  {
    remainingQuantity = axiesAdopted[receiver][clazz] = axiesAdopted[receiver][clazz].sub(quantity);

    if (quantity > 0) {
      // This requires that adopted Axies are always included in the total
      // to make sure overflow won't happen.
      totalAxiesAdopted[clazz] -= quantity;

      AdoptedAxiesRedeemed(receiver, clazz, quantity);
    }
  }
}