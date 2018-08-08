pragma solidity ^0.4.18;

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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  /**
   * @param _wallet Vault address
   */
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

/**
 * @title LandSale
 * @dev Landsale contract is a timed, refundable crowdsale for land. It has
 * a tiered increasing price element based on number of land sold per type.
 * @notice We omit a fallback function to prevent accidental sends to this contract.
 */
contract LandSale is Ownable {
    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;

    uint256 constant public VILLAGE_START_PRICE = 1200000000000000; // 0.0012 ETH
    uint256 constant public TOWN_START_PRICE = 5000000000000000; // 0.005 ETH
    uint256 constant public CITY_START_PRICE = 20000000000000000; // 0.02 ETH

    uint256 constant public VILLAGE_INCREASE_RATE = 500000000000000; // 0.0005 ETH
    uint256 constant public TOWN_INCREASE_RATE = 2500000000000000; // 0.0025 ETH
    uint256 constant public CITY_INCREASE_RATE = 12500000000000000; // 0.0125 ETH

    // Address where funds are collected
    address public wallet;

    // Amount of wei raised
    uint256 public weiRaised;

    // minimum amount of funds to be raised in wei
    uint256 public goal;

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;

    // Array of addresses who purchased land via their ethereum address
    address[] public walletUsers;
    uint256 public walletUserCount;

    // Array of users who purchased land via other method (ex. CC)
    bytes32[] public ccUsers;
    uint256 public ccUserCount;

    // Number of each landType sold
    uint256 public villagesSold;
    uint256 public townsSold;
    uint256 public citiesSold;


    // 0 - Plot
    // 1 - Village
    // 2 - Town
    // 3 - City

    // user wallet address -> # of land
    mapping (address => uint256) public addressToNumVillages;
    mapping (address => uint256) public addressToNumTowns;
    mapping (address => uint256) public addressToNumCities;

    // user id hash -> # of land
    mapping (bytes32 => uint256) public userToNumVillages;
    mapping (bytes32 => uint256) public userToNumTowns;
    mapping (bytes32 => uint256) public userToNumCities;

    bool private paused = false;
    bool public isFinalized = false;

    /**
     * @dev Send events for every purchase. Also send an event when LandSale is complete
     */
    event LandPurchased(address indexed purchaser, uint256 value, uint8 landType, uint256 quantity);
    event LandPurchasedCC(bytes32 indexed userId, address indexed purchaser, uint8 landType, uint256 quantity);
    event Finalized();

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime && !paused);
        _;
    }

    /**
     * @dev Constructor. One-time set up of goal and opening/closing times of landsale
     */
    function LandSale(address _wallet, uint256 _goal,
                        uint256 _openingTime, uint256 _closingTime) public {
        require(_wallet != address(0));
        require(_goal > 0);
        require(_openingTime >= block.timestamp);
        require(_closingTime >= _openingTime);

        wallet = _wallet;
        vault = new RefundVault(wallet);
        goal = _goal;
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @dev Add new ethereum wallet users to array
     */
    function addWalletAddress(address walletAddress) private {
        if ((addressToNumVillages[walletAddress] == 0) &&
            (addressToNumTowns[walletAddress] == 0) &&
            (addressToNumCities[walletAddress] == 0)) {
            // only add address to array during first land purchase
            walletUsers.push(msg.sender);
            walletUserCount++;
        }
    }

    /**
     * @dev Add new CC users to array
     */
    function addCCUser(bytes32 user) private {
        if ((userToNumVillages[user] == 0) &&
            (userToNumTowns[user] == 0) &&
            (userToNumCities[user] == 0)) {
            // only add user to array during first land purchase
            ccUsers.push(user);
            ccUserCount++;
        }
    }

    /**
     * @dev Purchase a village. For bulk purchase, current price honored for all
     * villages purchased.
     */
    function purchaseVillage(uint256 numVillages) payable public onlyWhileOpen {
        require(msg.value >= (villagePrice()*numVillages));
        require(numVillages > 0);

        weiRaised = weiRaised.add(msg.value);

        villagesSold = villagesSold.add(numVillages);
        addWalletAddress(msg.sender);
        addressToNumVillages[msg.sender] = addressToNumVillages[msg.sender].add(numVillages);

        _forwardFunds();
        LandPurchased(msg.sender, msg.value, 1, numVillages);
    }

    /**
     * @dev Purchase a town. For bulk purchase, current price honored for all
     * towns purchased.
     */
    function purchaseTown(uint256 numTowns) payable public onlyWhileOpen {
        require(msg.value >= (townPrice()*numTowns));
        require(numTowns > 0);

        weiRaised = weiRaised.add(msg.value);

        townsSold = townsSold.add(numTowns);
        addWalletAddress(msg.sender);
        addressToNumTowns[msg.sender] = addressToNumTowns[msg.sender].add(numTowns);

        _forwardFunds();
        LandPurchased(msg.sender, msg.value, 2, numTowns);
    }

    /**
     * @dev Purchase a city. For bulk purchase, current price honored for all
     * cities purchased.
     */
    function purchaseCity(uint256 numCities) payable public onlyWhileOpen {
        require(msg.value >= (cityPrice()*numCities));
        require(numCities > 0);

        weiRaised = weiRaised.add(msg.value);

        citiesSold = citiesSold.add(numCities);
        addWalletAddress(msg.sender);
        addressToNumCities[msg.sender] = addressToNumCities[msg.sender].add(numCities);

        _forwardFunds();
        LandPurchased(msg.sender, msg.value, 3, numCities);
    }

    /**
     * @dev Accounting for the CC purchases for audit purposes (no actual ETH transfer here)
     */
    function purchaseLandWithCC(uint8 landType, bytes32 userId, uint256 num) public onlyOwner onlyWhileOpen {
        require(landType <= 3);
        require(num > 0);

        addCCUser(userId);

        if (landType == 3) {
            weiRaised = weiRaised.add(cityPrice()*num);
            citiesSold = citiesSold.add(num);
            userToNumCities[userId] = userToNumCities[userId].add(num);
        } else if (landType == 2) {
            weiRaised = weiRaised.add(townPrice()*num);
            townsSold = townsSold.add(num);
            userToNumTowns[userId] = userToNumTowns[userId].add(num);
        } else if (landType == 1) {
            weiRaised = weiRaised.add(villagePrice()*num);
            villagesSold = villagesSold.add(num);
            userToNumVillages[userId] = userToNumVillages[userId].add(num);
        }

        LandPurchasedCC(userId, msg.sender, landType, num);
    }

    /**
     * @dev Returns the current price of a village. Price raises every 10 purchases.
     */
    function villagePrice() view public returns(uint256) {
        return VILLAGE_START_PRICE.add((villagesSold.div(10).mul(VILLAGE_INCREASE_RATE)));
    }

    /**
     * @dev Returns the current price of a town. Price raises every 10 purchases
     */
    function townPrice() view public returns(uint256) {
        return TOWN_START_PRICE.add((townsSold.div(10).mul(TOWN_INCREASE_RATE)));
    }

    /**
     * @dev Returns the current price of a city. Price raises every 10 purchases
     */
    function cityPrice() view public returns(uint256) {
        return CITY_START_PRICE.add((citiesSold.div(10).mul(CITY_INCREASE_RATE)));
    }

    /**
     * @dev Allows owner to pause puchases during the landsale
     */
    function pause() onlyOwner public {
        paused = true;
    }

    /**
     * @dev Allows owner to resume puchases during the landsale
     */
    function resume() onlyOwner public {
        paused = false;
    }

    /**
     * @dev Allows owner to check the paused status
     * @return Whether landsale is paused
     */
    function isPaused () onlyOwner public view returns(bool) {
        return paused;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return block.timestamp > closingTime;
    }

    /**
     * @dev Investors can claim refunds here if crowdsale is unsuccessful
     */
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    /**
     * @dev Checks whether funding goal was reached.
     * @return Whether funding goal was reached
     */
    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }

    /**
     * @dev vault finalization task, called when owner calls finalize()
     */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasClosed());

        if (goalReached()) {
          vault.close();
        } else {
          vault.enableRefunds();
        }

        Finalized();

        isFinalized = true;
    }

    /**
     * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
     */
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }
}