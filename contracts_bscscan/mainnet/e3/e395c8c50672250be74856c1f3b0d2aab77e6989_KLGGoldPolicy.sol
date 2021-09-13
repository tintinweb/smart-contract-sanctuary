/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT

/* 

    Kaly Gold $KLG is a goldpegged defi protocol that is based on Ampleforths elastic tokensupply model. 
    KLG is designed to maintain its base price target of 0.01g of Gold with a progammed inflation adjustment (rebase).
    
    Forked from Ampleforth: https://github.com/ampleforth/uFragments (Credits to Ampleforth team for implementation of rebasing on binance smart chain)
    
    GPL 3.0 license
    
    KLG_GoldPolicy.sol - KLG Gold Orchestrator Policy
  
*/

pragma solidity ^0.6.12;

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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

interface IKLG {
    function totalSupply() external view returns (uint256);
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
}

interface IGoldOracle {
    function getGoldPrice() external view returns (uint256, bool);
    function getMarketPrice() external view returns (uint256, bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

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
 * @title KLG $KLG Gold Supply Policy
 * @dev This is the extended orchestrator version of the KLG $KLG Ideal Gold Pegged DeFi protocol aka Ampleforth Gold ($KLG).
 *      KLG operates symmetrically on expansion and contraction. It will both split and
 *      combine coins to maintain a stable gold unit price against PAX gold.
 *
 *      This component regulates the token supply of the KLG ERC20 token in response to
 *      market oracles and gold price.
 */
contract KLGGoldPolicy is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    event LogRebase(
        uint256 indexed epoch,
        uint256 exchangeRate,
        uint256 goldPrice,
        int256 requestedSupplyAdjustment,
        uint256 timestampSec
    );

    IKLG public KLG;

    // Gold oracle provides the gold price and market price.
    IGoldOracle public goldOracle;

    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    // DECIMALS Fixed point number.
    uint256 public deviationThreshold;

    // The rebase lag parameter, used to dampen the applied supply adjustment by 1 / rebaseLag
    // Check setRebaseLag comments for more details.
    // Natural number, no decimal places.
    uint256 public rebaseLag;

    // More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 18;

    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 10**6 * 10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = ~(uint256(1) << 255) / MAX_RATE;

    constructor() public {
        deviationThreshold = 5 * 10 ** (DECIMALS-2);

        rebaseLag = 6;
        minRebaseTimeIntervalSec = 12 hours;
        lastRebaseTimestampSec = 0;
        epoch = 0;
    }

    /**
     * @notice Returns true if at least minRebaseTimeIntervalSec seconds have passed since last rebase.
     *
     */
     
    function canRebase() public view returns (bool) {
        return (lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now);
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     */     
    function rebase() external {

        require(canRebase(), "KLG Error: Insufficient time has passed since last rebase.");

        require(tx.origin == msg.sender);

        lastRebaseTimestampSec = now;

        epoch = epoch.add(1);
        
        (uint256 curGoldPrice, uint256 marketPrice, int256 targetRate, int256 supplyDelta) = getRebaseValues();

        uint256 supplyAfterRebase = KLG.rebase(epoch, supplyDelta);
        assert(supplyAfterRebase <= MAX_SUPPLY);
        
        emit LogRebase(epoch, marketPrice, curGoldPrice, supplyDelta, now);
    }
    
    /**
     * @notice Calculates the supplyDelta and returns the current set of values for the rebase
     *
     * @dev The supply adjustment equals the formula 
     *      (current price – base target price in usd) * total supply / (base target price in usd * lag 
     *       factor)
     */   
    function getRebaseValues() public view returns (uint256, uint256, int256, int256) {
        uint256 curGoldPrice;
        bool goldValid;
        (curGoldPrice, goldValid) = goldOracle.getGoldPrice();

        require(goldValid);
        
        uint256 marketPrice;
        bool marketValid;
        (marketPrice, marketValid) = goldOracle.getMarketPrice();
        
        require(marketValid);
        
        int256 goldPriceSigned = curGoldPrice.toInt256Safe();
        int256 marketPriceSigned = marketPrice.toInt256Safe();
        
        int256 rate = marketPriceSigned.sub(goldPriceSigned);
              
        if (marketPrice > MAX_RATE) {
            marketPrice = MAX_RATE;
        }

        int256 supplyDelta = computeSupplyDelta(marketPrice, curGoldPrice);

        if (supplyDelta > 0 && KLG.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
            supplyDelta = (MAX_SUPPLY.sub(KLG.totalSupply())).toInt256Safe();
        }

       return (curGoldPrice, marketPrice, rate, supplyDelta);
    }


    /**
     * @return Computes the total supply adjustment in response to the market price
     *         and the current gold price. 
     */
    function computeSupplyDelta(uint256 marketPrice, uint256 curGoldPrice)
        internal
        view
        returns (int256)
    {
        if (withinDeviationThreshold(marketPrice, curGoldPrice)) {
            return 0;
        }
        
        //(current price – base target price in usd) * total supply / (base target price in usd * lag factor)
        int256 goldPrice = curGoldPrice.toInt256Safe();
        int256 marketPrice = marketPrice.toInt256Safe();
        
        int256 delta = marketPrice.sub(goldPrice);
        int256 lagSpawn = goldPrice.mul(rebaseLag.toInt256Safe());
        
        return KLG.totalSupply().toInt256Safe()
            .mul(delta).div(lagSpawn);

    }

    /**
     * @notice Sets the rebase lag parameter.
     * @param rebaseLag_ The new rebase lag parameter.
     */
    function setRebaseLag(uint256 rebaseLag_)
        external
        onlyOwner
    {
        require(rebaseLag_ > 0);
        rebaseLag = rebaseLag_;
    }


    /**
     * @notice Sets the parameter which control the timing and frequency of
     *         rebase operations the minimum time period that must elapse between rebase cycles.
     * @param minRebaseTimeIntervalSec_ More than this much time must pass between rebase
     *        operations, in seconds.
     */
    function setRebaseTimingParameter(uint256 minRebaseTimeIntervalSec_)
        external
        onlyOwner
    {
        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
    }

    /**
     * @param rate The current market price
     * @param targetRate The current gold price
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 rate, uint256 targetRate)
        internal
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold)
            .div(10 ** DECIMALS);

        return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }
    
    /**
     * @notice Sets the reference to the KLG token governed.
     *         Can only be called once during initialization.
     * 
     * @param KLG_ The address of the KLG ERC20 token.
     */
    function setKLG(IKLG KLG_)
        external
        onlyOwner
    {
        require(KLG == IKLG(0)); 
        KLG = KLG_;    
    }

    /**
     * @notice Sets the reference to the KLG $KLG oracle.
     * @param _goldOracle The address of the KLG oracle contract.
     */
    function setGoldOracle(IGoldOracle _goldOracle)
        external
        onlyOwner
    {
        goldOracle = _goldOracle;
    }
    
}