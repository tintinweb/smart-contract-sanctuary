pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

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

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;


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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract CryptoPhoenixes is Ownable, Pausable {
  using SafeMath for uint256;

  address public subDev;
  Phoenix[] private phoenixes;
  uint256 public PHOENIX_POOL;
  uint256 public EXPLOSION_DENOMINATOR = 1000; //Eg explosivePower = 30 -> 3%
  bool public ALLOW_BETA = true;
  uint BETA_CUTOFF;

  // devFunds
  mapping (address => uint256) public devFunds;

  // dividends
  mapping (address => uint256) public userFunds;

  // Events
  event PhoenixPurchased(
    uint256 _phoenixId,
    address oldOwner,
    address newOwner,
    uint256 price,
    uint256 nextPrice
  );
  
  event PhoenixExploded(
      uint256 phoenixId,
      address owner,
      uint256 payout,
      uint256 price,
      uint nextExplosionTime
  );

  event WithdrewFunds(
    address owner
  );

  // Caps for price changes and cutoffs
  uint256 constant private QUARTER_ETH_CAP  = 0.25 ether;
  uint256 constant private ONE_ETH_CAP  = 1.0 ether;
  uint256 public BASE_PRICE = 0.0025 ether;
  uint256 public PRICE_CUTOFF = 1.0 ether;
  uint256 public HIGHER_PRICE_RESET_PERCENTAGE = 20;
  uint256 public LOWER_PRICE_RESET_PERCENTAGE = 10;

  // Struct to store Phoenix Data
  struct Phoenix {
    uint256 price;  // Current price of phoenix
    uint256 dividendPayout; // The percent of the dividends pool rewarded
    uint256 explosivePower; // Percentage that phoenix can claim from PHOENIX_POOL after explode() function is called
    uint cooldown; // Time it takes for phoenix to recharge till next explosion
    uint nextExplosionTime; // Time of next explosion
    address previousOwner;  // Owner of the phoenix who triggered explosion in previous round
    address currentOwner; // Owner of phoenix in current round
  }

// Check if game is in beta or not. Certain functions will be disabled after beta period ends.
  modifier inBeta() {
    require(ALLOW_BETA);
    _;
  }

// Main function to set the beta period and sub developer
  function CryptoPhoenixes(address _subDev) {
    BETA_CUTOFF = now + 90 * 1 days; //Allow 3 months to tweak parameters
    subDev = _subDev;
  }
  
// Function anyone can call to turn off beta, thus disabling some functions
  function closeBeta() {
    require(now >= BETA_CUTOFF);
    ALLOW_BETA = false;
  }

  function createPhoenix(uint256 _payoutPercentage, uint256 _explosivePower, uint _cooldown) onlyOwner public {
    
    var phoenix = Phoenix({
    price: BASE_PRICE,
    dividendPayout: _payoutPercentage,
    explosivePower: _explosivePower,
    cooldown: _cooldown,
    nextExplosionTime: now,
    previousOwner: address(0),
    currentOwner: this
    });

    phoenixes.push(phoenix);
  }

  function createMultiplePhoenixes(uint256[] _payoutPercentages, uint256[] _explosivePowers, uint[] _cooldowns) onlyOwner public {
    require(_payoutPercentages.length == _explosivePowers.length);
    require(_explosivePowers.length == _cooldowns.length);
    
    for (uint256 i = 0; i < _payoutPercentages.length; i++) {
      createPhoenix(_payoutPercentages[i],_explosivePowers[i],_cooldowns[i]);
    }
  }

  function getPhoenix(uint256 _phoenixId) public view returns (
    uint256 price,
    uint256 nextPrice,
    uint256 dividendPayout,
    uint256 effectivePayout,
    uint256 explosivePower,
    uint cooldown,
    uint nextExplosionTime,
    address previousOwner,
    address currentOwner
  ) {
    var phoenix = phoenixes[_phoenixId];
    price = phoenix.price;
    nextPrice = getNextPrice(phoenix.price);
    dividendPayout = phoenix.dividendPayout;
    effectivePayout = phoenix.dividendPayout.mul(10000).div(getTotalPayout());
    explosivePower = phoenix.explosivePower;
    cooldown = phoenix.cooldown;
    nextExplosionTime = phoenix.nextExplosionTime;
    previousOwner = phoenix.previousOwner;
    currentOwner = phoenix.currentOwner;
  }

/**
  * @dev Determines next price of token
  * @param _price uint256 ID of current price
*/
  function getNextPrice (uint256 _price) private pure returns (uint256 _nextPrice) {
    if (_price < QUARTER_ETH_CAP) {
      return _price.mul(140).div(100); //1.4x
    } else if (_price < ONE_ETH_CAP) {
      return _price.mul(130).div(100); //1.3x
    } else {
      return _price.mul(125).div(100); //1.25x
    }
  }

/**
  * @dev Set dividend payout of phoenix
  * @param _phoenixId id of phoenix
  * @param _payoutPercentage uint256 Desired payout percentage
*/
  function setDividendPayout (uint256 _phoenixId, uint256 _payoutPercentage) onlyOwner inBeta {
    Phoenix phoenix = phoenixes[_phoenixId];
    phoenix.dividendPayout = _payoutPercentage;
  }

/**
  * @dev Set explosive power of phoenix
  * @param _phoenixId id of phoenix
  * @param _explosivePower uint256 Desired claimable percentage from PHOENIX_POOL
*/
  function setExplosivePower (uint256 _phoenixId, uint256 _explosivePower) onlyOwner inBeta {
    Phoenix phoenix = phoenixes[_phoenixId];
    phoenix.explosivePower = _explosivePower;
  }

/**
  * @dev Set cooldown of phoenix
  * @param _phoenixId id of phoenix
  * @param _cooldown uint256 Desired cooldown time
*/
  function setCooldown (uint256 _phoenixId, uint256 _cooldown) onlyOwner inBeta {
    Phoenix phoenix = phoenixes[_phoenixId];
    phoenix.cooldown = _cooldown;
  }

/**
  * @dev Set price cutoff when determining phoenix price after explosion. To adjust for ETH price fluctuations
  * @param _price uint256 Price cutoff in wei
*/
  function setPriceCutoff (uint256 _price) onlyOwner {
    PRICE_CUTOFF = _price;
  }

/**
  * @dev Set price percentage for when price exceeds or equates to price cutoff to reset to
  * @param _percentage uint256 Desired percentage
*/
  function setHigherPricePercentage (uint256 _percentage) onlyOwner inBeta {
    require(_percentage > 0);
    require(_percentage < 100);
    HIGHER_PRICE_RESET_PERCENTAGE = _percentage;
  }

/**
  * @dev Set price percentage for when price is lower than price cutoff to reset to
  * @param _percentage uint256 Desired percentage
*/
  function setLowerPricePercentage (uint256 _percentage) onlyOwner inBeta {
    require(_percentage > 0);
    require(_percentage < 100);
    LOWER_PRICE_RESET_PERCENTAGE = _percentage;
  }

/**
  * @dev Set base price for phoenixes. To adjust for ETH price fluctuations
  * @param _amount uint256 Desired amount in wei
*/
  function setBasePrice (uint256 _amount) onlyOwner {
    require(_amount > 0);
    BASE_PRICE = _amount;
  }

/**
  * @dev Purchase show from previous owner
  * @param _phoenixId uint256 of token
*/
  function purchasePhoenix(uint256 _phoenixId) whenNotPaused public payable {
    Phoenix phoenix = phoenixes[_phoenixId];
    //Get current price of phoenix
    uint256 price = phoenix.price;

    // revert checks
    require(price > 0);
    require(msg.value >= price);
    //prevent multiple subsequent purchases
    require(outgoingOwner != msg.sender);

    //Get owners of phoenixes
    address previousOwner = phoenix.previousOwner;
    address outgoingOwner = phoenix.currentOwner;

    //Define Cut variables
    uint256 devCut;  
    uint256 dividendsCut; 
    uint256 previousOwnerCut;
    uint256 phoenixPoolCut;
    uint256 phoenixPoolPurchaseExcessCut;
    
    //Calculate excess
    uint256 purchaseExcess = msg.value.sub(price);

    //handle boundary case where we assign previousOwner to the user
    if (previousOwner == address(0)) {
        phoenix.previousOwner = msg.sender;
    }
    
    //Calculate cuts
    (devCut,dividendsCut,previousOwnerCut,phoenixPoolCut) = calculateCuts(price);

    // Amount payable to old owner minus the developer&#39;s and pools&#39; cuts.
    uint256 outgoingOwnerCut = price.sub(devCut);
    outgoingOwnerCut = outgoingOwnerCut.sub(dividendsCut);
    outgoingOwnerCut = outgoingOwnerCut.sub(previousOwnerCut);
    outgoingOwnerCut = outgoingOwnerCut.sub(phoenixPoolCut);
    
    // Take 2% cut from leftovers of overbidding
    phoenixPoolPurchaseExcessCut = purchaseExcess.mul(2).div(100);
    purchaseExcess = purchaseExcess.sub(phoenixPoolPurchaseExcessCut);
    phoenixPoolCut = phoenixPoolCut.add(phoenixPoolPurchaseExcessCut);

    // set new price
    phoenix.price = getNextPrice(price);

    // set new owner
    phoenix.currentOwner = msg.sender;

    //Actual transfer
    devFunds[owner] = devFunds[owner].add(devCut.mul(7).div(10)); //70% of dev cut goes to owner
    devFunds[subDev] = devFunds[subDev].add(devCut.mul(3).div(10)); //30% goes to other dev
    distributeDividends(dividendsCut);
    userFunds[previousOwner] = userFunds[previousOwner].add(previousOwnerCut);
    PHOENIX_POOL = PHOENIX_POOL.add(phoenixPoolCut);

    //handle boundary case where we exclude currentOwner == address(this) when transferring funds
    if (outgoingOwner != address(this)) {
      sendFunds(outgoingOwner,outgoingOwnerCut);
    }

    // Send refund to owner if needed
    if (purchaseExcess > 0) {
      sendFunds(msg.sender,purchaseExcess);
    }

    // raise event
    PhoenixPurchased(_phoenixId, outgoingOwner, msg.sender, price, phoenix.price);
  }

  function calculateCuts(uint256 _price) private pure returns (
    uint256 devCut, 
    uint256 dividendsCut,
    uint256 previousOwnerCut,
    uint256 phoenixPoolCut
    ) {
      // Calculate cuts
      // 2% goes to developers
      devCut = _price.mul(2).div(100);

      // 2.5% goes to dividends
      dividendsCut = _price.mul(25).div(1000); 

      // 0.5% goes to owner of phoenix in previous exploded round
      previousOwnerCut = _price.mul(5).div(1000);

      // 10-12% goes to phoenix pool
      phoenixPoolCut = calculatePhoenixPoolCut(_price);
    }

  function calculatePhoenixPoolCut (uint256 _price) private pure returns (uint256 _poolCut) {
      if (_price < QUARTER_ETH_CAP) {
          return _price.mul(12).div(100); //12%
      } else if (_price < ONE_ETH_CAP) {
          return _price.mul(11).div(100); //11%
      } else {
          return _price.mul(10).div(100); //10%
      }
  }

  function distributeDividends(uint256 _dividendsCut) private {
    uint256 totalPayout = getTotalPayout();

    for (uint256 i = 0; i < phoenixes.length; i++) {
      var phoenix = phoenixes[i];
      var payout = _dividendsCut.mul(phoenix.dividendPayout).div(totalPayout);
      userFunds[phoenix.currentOwner] = userFunds[phoenix.currentOwner].add(payout);
    }
  }

  function getTotalPayout() private view returns(uint256) {
    uint256 totalPayout = 0;

    for (uint256 i = 0; i < phoenixes.length; i++) {
      var phoenix = phoenixes[i];
      totalPayout = totalPayout.add(phoenix.dividendPayout);
    }

    return totalPayout;
  }
    
//Note that the previous and current owner will be the same person after this function is called
  function explodePhoenix(uint256 _phoenixId) whenNotPaused public {
      Phoenix phoenix = phoenixes[_phoenixId];
      require(msg.sender == phoenix.currentOwner);
      require(PHOENIX_POOL > 0);
      require(now >= phoenix.nextExplosionTime);
      
      uint256 payout = phoenix.explosivePower.mul(PHOENIX_POOL).div(EXPLOSION_DENOMINATOR);

      //subtract from phoenix_POOL
      PHOENIX_POOL = PHOENIX_POOL.sub(payout);
      
      //decrease phoenix price
      if (phoenix.price >= PRICE_CUTOFF) {
        phoenix.price = phoenix.price.mul(HIGHER_PRICE_RESET_PERCENTAGE).div(100);
      } else {
        phoenix.price = phoenix.price.mul(LOWER_PRICE_RESET_PERCENTAGE).div(100);
        if (phoenix.price < BASE_PRICE) {
          phoenix.price = BASE_PRICE;
          }
      }

      // set previous owner to be current owner, so he can get extra dividends next round
      phoenix.previousOwner = msg.sender;
      // reset cooldown
      phoenix.nextExplosionTime = now + (phoenix.cooldown * 1 minutes);
      
      // Finally, payout to user
      sendFunds(msg.sender,payout);
      
      //raise event
      PhoenixExploded(_phoenixId, msg.sender, payout, phoenix.price, phoenix.nextExplosionTime);
  }
  
/**
* @dev Try to send funds immediately
* If it fails, user has to manually withdraw.
*/
  function sendFunds(address _user, uint256 _payout) private {
    if (!_user.send(_payout)) {
      userFunds[_user] = userFunds[_user].add(_payout);
    }
  }

/**
* @dev Withdraw dev cut.
*/
  function devWithdraw() public {
    uint256 funds = devFunds[msg.sender];
    require(funds > 0);
    devFunds[msg.sender] = 0;
    msg.sender.transfer(funds);
  }

/**
* @dev Users can withdraw their accumulated dividends
*/
  function withdrawFunds() public {
    uint256 funds = userFunds[msg.sender];
    require(funds > 0);
    userFunds[msg.sender] = 0;
    msg.sender.transfer(funds);
    WithdrewFunds(msg.sender);
  }
}