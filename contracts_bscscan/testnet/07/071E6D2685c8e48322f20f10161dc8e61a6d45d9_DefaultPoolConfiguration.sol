pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IPoolConfiguration.sol";
import "./libraries/WadMath.sol";

/**
 * @title Default pool configuration contract
 * @notice Implements the configuration of the ERC20 token pool.
 * @author Alpha
 **/

contract DefaultPoolConfiguration is IPoolConfiguration, Ownable {
  using SafeMath for uint256;
  using WadMath for uint256;

  /**
   * @notice the borrow interest rate calculation
   * Borrow interest rate(%)
   *  ^
   *  |             |    /
   *  |             |   /
   *  |             |  /<------ rate slope 2
   *  |             | /
   *  |         ____|/
   *  |    ____/    |
   *  | __/<--------|-------- rate slope 1
   *  |/<-----------|-------- base borrow rate
   *  |-------------|------|  Utilization rate(%)
   *  0             80    100
   *               ^   ^
   *               |   | excess utilization rate
   *               | optimal utilization rate
   *
   * When the utilization rate is too high (over 80%) the the pool will use rate slope 2 to calculate
   * the borrow interest rate which grow very fast to protect the liquidity in the pool.
   */

  // optimal utilization rate at 80%
  uint256 public constant OPTIMAL_UTILIZATION_RATE = 0.8 * 1e18;
  // excess utilization rate at 20%
  uint256 public constant EXCESS_UTILIZATION_RATE = 0.2 * 1e18;

  uint256 public baseBorrowRate;
  uint256 public rateSlope1;
  uint256 public rateSlope2;
  uint256 public collateralPercent;
  uint256 public liquidationBonusPercent;

  constructor(
    uint256 _baseBorrowRate,
    uint256 _rateSlope1,
    uint256 _rateSlope2,
    uint256 _collateralPercent,
    uint256 _liquidationBonusPercent
  ) public {
    baseBorrowRate = _baseBorrowRate;
    rateSlope1 = _rateSlope1;
    rateSlope2 = _rateSlope2;
    collateralPercent = _collateralPercent;
    liquidationBonusPercent = _liquidationBonusPercent;
  }

  /**
   * @dev get base borrow rate of the ERC20 token pool
   * @return base borrow rate
   */
  function getBaseBorrowRate() external override(IPoolConfiguration) view returns (uint256) {
    return baseBorrowRate;
  }

  /**
   * @dev get collateral percent of the ERC20 token pool
   * @return collateral percent
   * Basically the collateral percent is the percent that liquidity can be use as collteral to cover the user's loan
   */
  function getCollateralPercent() external override(IPoolConfiguration) view returns (uint256) {
    return collateralPercent;
  }

  /**
   * @dev get the liquidation bonus of the ERC20 token pool
   * @return liquidation bonus percent
   * the liquidation bunus percent used for collateral amount calculation.
   * How many collateral that liquidator will receive when the liquidation is success.
   */
  function getLiquidationBonusPercent()
    external
    override(IPoolConfiguration)
    view
    returns (uint256)
  {
    return liquidationBonusPercent;
  }

  /**
   * @dev calculate the annual interest rate based on utilization rate
   * @param _totalBorrows the total borrows of the ERC20 token pool
   * @param _totalLiquidity the total liquidity of the ERC20 token of the pool
   * First, calculate the utilization rate as below formula
   * utilization rate = total borrows / (total borrows + available liquidity)
   * Second, calculate the annual interest rate
   * As the above graph which show the relative between the utilization rate and the borrow interest rate.
   * There are 2 cases:
   * 1. the utilization rate is less than or equal 80%
   * - the borrow interest rate = base borrow rate + (utilization rate * rate slope 1 / optimal utilization rate)
   * 2. the utilization rate is excessed 80%. In this case the borrow interest rate will be very high.
   * - the excess utilization rate ratio = (utilization rate - optimal utilization rate) / excess utilization rate
   * - the borrow interest rate = base borrow rate + rate slope 1 + (rate slope 2 * excess utilization rate ratio)
   */
  function calculateInterestRate(uint256 _totalBorrows, uint256 _totalLiquidity)
    external
    override(IPoolConfiguration)
    view
    returns (uint256)
  {
    uint256 utilizationRate = getUtilizationRate(_totalBorrows, _totalLiquidity);

    if (utilizationRate > OPTIMAL_UTILIZATION_RATE) {
      uint256 excessUtilizationRateRatio = utilizationRate.sub(OPTIMAL_UTILIZATION_RATE).wadDiv(
        EXCESS_UTILIZATION_RATE
      );
      return baseBorrowRate.add(rateSlope1).add(rateSlope2.wadMul(excessUtilizationRateRatio));
    } else {
      return
        baseBorrowRate.add(utilizationRate.wadMul(rateSlope1).wadDiv(OPTIMAL_UTILIZATION_RATE));
    }
  }

  /**
   * @dev get optimal utilization rate of the ERC20 token pool
   * @return the optimal utilization
   */
  function getOptimalUtilizationRate() external override view returns (uint256) {
    return OPTIMAL_UTILIZATION_RATE;
  }

  /**
   * @dev calculate the utilization rate
   * @param _totalBorrows the total borrows of the ERC20 token pool
   * @param _totalLiquidity the total liquidity of the ERC20 token of the pool
   * @return utilizationRate the utilization rate of the ERC20 pool
   */
  function getUtilizationRate(uint256 _totalBorrows, uint256 _totalLiquidity)
    public
    override
    view
    returns (uint256)
  {
    return (_totalLiquidity == 0) ? 0 : _totalBorrows.wadDiv(_totalLiquidity);
  }
}

pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title WadMath library
 * @notice The wad math library.
 * @author Alpha
 **/

library WadMath {
  using SafeMath for uint256;

  /**
   * @dev one WAD is equals to 10^18
   */
  uint256 internal constant WAD = 1e18;

  /**
   * @notice get wad
   */
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @notice a multiply by b in Wad unit
   * @return the result of multiplication
   */
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(b).div(WAD);
  }

  /**
   * @notice a divided by b in Wad unit
   * @return the result of division
   */
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(WAD).div(b);
  }
}

pragma solidity 0.6.11;

/**
 * @title Pool configuration interface
 * @notice The interface of pool configuration of the ERC20 token pool
 * @author Alpha
 **/

interface IPoolConfiguration {
  /**
   * @notice get optimal utilization rate of the ERC20 token pool
   * @return the optimal utilization
   */
  function getOptimalUtilizationRate() external view returns (uint256);

  /**
   * @notice get base borrow rate of the ERC20 token pool
   * @return the base borrow rate
   */
  function getBaseBorrowRate() external view returns (uint256);

  /**
   * @notice get the liquidation bonus percent to calculate the collateral amount of liquidation
   * @return the liquidation bonus percent
   */
  function getLiquidationBonusPercent() external view returns (uint256);

  /**
   * @notice get the collateral percent which is the percent that the liquidity can use as collateral
   * @return the collateral percent
   */
  function getCollateralPercent() external view returns (uint256);

  /**
   * @notice calculate the annual interest rate
   * @param _totalBorrows the total borrows of the ERC20 token pool
   * @param _totalLiquidity the total liquidity of the ERC20 token of the pool
   * @return borrowInterestRate an annual borrow interest rate
   */
  function calculateInterestRate(uint256 _totalBorrows, uint256 _totalLiquidity)
    external
    view
    returns (uint256 borrowInterestRate);

  /**
   * @notice calculate the utilization rate
   * @param _totalBorrows the total borrows of the ERC20 token pool
   * @param _totalLiquidity the total liquidity of the ERC20 token of the pool
   * @return utilizationRate the utilization rate of the ERC20 pool
   */
  function getUtilizationRate(uint256 _totalBorrows, uint256 _totalLiquidity)
    external
    view
    returns (uint256 utilizationRate);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}