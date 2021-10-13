/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;




interface IPulsar {
    function totalSupply() external view returns (uint256);
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
}


interface IOracle {
    function getData() external view returns (uint256);
    function update() external;
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipRenounced(address indexed previousOwner);

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  function getUnlockTime() public view returns (uint256) {
    return _lockTime;
  }


  //Locks the contract for owner
  function lock() public onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    emit OwnershipRenounced(_owner);

  }

  function unlock() public {
    require(_previousOwner == msg.sender, "You don’t have permission to unlock");
    require(now > _lockTime , "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}


/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}


/**
 * @title Pulsar's Master
 * @dev Controller for an elastic supply currency based on the uFragments Ideal Money protocol a.k.a. Ampleforth.
 *      uFragments operates symmetrically on expansion and contraction. It will both split and
 *      combine coins to maintain a stable unit price.
 *
 *      This component regulates the token supply of the uFragments ERC20 token in response to
 *      market oracles.
 */
contract Master is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }

    event TransactionFailed(address indexed destination, uint index, bytes data);

    // Stable ordering is not guaranteed.
    Transaction[] public transactions;

    event LogRebase(
        uint256 indexed epoch,
        uint256 exchangeRate,
        int256 requestedSupplyAdjustment,
        uint256 timestampSec
    );

    IPulsar public pulsar;

    // Market oracle provides the PUL/USD exchange rate as an 18 decimal fixed point number.
    IOracle public marketOracle;

    // Price ceiling
    uint256 public ceiling;

    // More than this much time must pass between rebase operations.
    uint256 public rebaseCooldown;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 18;

    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 1500000 * 10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = ~(uint256(1) << 255) / MAX_RATE;

    // Rebase will remain restricted to the owner until the final Oracle is deployed and battle-tested.
    // Ownership will be renounced after this inital period.

    uint256 public targetRate;

    uint256 public peggedPrice;

    bool public rebaseLocked;

    bool public rebaseOverride = false;

    bool private allowSetInitalRate = true;

    bool public posRebaseEnabled;

    constructor(address _pulsar) public {
        targetRate = (2088 * 10**(DECIMALS-5));
        peggedPrice = (2088 * 10**(DECIMALS-5));

        ceiling = 50000 * 10 ** DECIMALS;

        rebaseCooldown = 4 seconds;
        epoch = 0;
        rebaseLocked = false;
        posRebaseEnabled = false;

        pulsar = IPulsar(_pulsar);
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Override to ensure that rebases aren't locked when this happens.
     */

    function renounceOwnership() public onlyOwner {
        require(!rebaseLocked);
        super.renounceOwnership();
    }

    function lockRebase() external onlyOwner {
        rebaseLocked = true;
    }

    /**
     * @notice Returns true if the cooldown timer has expired since the last rebase.
     *
     */

    function canRebase() public view returns (bool) {
      if (rebaseOverride) {
        return true;
      } else {
        return (!rebaseLocked  && lastRebaseTimestampSec.add(rebaseCooldown) < now);
      }
    }

    function cooldownExpiryTimestamp() public view returns (uint256) {
        return lastRebaseTimestampSec.add(rebaseCooldown);
    }

    function setInitialTargetRate(uint256 _initRate)
    external
    onlyOwner
    {
      if (allowSetInitalRate){
        targetRate = _initRate;
        allowSetInitalRate = false;
      }
      else {
        revert('Cannot set initial rate more than once');
      }
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     */

    function rebase() public {

        require(tx.origin == msg.sender);
        require(canRebase(), "Rebase not allowed");

        lastRebaseTimestampSec = now;

        epoch = epoch.add(1);

        (uint256 exchangeRate, int256 supplyDelta) = getRebaseValues();

        if (supplyDelta > 0 && !posRebaseEnabled) {
            supplyDelta = 0;
        }

        uint256 supplyAfterRebase = pulsar.rebase(epoch, supplyDelta);

        assert(supplyAfterRebase <= MAX_SUPPLY);

        marketOracle.update();

        if (exchangeRate < ceiling) {
            incrementTargetRate();
        } else {
            peggedPrice = targetRate;
            targetRate = ceiling;
            posRebaseEnabled = true;
        }

        emit LogRebase(epoch, exchangeRate, supplyDelta, now);
    }

    function overrideRebase() external onlyOwner {
        rebaseOverride = true;
        rebase();
        rebaseOverride = false;
    }

    // if exchange rate is above target rate, then move up the target rate
    function adjustTargetRate() external
    {
      uint256 exchangeRate = marketOracle.getData();

      if (exchangeRate > targetRate){
          peggedPrice = targetRate;
          targetRate = exchangeRate.mul(105).div(100);
      }

    }

    // increment by 1.011766375 to achieve 9.81% every 8hrs
    function incrementTargetRate() internal {

      uint256 newRate = targetRate.mul(105).div(100);

      if (newRate < ceiling)
      {
        peggedPrice = targetRate;
        targetRate = newRate;
      } else {
        peggedPrice = targetRate;
        targetRate = ceiling;
      }
    }

    /**
     * @notice Calculates the supplyDelta and returns the current set of values for the rebase
     *
     * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate) / rebaseLag
     *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
     *
     */

    function getRebaseValues() public view returns (uint256, int256) {

        uint256 exchangeRate = marketOracle.getData();

        if (exchangeRate > MAX_RATE) {
            exchangeRate = MAX_RATE;
        }

        int256 supplyDelta = computeSupplyDelta(exchangeRate);

        if (supplyDelta > 0 && pulsar.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
            supplyDelta = (MAX_SUPPLY.sub(pulsar.totalSupply())).toInt256Safe();
        }

        return (exchangeRate, supplyDelta);
    }


    /**
     * @return Computes the total supply adjustment in response to the exchange rate
     *         and the targetRate.
     */
    function computeSupplyDelta(uint256 rate)
        internal
        view
        returns (int256)
    {
        int256 targetRateSigned = targetRate.toInt256Safe();
        return pulsar.totalSupply().toInt256Safe()
            .mul(rate.toInt256Safe().sub(targetRateSigned))
            .div(targetRateSigned);
    }

    function setMarketOracle(IOracle marketOracle_)
        external
        onlyOwner
    {
        marketOracle = marketOracle_;
    }

   

}