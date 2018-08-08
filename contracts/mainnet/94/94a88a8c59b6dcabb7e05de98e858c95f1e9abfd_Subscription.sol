pragma solidity ^0.4.21;

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/subscription/Subscription.sol

contract Subscription is Ownable {
  uint256 constant UINT256_MAX = ~uint256(0);
  using SafeMath for uint256;

  /// @dev The token being use (C8)
  ERC20 public token;

  /// @dev Address where fee are collected
  address public wallet;

  /// @dev Cost per day of membership for C8 token
  uint256 public subscriptionRate;

  uint public fee;

  uint256 lastAppId;

  struct Pricing {
    uint256 day;
    uint256 price;
  }

  struct Application {
    /// @dev Application Id.
    uint256 appId;

    /// @dev Application name.
    bytes32 appName;

    /// @dev Beneficiary address.
    address beneficiary;

    /// @dev Owner address.
    address owner;

    /// @dev Timestamp of when Membership expires UserId=>timestamp of expire.
    mapping(uint256 => uint256) subscriptionExpiration;

    Pricing[] prices;
  }

  mapping(uint256 => Application) public applications;

  /**
   * Event for subscription purchase logging
   * @param purchaser who paid for the subscription
   * @param userId user id who will benefit from purchase
   * @param day day of subscription purchased
   * @param amount amount of subscription purchased in wei
   * @param expiration expiration of user subscription.
   */
  event SubscriptionPurchase(
    address indexed purchaser,
    uint256 indexed _appId,
    uint256 indexed userId,
    uint256 day,
    uint256 amount,
    uint256 expiration
  );

  event Registration(
    address indexed creator,
    uint256 _appId,
    bytes32 _appName,
    uint256 _price,
    address _beneficiary
  );

  function Subscription(
    uint _fee,
    address _fundWallet,
    ERC20 _token) public
  {
    require(_token != address(0));
    require(_fundWallet != address(0));
    require(_fee > 0);
    token = _token;
    wallet = _fundWallet;
    fee = _fee;
    lastAppId = 0;
  }

  function renewSubscriptionByDays(uint256 _appId, uint256 _userId, uint _day) external {
    Application storage app = applications[_appId];
    require(app.appId == _appId);
    require(_day >= 1);
    uint256 amount = getPrice(_appId, _day);
    require(amount > 0);

    uint256 txFee = processFee(amount);
    uint256 toAppOwner = amount.sub(txFee);
    require(token.transferFrom(msg.sender, app.beneficiary, toAppOwner));

    uint256 currentExpiration = app.subscriptionExpiration[_userId];
    // If their membership already expired...
    if (currentExpiration < now) {
      // ...use `now` as the starting point of their new subscription
      currentExpiration = now;
    }
    uint256 newExpiration = currentExpiration.add(_day.mul(1 days));
    app.subscriptionExpiration[_userId] = newExpiration;
    emit SubscriptionPurchase(
      msg.sender,
      _appId,
      _userId,
      _day,
      amount,
      newExpiration);
  }

  function registration(
    bytes32 _appName,
    uint256 _price,
    address _beneficiary)
  external
  {
    require(_appName != "");
    require(_price > 0);
    require(_beneficiary != address(0));
    lastAppId = lastAppId.add(1);
    Application storage app = applications[lastAppId];
    app.appId = lastAppId;
    app.appName = _appName;
    app.beneficiary = _beneficiary;
    app.owner = msg.sender;
    app.prices.push(Pricing({
      day : 1,
      price : _price
      }));
    emit Registration(
      msg.sender,
      lastAppId,
      _appName,
      _price,
      _beneficiary);
  }

  function setPrice(uint256 _appId, uint256[] _days, uint256[] _prices) external {
    Application storage app = applications[_appId];
    require(app.owner == msg.sender);
    app.prices.length = 0;
    for (uint i = 0; i < _days.length; i++) {
      require(_days[i] > 0);
      require(_prices[i] > 0);
      app.prices.push(Pricing({
        day : _days[i],
        price : _prices[i]
        }));
    }
  }

  /// @dev Set fee percent for Carboneum team.
  function setFee(uint _fee) external onlyOwner {
    fee = _fee;
  }

  function getExpiration(uint256 _appId, uint256 _userId) public view returns (uint256) {
    Application storage app = applications[_appId];
    return app.subscriptionExpiration[_userId];
  }

  function getPrice(uint256 _appId, uint256 _day) public view returns (uint256) {
    Application storage app = applications[_appId];
    uint256 amount = UINT256_MAX;
    for (uint i = 0; i < app.prices.length; i++) {
      if (_day == app.prices[i].day) {
        amount = app.prices[i].price;
      } else if (_day > app.prices[i].day) {
        uint256 rate = app.prices[i].price.div(app.prices[i].day);
        uint256 amountInPrice = _day.mul(rate);
        if (amountInPrice < amount) {
          amount = amountInPrice;
        }
      }
    }
    if (amount == UINT256_MAX) {
      amount = 0;
    }
    return amount;
  }

  function processFee(uint256 _weiAmount) internal returns (uint256) {
    uint256 txFee = _weiAmount.mul(fee).div(100);
    require(token.transferFrom(msg.sender, wallet, txFee));
    return txFee;
  }
}