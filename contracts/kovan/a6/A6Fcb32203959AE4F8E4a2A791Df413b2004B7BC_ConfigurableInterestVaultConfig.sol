// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IVaultConfig.sol";
import "./interfaces/IWorkerConfig.sol";
import "./interfaces/InterestModel.sol";

contract ConfigurableInterestVaultConfig is IVaultConfig, Ownable {
  /// @notice Events
  event SetWhitelistedCaller(address indexed caller, address indexed addr, bool ok);
  event SetParams(
    address indexed caller,
    uint256 minDebtSize,
    uint256 reservePoolBps,
    uint256 killBps,
    address interestModel,
    address wrappedNative,
    address wNativeRelayer,
    uint256 killTreasuryBps,
    address treasury
  );
  event SetWorkers(address indexed caller, address worker, address workerConfig);
  event SetMaxKillBps(address indexed caller, uint256 maxKillBps);
  event SetWhitelistedLiquidator(address indexed caller, address indexed addr, bool ok);
  event SetApprovedAddStrategy(address indexed caller, address addStrat, bool ok);

  /// The minimum debt size per position.
  uint256 public override minDebtSize;
  /// The portion of interests allocated to the reserve pool.
  uint256 public override getReservePoolBps;
  /// The reward for successfully killing a position.
  uint256 public override getKillBps;
  /// Mapping for worker address to its configuration.
  mapping(address => IWorkerConfig) public workers;
  /// Interest rate model
  InterestModel public interestModel;
  /// address for wrapped native eg WBNB, WETH
  address public override getWrappedNativeAddr;
  /// address for wNtive Relayer
  address public override getWNativeRelayer;
  /// maximum killBps
  uint256 public maxKillBps;
  /// list of whitelisted callers
  mapping(address => bool) public override whitelistedCallers;
  // The portion of reward that will be transferred to treasury account after successfully killing a position.
  uint256 public override getKillTreasuryBps;
  // address of treasury account
  address public treasury;
  // Mapping of approved add strategies
  mapping(address => bool) public override approvedAddStrategies;
  // list of whitelisted liquidators
  mapping(address => bool) public override whitelistedLiquidators;

  constructor(
    uint256 _minDebtSize,
    uint256 _reservePoolBps,
    uint256 _killBps,
    InterestModel _interestModel,
    address _getWrappedNativeAddr,
    address _getWNativeRelayer,
    uint256 _getKillTreasuryBps,
    address _treasury
  ) public {
    maxKillBps = 500;
    setParams(
      _minDebtSize,
      _reservePoolBps,
      _killBps,
      _interestModel,
      _getWrappedNativeAddr,
      _getWNativeRelayer,
      _getKillTreasuryBps,
      _treasury
    );
  }

  /// @dev Set all the basic parameters. Must only be called by the owner.
  /// @param _minDebtSize The new minimum debt size value.
  /// @param _reservePoolBps The new interests allocated to the reserve pool value.
  /// @param _killBps The new reward for killing a position value.
  /// @param _interestModel The new interest rate model contract.
  /// @param _getKillTreasuryBps The portion of reward that will be transferred to treasury account after successfully killing a position.
  /// @param _treasury address of treasury account
  function setParams(
    uint256 _minDebtSize,
    uint256 _reservePoolBps,
    uint256 _killBps,
    InterestModel _interestModel,
    address _getWrappedNativeAddr,
    address _getWNativeRelayer,
    uint256 _getKillTreasuryBps,
    address _treasury
  ) public onlyOwner {
    require(
      _killBps + _getKillTreasuryBps <= maxKillBps,
      "ConfigurableInterestVaultConfig::setParams:: kill bps exceeded max kill bps"
    );

    minDebtSize = _minDebtSize;
    getReservePoolBps = _reservePoolBps;
    getKillBps = _killBps;
    interestModel = _interestModel;
    getWrappedNativeAddr = _getWrappedNativeAddr;
    getWNativeRelayer = _getWNativeRelayer;
    getKillTreasuryBps = _getKillTreasuryBps;
    treasury = _treasury;

    emit SetParams(
      _msgSender(),
      minDebtSize,
      getReservePoolBps,
      getKillBps,
      address(interestModel),
      getWrappedNativeAddr,
      getWNativeRelayer,
      getKillTreasuryBps,
      treasury
    );
  }

  /// @dev Set the configuration for the given workers. Must only be called by the owner.
  function setWorkers(address[] calldata addrs, IWorkerConfig[] calldata configs) external onlyOwner {
    require(addrs.length == configs.length, "ConfigurableInterestVaultConfig::setWorkers:: bad length");
    for (uint256 idx = 0; idx < addrs.length; idx++) {
      workers[addrs[idx]] = configs[idx];
      emit SetWorkers(_msgSender(), addrs[idx], address(configs[idx]));
    }
  }

  /// @dev Set whitelisted callers. Must only be called by the owner.
  function setWhitelistedCallers(address[] calldata callers, bool ok) external onlyOwner {
    for (uint256 idx = 0; idx < callers.length; idx++) {
      whitelistedCallers[callers[idx]] = ok;
      emit SetWhitelistedCaller(_msgSender(), callers[idx], ok);
    }
  }

  /// @dev Set approved add strategies. Must only be called by the owner.
  function setApprovedAddStrategy(address[] calldata addStrats, bool ok) external onlyOwner {
    for (uint256 idx = 0; idx < addStrats.length; idx++) {
      approvedAddStrategies[addStrats[idx]] = ok;
      emit SetApprovedAddStrategy(_msgSender(), addStrats[idx], ok);
    }
  }

  /// @dev Set max kill bps. Must only be called by the owner.
  function setMaxKillBps(uint256 _maxKillBps) external onlyOwner {
    require(_maxKillBps < 1000, "ConfigurableInterestVaultConfig::setMaxKillBps:: bad _maxKillBps");
    maxKillBps = _maxKillBps;
    emit SetMaxKillBps(_msgSender(), maxKillBps);
  }

  /// @dev Set whitelisted liquidators. Must only be called by the owner.
  function setWhitelistedLiquidators(address[] calldata callers, bool ok) external onlyOwner {
    for (uint256 idx = 0; idx < callers.length; idx++) {
      whitelistedLiquidators[callers[idx]] = ok;
      emit SetWhitelistedLiquidator(_msgSender(), callers[idx], ok);
    }
  }

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating) external view override returns (uint256) {
    return interestModel.getInterestRate(debt, floating);
  }

  /// @dev Return whether the given address is a worker.
  function isWorker(address worker) external view override returns (bool) {
    return address(workers[worker]) != address(0);
  }

  /// @dev Return whether the given worker accepts more debt. Revert on non-worker.
  function acceptDebt(address worker) external view override returns (bool) {
    return workers[worker].acceptDebt(worker);
  }

  /// @dev Return the work factor for the worker + debt, using 1e4 as denom. Revert on non-worker.
  function workFactor(address worker, uint256 debt) external view override returns (uint256) {
    return workers[worker].workFactor(worker, debt);
  }

  /// @dev Return the kill factor for the worker + debt, using 1e4 as denom. Revert on non-worker.
  function killFactor(address worker, uint256 debt) external view override returns (uint256) {
    return workers[worker].killFactor(worker, debt);
  }

  /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom.
  function rawKillFactor(address worker, uint256 debt) external view override returns (uint256) {
    return workers[worker].rawKillFactor(worker, debt);
  }

  /// @dev Return if worker is stable.
  function isWorkerStable(address worker) external view override returns (bool) {
    return workers[worker].isStable(worker);
  }

  /// @dev Return if pools is consistent
  function isWorkerReserveConsistent(address worker) external view override returns (bool) {
    return workers[worker].isReserveConsistent(worker);
  }

  /// @dev Return the treasuryAddr
  function getTreasuryAddr() external view override returns (address) {
    return treasury == address(0) ? 0x26Db8D48c611ED9CD6FA373fE97cAfBF8c416031 : treasury;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;

interface IVaultConfig {
  /// @dev Return minimum BaseToken debt size per position.
  function minDebtSize() external view returns (uint256);

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

  /// @dev Return the address of wrapped native token.
  function getWrappedNativeAddr() external view returns (address);

  /// @dev Return the address of wNative relayer.
  function getWNativeRelayer() external view returns (address);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint256);

  /// @dev Return the bps rate for Avada Kill caster.
  function getKillBps() external view returns (uint256);

  /// @dev Return if the caller is whitelisted.
  function whitelistedCallers(address caller) external returns (bool);

  /// @dev Return if the caller is whitelisted.
  function whitelistedLiquidators(address caller) external returns (bool);

  /// @dev Return if the given strategy is approved.
  function approvedAddStrategies(address addStrats) external returns (bool);

  /// @dev Return whether the given address is a worker.
  function isWorker(address worker) external view returns (bool);

  /// @dev Return whether the given worker accepts more debt. Revert on non-worker.
  function acceptDebt(address worker) external view returns (bool);

  /// @dev Return the work factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function workFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function killFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the kill factor for the worker + BaseToken debt without checking isStable, using 1e4 as denom. Revert on non-worker.
  function rawKillFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the portion of reward that will be transferred to treasury account after successfully killing a position.
  function getKillTreasuryBps() external view returns (uint256);

  /// @dev Return the address of treasury account
  function getTreasuryAddr() external view returns (address);

  /// @dev Return if worker is stable
  function isWorkerStable(address worker) external view returns (bool);

  /// @dev Return if reserve that worker is working with is consistent
  function isWorkerReserveConsistent(address worker) external view returns (bool);
}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;

interface IWorkerConfig {
  /// @dev Return whether the given worker accepts more debt.
  function acceptDebt(address worker) external view returns (bool);

  /// @dev Return the work factor for the worker + debt, using 1e4 as denom.
  function workFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the kill factor for the worker + debt, using 1e4 as denom.
  function killFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the kill factor for the worker + debt without checking isStable, using 1e4 as denom.
  function rawKillFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return if worker is stable.
  function isStable(address worker) external view returns (bool);

  /// @dev Revert if liquidity pool under manipulation
  function isReserveConsistent(address worker) external view returns (bool);
}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;

interface InterestModel {
  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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