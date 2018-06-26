pragma solidity ^0.4.24;

// File: contracts/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/IndieOnCrowdSale.sol

contract IndieOnCrowdSale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;
  uint256 public rate;
  uint256 public openingTime;
  uint256 public closingTime;
  uint256 public weiRaised;

  uint256 public  FirstWeekEnd;
  uint256 public  SecoundWeekStart;

  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token, uint _openingTime, uint _closingTime)
   public
   {
    require(_rate > 0);
    require(_wallet != address(0));
    require (_token != address(0));

    rate = _rate;
    wallet = _wallet;
    //indieTokenAddress = new IndieToken();
    token = _token;
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }

  /**
   * @dev Let user make a purchase
   */
  function () external payable {
    purchaseTokens(msg.sender);
  }

  function purchaseTokens(address buyer) public payable {

    uint256 weiAmount = msg.value;
    validatePurchase(buyer, weiAmount);

    // cCalculate token amount with Bonus
    uint256 tokens = getTokenAmount(weiAmount);
    // update fundRaising amount
    weiRaised = weiRaised.add(weiAmount);
    //Send tokens to token buyer, No time Locking
    token.transfer(buyer, tokens);

    emit TokenPurchase(msg.sender, buyer, weiAmount, tokens);
    sendFundsToWallet();
  }

  function validatePurchase( address buyer, uint256 weiAmount) onlyWhileOpen internal
  {
    require(buyer != address(0));
    require(weiAmount != 0);
  }

  /**
   * @dev Calculate the discount based on the current phase of sale.
   * @return Percentage of discount
   */
    function getDiscount() onlyWhileOpen internal returns (uint256) {
        if (now < FirstWeekEnd) // we are in first week
        return 160;
        else if (now > FirstWeekEnd && now < SecoundWeekStart) // in secound week
        return 130;
        else
        return 110;  //in third OR forth week
    }

  /**
   * @dev Calculate amount of tokens considering bonus
   * @param weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    uint discount = getDiscount();
    return weiAmount.mul(rate).div(100).mul(discount);
  }

  /**
   * @dev Transfer funds to cold wallet
   */
  function sendFundsToWallet() internal {
    wallet.transfer(msg.value);
  }
}