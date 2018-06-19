pragma solidity ^0.4.18;

contract AccessControl {
  /// @dev The addresses of the accounts (or contracts) that can execute actions within each roles
  address public ceoAddress;
  address public cooAddress;

  /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
  bool public paused = false;

  /// @dev The AccessControl constructor sets the original C roles of the contract to the sender account
  function AccessControl() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /// @dev Access modifier for COO-only functionality
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  /// @dev Access modifier for any CLevel functionality
  modifier onlyCLevel() {
    require(msg.sender == ceoAddress || msg.sender == cooAddress);
    _;
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  /// @dev Assigns a new address to act as the COO. Only available to the current CEO
  /// @param _newCOO The address of the new COO
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

  /// @dev Modifier to allow actions only when the contract IS NOT paused
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /// @dev Modifier to allow actions only when the contract IS paused
  modifier whenPaused {
    require(paused);
    _;
  }

  /// @dev Pause the smart contract. Only can be called by the CEO
  function pause() public onlyCEO whenNotPaused {
     paused = true;
  }

  /// @dev Unpauses the smart contract. Only can be called by the CEO
  function unpause() public onlyCEO whenPaused {
    paused = false;
  }
}


contract RacingClubPresale is AccessControl {
  using SafeMath for uint256;

  // Max number of cars (includes sales and gifts)
  uint256 public constant MAX_CARS = 999;

  // Max number of cars to gift (includes unicorns)
  uint256 public constant MAX_CARS_TO_GIFT = 99;

  // Max number of unicorn cars to gift
  uint256 public constant MAX_UNICORNS_TO_GIFT = 9;

  // End date for the presale. No purchases can be made after this date.
  // Thursday, May 10, 2018 11:59:59 PM
  uint256 public constant PRESALE_END_TIMESTAMP = 1525996799;

  // Price limits to decrease the appreciation rate
  uint256 private constant PRICE_LIMIT_1 = 0.1 ether;

  // Appreciation steps for each price limit
  uint256 private constant APPRECIATION_STEP_1 = 0.0005 ether;
  uint256 private constant APPRECIATION_STEP_2 = 0.0001 ether;

  // Max count which can be bought with one transaction
  uint256 private constant MAX_ORDER = 5;

  // 0 - 9 valid Id&#39;s for cars
  uint256 private constant CAR_MODELS = 10;

  // The special car (the most rarest one) which can&#39;t be picked even with MAX_ORDER
  uint256 public constant UNICORN_ID = 0;

  // Maps any number from 0 - 255 to 0 - 9 car Id
  uint256[] private PROBABILITY_MAP = [4, 18, 32, 46, 81, 116, 151, 186, 221, 256];

  // Step by which the price should be changed
  uint256 public appreciationStep = APPRECIATION_STEP_1;

  // Current price of the car. The price appreciation is happening with each new sale.
  uint256 public currentPrice = 0.001 ether;

  // Overall cars count
  uint256 public carsCount;

  // Overall gifted cars count
  uint256 public carsGifted;

  // Gifted unicorn cars count
  uint256 public unicornsGifted;

  // A mapping from addresses to the carIds
  mapping (address => uint256[]) private ownerToCars;

  // A mapping from addresses to the upgrade packages
  mapping (address => uint256) private ownerToUpgradePackages;

  // Events
  event CarsPurchased(address indexed _owner, uint256[] _carIds, bool _upgradePackage, uint256 _pricePayed);
  event CarGifted(address indexed _receiver, uint256 _carId, bool _upgradePackage);

  // Buy a car. The cars are unique within the order.
  // If order count is 5 then one car can be preselected.
  function purchaseCars(uint256 _carsToBuy, uint256 _pickedId, bool _upgradePackage) public payable whenNotPaused {
    require(now < PRESALE_END_TIMESTAMP);
    require(_carsToBuy > 0 && _carsToBuy <= MAX_ORDER);
    require(carsCount + _carsToBuy <= MAX_CARS);

    uint256 priceToPay = calculatePrice(_carsToBuy, _upgradePackage);
    require(msg.value >= priceToPay);

    // return excess ether
    uint256 excess = msg.value.sub(priceToPay);
    if (excess > 0) {
      msg.sender.transfer(excess);
    }

    // initialize an array for the new cars
    uint256[] memory randomCars = new uint256[](_carsToBuy);
    // shows from which point the randomCars array should be filled
    uint256 startFrom = 0;

    // for MAX_ORDERs the first item is user picked
    if (_carsToBuy == MAX_ORDER) {
      require(_pickedId < CAR_MODELS);
      require(_pickedId != UNICORN_ID);

      randomCars[0] = _pickedId;
      startFrom = 1;
    }
    fillRandomCars(randomCars, startFrom);

    // add new cars to the owner&#39;s list
    for (uint256 i = 0; i < randomCars.length; i++) {
      ownerToCars[msg.sender].push(randomCars[i]);
    }

    // increment upgrade packages
    if (_upgradePackage) {
      ownerToUpgradePackages[msg.sender] += _carsToBuy;
    }

    CarsPurchased(msg.sender, randomCars, _upgradePackage, priceToPay);

    carsCount += _carsToBuy;
    currentPrice += _carsToBuy * appreciationStep;

    // update this once per purchase
    // to save the gas and to simplify the calculations
    updateAppreciationStep();
  }

  // MAX_CARS_TO_GIFT amout of cars are dedicated for gifts
  function giftCar(address _receiver, uint256 _carId, bool _upgradePackage) public onlyCLevel {
    // NOTE
    // Some promo results will be calculated after the presale,
    // so there is no need to check for the PRESALE_END_TIMESTAMP.

    require(_carId < CAR_MODELS);
    require(_receiver != address(0));

    // check limits
    require(carsCount < MAX_CARS);
    require(carsGifted < MAX_CARS_TO_GIFT);
    if (_carId == UNICORN_ID) {
      require(unicornsGifted < MAX_UNICORNS_TO_GIFT);
    }

    ownerToCars[_receiver].push(_carId);
    if (_upgradePackage) {
      ownerToUpgradePackages[_receiver] += 1;
    }

    CarGifted(_receiver, _carId, _upgradePackage);

    carsCount += 1;
    carsGifted += 1;
    if (_carId == UNICORN_ID) {
      unicornsGifted += 1;
    }

    currentPrice += appreciationStep;
    updateAppreciationStep();
  }

  function calculatePrice(uint256 _carsToBuy, bool _upgradePackage) private view returns (uint256) {
    // Arithmetic Sequence
    // A(n) = A(0) + (n - 1) * D
    uint256 lastPrice = currentPrice + (_carsToBuy - 1) * appreciationStep;

    // Sum of the First n Terms of an Arithmetic Sequence
    // S(n) = n * (a(1) + a(n)) / 2
    uint256 priceToPay = _carsToBuy * (currentPrice + lastPrice) / 2;

    // add an extra amount for the upgrade package
    if (_upgradePackage) {
      if (_carsToBuy < 3) {
        priceToPay = priceToPay * 120 / 100; // 20% extra
      } else if (_carsToBuy < 5) {
        priceToPay = priceToPay * 115 / 100; // 15% extra
      } else {
        priceToPay = priceToPay * 110 / 100; // 10% extra
      }
    }

    return priceToPay;
  }

  // Fill unique random cars into _randomCars starting from _startFrom
  // as some slots may be already filled
  function fillRandomCars(uint256[] _randomCars, uint256 _startFrom) private view {
    // All random cars for the current purchase are generated from this 32 bytes.
    // All purchases within a same block will get different car combinations
    // as current price is changed at the end of the purchase.
    //
    // We don&#39;t need super secure random algorithm as it&#39;s just presale
    // and if someone can time the block and grab the desired car we are just happy for him / her
    bytes32 rand32 = keccak256(currentPrice, now);
    uint256 randIndex = 0;
    uint256 carId;

    for (uint256 i = _startFrom; i < _randomCars.length; i++) {
      do {
        // the max number for one purchase is limited to 5
        // 32 tries are more than enough to generate 5 unique numbers
        require(randIndex < 32);
        carId = generateCarId(uint8(rand32[randIndex]));
        randIndex++;
      } while(alreadyContains(_randomCars, carId, i));
      _randomCars[i] = carId;
    }
  }

  // Generate a car ID from the given serial number (0 - 255)
  function generateCarId(uint256 _serialNumber) private view returns (uint256) {
    for (uint256 i = 0; i < PROBABILITY_MAP.length; i++) {
      if (_serialNumber < PROBABILITY_MAP[i]) {
        return i;
      }
    }
    // we should not reach to this point
    assert(false);
  }

  // Check if the given value is already in the list.
  // By default all items are 0 so _to is used explicitly to validate 0 values.
  function alreadyContains(uint256[] _list, uint256 _value, uint256 _to) private pure returns (bool) {
    for (uint256 i = 0; i < _to; i++) {
      if (_list[i] == _value) {
        return true;
      }
    }
    return false;
  }

  function updateAppreciationStep() private {
    // this method is called once per purcahse
    // so use &#39;greater than&#39; not to miss the limit
    if (currentPrice > PRICE_LIMIT_1) {
      // don&#39;t update if there is no change
      if (appreciationStep != APPRECIATION_STEP_2) {
        appreciationStep = APPRECIATION_STEP_2;
      }
    }
  }

  function carCountOf(address _owner) public view returns (uint256 _carCount) {
    return ownerToCars[_owner].length;
  }

  function carOfByIndex(address _owner, uint256 _index) public view returns (uint256 _carId) {
    return ownerToCars[_owner][_index];
  }

  function carsOf(address _owner) public view returns (uint256[] _carIds) {
    return ownerToCars[_owner];
  }

  function upgradePackageCountOf(address _owner) public view returns (uint256 _upgradePackageCount) {
    return ownerToUpgradePackages[_owner];
  }

  function allOf(address _owner) public view returns (uint256[] _carIds, uint256 _upgradePackageCount) {
    return (ownerToCars[_owner], ownerToUpgradePackages[_owner]);
  }

  function getStats() public view returns (uint256 _carsCount, uint256 _carsGifted, uint256 _unicornsGifted, uint256 _currentPrice, uint256 _appreciationStep) {
    return (carsCount, carsGifted, unicornsGifted, currentPrice, appreciationStep);
  }

  function withdrawBalance(address _to, uint256 _amount) public onlyCEO {
    if (_amount == 0) {
      _amount = address(this).balance;
    }

    if (_to == address(0)) {
      ceoAddress.transfer(_amount);
    } else {
      _to.transfer(_amount);
    }
  }


  // Raffle
  // max count of raffle participants
  uint256 public raffleLimit = 50;

  // list of raffle participants
  address[] private raffleList;

  // Events
  event Raffle2Registered(address indexed _iuser, address _user);
  event Raffle3Registered(address _user);

  function isInRaffle(address _address) public view returns (bool) {
    for (uint256 i = 0; i < raffleList.length; i++) {
      if (raffleList[i] == _address) {
        return true;
      }
    }
    return false;
  }

  function getRaffleStats() public view returns (address[], uint256) {
    return (raffleList, raffleLimit);
  }

  function drawRaffle(uint256 _carId) public onlyCLevel {
    bytes32 rand32 = keccak256(now, raffleList.length);
    uint256 winner = uint(rand32) % raffleList.length;

    giftCar(raffleList[winner], _carId, true);
  }

  function resetRaffle() public onlyCLevel {
    delete raffleList;
  }

  function setRaffleLimit(uint256 _limit) public onlyCLevel {
    raffleLimit = _limit;
  }

  // Raffle v1
  function registerForRaffle() public {
    require(raffleList.length < raffleLimit);
    require(!isInRaffle(msg.sender));
    raffleList.push(msg.sender);
  }

  // Raffle v2
  function registerForRaffle2() public {
    Raffle2Registered(msg.sender, msg.sender);
  }

  // Raffle v3
  function registerForRaffle3() public payable {
    Raffle3Registered(msg.sender);
  }
}


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