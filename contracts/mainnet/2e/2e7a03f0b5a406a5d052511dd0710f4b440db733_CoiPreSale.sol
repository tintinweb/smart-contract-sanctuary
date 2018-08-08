pragma solidity 0.4.24;

// File: node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: contracts/CoiPreSale.sol

/**
 * @title CoiPreSale
 * @dev This crowdsale contract filters investments made according to
 *         - time
 *         - amount invested (in Wei)
 *      and forwards them to a predefined wallet in case all the filtering conditions are met.
 */
contract CoiPreSale is Pausable {
    using SafeMath for uint256;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // track the investments made from each address
    mapping(address => uint256) public investments;

    // total amount of funds raised (in wei)
    uint256 public weiRaised;

    uint256 public minWeiInvestment;
    uint256 public maxWeiInvestment;

    /**
     * @dev Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     */
    event Investment(address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        bytes payload);

    /**
     * @dev Constructor
     * @param _startTime the time to begin the crowdsale in seconds since the epoch
     * @param _endTime the time to begin the crowdsale in seconds since the epoch. Must be later than _startTime.
     * @param _minWeiInvestment the minimum amount for one single investment (in Wei)
     * @param _maxWeiInvestment the maximum amount for one single investment (in Wei)
     * @param _wallet the address to which funds will be directed to
     */
    constructor(uint256 _startTime,
        uint256 _endTime,
        uint256 _minWeiInvestment,
        uint256 _maxWeiInvestment,
        address _wallet) public {
        require(_endTime > _startTime);
        require(_minWeiInvestment > 0);
        require(_maxWeiInvestment > _minWeiInvestment);
        require(_wallet != address(0));

        startTime = _startTime;
        endTime = _endTime;

        minWeiInvestment = _minWeiInvestment;
        maxWeiInvestment = _maxWeiInvestment;

        wallet = _wallet;
    }

    /**
     * @dev External payable function to receive funds and buy tokens.
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Adapted Crowdsale#hasEnded
     * @return true if crowdsale event has started
     */
    function hasStarted() external view returns (bool) {
        return now >= startTime;
    }

    /**
     * @dev Adapted Crowdsale#hasEnded
     * @return true if crowdsale event has ended
     */
    function hasEnded() external view returns (bool) {
        return now > endTime;
    }

    /**
     * @dev Low level token purchase function
     * @param beneficiary the wallet to which the investment should be credited
     */
    function buyTokens(address beneficiary) public whenNotPaused payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // track how much wei is raised in total
        weiRaised = weiRaised.add(weiAmount);

        // track how much was transfered by the specific investor
        investments[beneficiary] = investments[beneficiary].add(weiAmount);

        emit Investment(msg.sender, beneficiary, weiAmount, msg.data);

        forwardFunds();
    }

    // send ether (wei) to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // overriding Crowdsale#validPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function validPurchase() internal view returns (bool) {
        if (msg.value < minWeiInvestment || msg.value > maxWeiInvestment) {
            return false;
        }
        bool withinPeriod = (now >= startTime) && (now <= endTime);  // 1128581 1129653
        return withinPeriod;
    }
}