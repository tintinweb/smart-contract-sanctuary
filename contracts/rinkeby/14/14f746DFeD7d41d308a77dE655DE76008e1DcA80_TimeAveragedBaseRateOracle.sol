/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

/*
    .'''''''''''..     ..''''''''''''''''..       ..'''''''''''''''..
    .;;;;;;;;;;;'.   .';;;;;;;;;;;;;;;;;;,.     .,;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;,.    .,;;;;;;;;;;;;;;;;;;,.
    .;;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.   .;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;;;;'.  .';;;;;;;;;;;;;;;;;;;;;;,. .';;;;;;;;;;;;;;;;;;;;;,.
    ';;;;;,..   .';;;;;;;;;;;;;;;;;;;;;;;,..';;;;;;;;;;;;;;;;;;;;;;,.
    ......     .';;;;;;;;;;;;;,'''''''''''.,;;;;;;;;;;;;;,'''''''''..
              .,;;;;;;;;;;;;;.           .,;;;;;;;;;;;;;.
             .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
            .,;;;;;;;;;;;;,.           .,;;;;;;;;;;;;,.
           .,;;;;;;;;;;;;,.           .;;;;;;;;;;;;;,.     .....
          .;;;;;;;;;;;;;'.         ..';;;;;;;;;;;;;'.    .',;;;;,'.
        .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.   .';;;;;;;;;;.
       .';;;;;;;;;;;;;'.         .';;;;;;;;;;;;;;'.    .;;;;;;;;;;;,.
      .,;;;;;;;;;;;;;'...........,;;;;;;;;;;;;;;.      .;;;;;;;;;;;,.
     .,;;;;;;;;;;;;,..,;;;;;;;;;;;;;;;;;;;;;;;,.       ..;;;;;;;;;,.
    .,;;;;;;;;;;;;,. .,;;;;;;;;;;;;;;;;;;;;;;,.          .',;;;,,..
   .,;;;;;;;;;;;;,.  .,;;;;;;;;;;;;;;;;;;;;;,.              ....
    ..',;;;;;;;;,.   .,;;;;;;;;;;;;;;;;;;;;,.
       ..',;;;;'.    .,;;;;;;;;;;;;;;;;;;;'.
          ...'..     .';;;;;;;;;;;;;;,,,'.
                       ...............
*/

// https://github.com/trusttoken/smart-contracts
// Dependency file: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

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


// Dependency file: contracts/common/Initializable.sol

// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/v3.0.0/contracts/Initializable.sol
// Added public isInitialized() view of private initialized bool.

// pragma solidity 0.6.10;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    /**
     * @dev Return true if and only if the contract has been initialized
     * @return whether the contract has been initialized
     */
    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


// Dependency file: contracts/common/UpgradeableClaimable.sol

// pragma solidity 0.6.10;

// import {Context} from "@openzeppelin/contracts/GSN/Context.sol";

// import {Initializable} from "contracts/common/Initializable.sol";

/**
 * @title UpgradeableClaimable
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. Since
 * this contract combines Claimable and UpgradableOwnable contracts, ownership
 * can be later change via 2 step method {transferOwnership} and {claimOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract UpgradeableClaimable is Initializable, Context {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting a custom initial owner of choice.
     * @param __owner Initial owner of contract to be set.
     */
    function initialize(address __owner) internal initializer {
        _owner = __owner;
        emit OwnershipTransferred(address(0), __owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable: caller is not the pending owner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity ^0.6.0;

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


// Dependency file: contracts/truefi2/interface/IAaveLendingPool.sol

// pragma solidity 0.6.10;

interface IAaveLendingPool {
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 configuration,
            uint128 liquidityIndex,
            uint128 variableBorrowIndex,
            uint128 currentLiquidityRate,
            uint128 currentVariableBorrowRate,
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            address interestRateStrategyAddress,
            uint8 id
        );
}


// Dependency file: contracts/truefi2/SpotBaseRateOracle.sol

// pragma solidity 0.6.10;

// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
// import {IAaveLendingPool} from "contracts/truefi2/interface/IAaveLendingPool.sol";

/**
 * @title SpotBaseRateOracle
 * @dev Oracle to get spot rates from different lending protocols
 */
contract SpotBaseRateOracle {
    using SafeMath for uint256;

    /// @dev Aave lending pool contract
    IAaveLendingPool public immutable aaveLendingPool;

    /// @dev constructor which sets aave pool to `_aaveLendingPool`
    constructor(IAaveLendingPool _aaveLendingPool) public {
        aaveLendingPool = _aaveLendingPool;
    }

    /**
     * @dev Get rate for an `asset`
     * @param asset Asset to get rate for
     * @return Borrow rate for `asset`
     */
    function getRate(address asset) external view returns (uint256) {
        return _getAaveVariableBorrowAPY(asset);
    }

    /**
     * @dev Internal function to get Aave variable borrow apy for `asset`
     * @return Variable borrow rate for an asset
     */
    function _getAaveVariableBorrowAPY(address asset) internal view returns (uint256) {
        (, , , , uint128 currentVariableBorrowRate, , , , , , , ) = aaveLendingPool.getReserveData(asset);
        return uint256(currentVariableBorrowRate).div(1e23);
    }
}


// Dependency file: contracts/truefi2/interface/ITimeAveragedBaseRateOracle.sol

// pragma solidity 0.6.10;

interface ITimeAveragedBaseRateOracle {
    function calculateAverageAPY(uint16 numberOfValues) external view returns (uint256);

    function getWeeklyAPY() external view returns (uint256);

    function getMonthlyAPY() external view returns (uint256);

    function getYearlyAPY() external view returns (uint256);
}


// Root file: contracts/truefi2/TimeAveragedBaseRateOracle.sol

pragma solidity 0.6.10;

// import {UpgradeableClaimable} from "contracts/common/UpgradeableClaimable.sol";
// import {SpotBaseRateOracle} from "contracts/truefi2/SpotBaseRateOracle.sol";
// import {ITimeAveragedBaseRateOracle} from "contracts/truefi2/interface/ITimeAveragedBaseRateOracle.sol";

// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title TimeAveragedBaseRateOracle
 * @dev Used to find the time averaged interest rate for TrueFi secured lending rate
 * - Uses a spot oracle to capture data points over time
 * - Finds and stores time-weighted average of borrow APYs
 */
contract TimeAveragedBaseRateOracle is UpgradeableClaimable, ITimeAveragedBaseRateOracle {
    using SafeMath for uint256;

    uint16 public constant BUFFER_SIZE = 365 + 1;

    // A cyclic buffer structure for storing running total (cumulative sum)
    // values and their respective timestamps.
    // currIndex points to the previously inserted value.
    struct RunningTotalsBuffer {
        uint256[BUFFER_SIZE] runningTotals;
        uint256[BUFFER_SIZE] timestamps;
        uint16 currIndex;
    }

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    SpotBaseRateOracle public spotOracle;
    address public asset;

    // A fixed amount of time to wait
    // to be able to update the totalsBuffer
    uint256 public cooldownTime;

    RunningTotalsBuffer public totalsBuffer;

    // ======= STORAGE DECLARATION END ===========

    event SpotBaseRateOracleChanged(SpotBaseRateOracle newSpotOracle);

    /**
     * @dev Throws if cooldown is on when updating the totalsBuffer
     */
    modifier offCooldown() {
        require(isOffCooldown(), "TimeAveragedBaseRateOracle: Buffer on cooldown");
        _;
    }

    /// @dev initialize
    function initialize(
        SpotBaseRateOracle _spotOracle,
        address _asset,
        uint256 _cooldownTime
    ) external initializer {
        UpgradeableClaimable.initialize(msg.sender);
        spotOracle = _spotOracle;
        asset = _asset;
        cooldownTime = _cooldownTime;

        totalsBuffer.timestamps[0] = block.timestamp;
    }

    /// @dev Get buffer size for this oracle
    function bufferSize() public virtual pure returns (uint16) {
        return BUFFER_SIZE;
    }

    /// @dev Set spot oracle to `newSpotOracle`
    function setSpotOracle(SpotBaseRateOracle newSpotOracle) public onlyOwner {
        spotOracle = newSpotOracle;
        emit SpotBaseRateOracleChanged(newSpotOracle);
    }

    /// @dev Return true if this contract is cooled down from the last update
    function isOffCooldown() public view returns (bool) {
        // get the last timestamp written into the buffer
        uint256 lastWritten = totalsBuffer.timestamps[totalsBuffer.currIndex];
        return block.timestamp >= lastWritten.add(cooldownTime);
    }

    /**
     * @dev Helper function to get contents of the totalsBuffer
     */
    function getTotalsBuffer()
        public
        view
        returns (
            uint256[BUFFER_SIZE] memory,
            uint256[BUFFER_SIZE] memory,
            uint16
        )
    {
        return (totalsBuffer.runningTotals, totalsBuffer.timestamps, totalsBuffer.currIndex);
    }

    /**
     * @dev Update the totalsBuffer:
     * Gets current variable borrow apy from a collateralized lending protocol
     * for chosen asset and writes down new total running value.
     * If the buffer is filled overwrites the oldest value
     * with a new one and updates its timestamp.
     */
    function update() public offCooldown {
        uint16 _currIndex = totalsBuffer.currIndex;
        uint16 nextIndex = (_currIndex + 1) % bufferSize();
        uint256 apy = spotOracle.getRate(asset);
        uint256 nextTimestamp = block.timestamp;
        uint256 dt = nextTimestamp.sub(totalsBuffer.timestamps[_currIndex]);
        totalsBuffer.runningTotals[nextIndex] = totalsBuffer.runningTotals[_currIndex].add(apy.mul(dt));
        totalsBuffer.timestamps[nextIndex] = nextTimestamp;
        totalsBuffer.currIndex = nextIndex;
    }

    /**
     * @dev Average apy is calculated by taking
     * the time-weighted average of the borrowing apys.
     * Essentially formula given below is used:
     *
     *           sum_{i=1}^{n} v_i * (t_i - t_{i-1})
     * avgAPY = ------------------------------------
     *                      t_n - t_0
     *
     * where v_i, t_i are values of the apys and their respective timestamps.
     * Index n corresponds to the most recent values and index 0 to the oldest ones.
     *
     * To avoid costly computations in a loop an optimization is used:
     * Instead of directly storing apys we store calculated numerators from the formula above.
     * This gives us most of the job done for every calculation.
     *
     * @param numberOfValues How many values of totalsBuffer should be involved in calculations.
     * @return Average apy.
     */
    function calculateAverageAPY(uint16 numberOfValues) public override view returns (uint256) {
        require(numberOfValues > 0, "TimeAveragedBaseRateOracle: Number of values should be greater than 0");
        require(numberOfValues < bufferSize(), "TimeAveragedBaseRateOracle: Number of values should be less than buffer size");

        uint16 _currIndex = totalsBuffer.currIndex;
        uint16 startIndex = (_currIndex + bufferSize() - numberOfValues) % bufferSize();

        if (totalsBuffer.timestamps[startIndex] == 0) {
            require(_currIndex > 0, "TimeAveragedBaseRateOracle: Cannot use buffer before any update call");
            startIndex = 0;
        }

        uint256 diff = totalsBuffer.runningTotals[_currIndex].sub(totalsBuffer.runningTotals[startIndex]);
        uint256 dt = totalsBuffer.timestamps[_currIndex].sub(totalsBuffer.timestamps[startIndex]);
        return diff.div(dt);
    }

    /**
     * @dev apy based on last 7 entries in totalsBuffer.
     */
    function getWeeklyAPY() public override view returns (uint256) {
        return calculateAverageAPY(7);
    }

    /**
     * @dev apy based on last 30 entries in totalsBuffer.
     */
    function getMonthlyAPY() public override view returns (uint256) {
        return calculateAverageAPY(30);
    }

    /**
     * @dev apy based on last 365 entries in totalsBuffer.
     */
    function getYearlyAPY() public override view returns (uint256) {
        return calculateAverageAPY(365);
    }
}