/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Global Enums and Structs

library VestingEntries {
    struct VestingEntry {
        uint64 endTime;
        uint256 escrowAmount;
    }
    struct VestingEntryWithID {
        uint64 endTime;
        uint256 escrowAmount;
        uint256 entryID;
    }
}

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

// Part: IAddressResolver

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address);
}

// Part: IExchangeRates

interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    struct InversePricing {
        uint256 entryPoint;
        uint256 upperLimit;
        uint256 lowerLimit;
        bool frozenAtUpperLimit;
        bool frozenAtLowerLimit;
    }

    function owner() external view returns (address);

    function setOracle(address _oracle) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys)
        external
        view
        returns (bool);

    function canFreezeRate(bytes32 currencyKey) external view returns (bool);

    function currentRoundForRate(bytes32 currencyKey)
        external
        view
        returns (uint256);

    function currenciesUsingAggregator(address aggregator)
        external
        view
        returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
        );

    function effectiveValueAtRound(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    ) external view returns (uint256 value);

    function getCurrentRoundId(bytes32 currencyKey)
        external
        view
        returns (uint256);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint256 startingRoundId,
        uint256 startingTimestamp,
        uint256 timediff
    ) external view returns (uint256);

    function inversePricing(bytes32 currencyKey)
        external
        view
        returns (
            uint256 entryPoint,
            uint256 upperLimit,
            uint256 lowerLimit,
            bool frozenAtUpperLimit,
            bool frozenAtLowerLimit
        );

    function lastRateUpdateTimes(bytes32 currencyKey)
        external
        view
        returns (uint256);

    function oracle() external view returns (address);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint256 roundId)
        external
        view
        returns (uint256 rate, uint256 time);

    function rateAndUpdatedTime(bytes32 currencyKey)
        external
        view
        returns (uint256 rate, uint256 time);

    function rateAndInvalid(bytes32 currencyKey)
        external
        view
        returns (uint256 rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey)
        external
        view
        returns (uint256);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsFrozen(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint256);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint256 numRounds
    ) external view returns (uint256[] memory rates, uint256[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint256[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint256[] memory);

    // Mutative functions
    function freezeRate(bytes32 currencyKey) external;
}

// Part: IFeePool

interface IFeePool {
    // Views

    function FEE_ADDRESS() external view returns (address);

    function feesAvailable(address account)
        external
        view
        returns (uint256, uint256);

    function feePeriodDuration() external view returns (uint256);

    function isFeesClaimable(address account) external view returns (bool);

    function targetThreshold() external view returns (uint256);

    function totalFeesAvailable() external view returns (uint256);

    function totalRewardsAvailable() external view returns (uint256);

    // Mutative Functions
    function claimFees() external returns (bool);

    function claimOnBehalf(address claimingForAddress) external returns (bool);

    function closeCurrentFeePeriod() external;
}

// Part: IIssuer

interface IIssuer {
    // Views
    function anySynthOrSNXRateIsInvalid()
        external
        view
        returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer)
        external
        view
        returns (uint256);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey)
        external
        view
        returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer)
        external
        view
        returns (uint256 maxIssuable);

    function minimumStakeTime() external view returns (uint256);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint256 maxIssuable,
            uint256 alreadyIssued,
            uint256 totalSystemDebt
        );

    function synthsByAddress(address synthAddress)
        external
        view
        returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey, bool excludeEtherCollateral)
        external
        view
        returns (uint256);

    function transferableSynthetixAndAnyRateIsInvalid(
        address account,
        uint256 balance
    ) external view returns (uint256 transferable, bool anyRateIsInvalid);

    // Restricted: used internally to Synthetix
    function issueSynths(address from, uint256 amount) external;

    function issueSynthsOnBehalf(
        address issueFor,
        address from,
        uint256 amount
    ) external;

    function issueMaxSynths(address from) external;

    function issueMaxSynthsOnBehalf(address issueFor, address from) external;

    function burnSynths(address from, uint256 amount) external;

    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint256 amount
    ) external;

    function burnSynthsToTarget(address from) external;

    function burnSynthsToTargetOnBehalf(address burnForAddress, address from)
        external;
}

// Part: IReadProxy

interface IReadProxy {
    function target() external view returns (address);
}

// Part: IRewardEscrowV2

interface IRewardEscrowV2 {
    // Views
    function nextEntryId() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function numVestingEntries(address account) external view returns (uint256);

    function totalEscrowedAccountBalance(address account)
        external
        view
        returns (uint256);

    function totalVestedAccountBalance(address account)
        external
        view
        returns (uint256);

    function getVestingQuantity(address account, uint256[] calldata entryIDs)
        external
        view
        returns (uint256);

    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (VestingEntries.VestingEntryWithID[] memory);

    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (uint256[] memory);

    function getVestingEntryClaimable(address account, uint256 entryID)
        external
        view
        returns (uint256);

    function getVestingEntry(address account, uint256 entryID)
        external
        view
        returns (uint64, uint256);

    // Mutative functions
    function vest(uint256[] calldata entryIDs) external;

    function createEscrowEntry(
        address beneficiary,
        uint256 deposit,
        uint256 duration
    ) external;

    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external;

    function migrateVestingSchedule(address _addressToMigrate) external;

    function migrateAccountEscrowBalances(
        address[] calldata accounts,
        uint256[] calldata escrowBalances,
        uint256[] calldata vestedBalances
    ) external;

    // Account Merging
    function startMergingWindow() external;

    function mergeAccount(address accountToMerge, uint256[] calldata entryIDs)
        external;

    function nominateAccountToMerge(address account) external;

    function accountMergingIsOpen() external view returns (bool);

    // L2 Migration
    function importVestingEntries(
        address account,
        uint256 escrowedAmount,
        VestingEntries.VestingEntry[] calldata vestingEntries
    ) external;

    // Return amount of SNX transfered to SynthetixBridgeToOptimism deposit contract
    function burnForMigration(address account, uint256[] calldata entryIDs)
        external
        returns (
            uint256 escrowedAccountBalance,
            VestingEntries.VestingEntry[] memory vestingEntries
        );
}

// Part: ISushiRouter

interface ISushiRouter {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// Part: ISynthetix

interface ISynthetix {
    // Views
    function anySynthOrSNXRateIsInvalid()
        external
        view
        returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer)
        external
        view
        returns (uint256);

    function debtBalanceOf(address issuer, bytes32 currencyKey)
        external
        view
        returns (uint256);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuableSynths(address issuer)
        external
        view
        returns (uint256 maxIssuable);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint256 maxIssuable,
            uint256 alreadyIssued,
            uint256 totalSystemDebt
        );

    function synthsByAddress(address synthAddress)
        external
        view
        returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey)
        external
        view
        returns (uint256);

    function totalIssuedSynthsExcludeEtherCollateral(bytes32 currencyKey)
        external
        view
        returns (uint256);

    function transferableSynthetix(address account)
        external
        view
        returns (uint256 transferable);

    // Mutative Functions
    function burnSynths(uint256 amount) external;

    function burnSynthsOnBehalf(address burnForAddress, uint256 amount)
        external;

    function burnSynthsToTarget() external;

    function burnSynthsToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);

    function issueMaxSynths() external;

    function issueMaxSynthsOnBehalf(address issueForAddress) external;

    function issueSynths(uint256 amount) external;

    function issueSynthsOnBehalf(address issueForAddress, uint256 amount)
        external;

    function mint() external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntries
        );

    // Liquidations
    function liquidateDelinquentAccount(address account, uint256 susdAmount)
        external
        returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint256 amount) external;

    function mintSecondaryRewards(uint256 amount) external;

    function burnSecondary(address account, uint256 amount) external;
}


// Part: OpenZeppelin/[email protected]/Address

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Part: OpenZeppelin/[email protected]/Math

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: iearn-finance/[email protected]/HealthCheck

interface HealthCheck {
    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool);
}

// Part: IVault

interface IVault is IERC20 {
    function deposit() external;

    function pricePerShare() external view returns (uint256);

    function withdraw() external;

    function withdraw(uint256 amount) external;

    function withdraw(
        uint256 amount,
        address account,
        uint256 maxLoss
    ) external;

    function availableDepositLimit() external view returns (uint256);
}

// Part: OpenZeppelin/[email protected]/SafeERC20

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// Part: iearn-finance/[email protected]/VaultAPI

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

// Part: iearn-finance/[email protected]/BaseStrategy

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */

abstract contract BaseStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    string public metadataURI;

    // health checks
    bool public doHealthCheck;
    address public healthCheck;

    /**
     * @notice
     *  Used to track which version of `StrategyAPI` this Strategy
     *  implements.
     * @dev The Strategy's version must match the Vault's `API_VERSION`.
     * @return A string which holds the current API version of this contract.
     */
    function apiVersion() public pure returns (string memory) {
        return "0.4.2";
    }

    /**
     * @notice This Strategy's name.
     * @dev
     *  You can use this field to manage the "version" of this Strategy, e.g.
     *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
     *  `apiVersion()` function above.
     * @return This Strategy's name.
     */
    function name() external view virtual returns (string memory);

    /**
     * @notice
     *  The amount (priced in want) of the total assets managed by this strategy should not count
     *  towards Yearn's TVL calculations.
     * @dev
     *  You can override this field to set it to a non-zero value if some of the assets of this
     *  Strategy is somehow delegated inside another part of of Yearn's ecosystem e.g. another Vault.
     *  Note that this value must be strictly less than or equal to the amount provided by
     *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
     *  Also note that this value is used to determine the total assets under management by this
     *  strategy, for the purposes of computing the management fee in `Vault`
     * @return
     *  The amount of assets this strategy manages that should not be included in Yearn's Total Value
     *  Locked (TVL) calculation across it's ecosystem.
     */
    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedProfitFactor(uint256 profitFactor);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;

    // The minimum multiple that `callCost` must be above the credit/profit to
    // be "justifiable". See `setProfitFactor()` for more details.
    uint256 public profitFactor;

    // Use this to adjust the threshold at which running a debt causes a
    // harvest trigger. See `setDebtThreshold()` for more details.
    uint256 public debtThreshold;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // modifiers
    modifier onlyAuthorized() {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        _;
    }

    modifier onlyEmergencyAuthorized() {
        require(
            msg.sender == strategist || msg.sender == governance() || msg.sender == vault.guardian() || msg.sender == vault.management(),
            "!authorized"
        );
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist, "!strategist");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance(), "!authorized");
        _;
    }

    modifier onlyKeepers() {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management(),
            "!authorized"
        );
        _;
    }

    modifier onlyVaultManagers() {
        require(msg.sender == vault.management() || msg.sender == governance(), "!authorized");
        _;
    }

    constructor(address _vault) public {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }

    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @dev `_vault` should implement `VaultAPI`.
     * @param _vault The address of the Vault responsible for this Strategy.
     * @param _strategist The address to assign as `strategist`.
     * The strategist is able to change the reward address
     * @param _rewards  The address to use for pulling rewards.
     * @param _keeper The adddress of the _keeper. _keeper
     * can harvest and tend a strategy.
     */
    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        require(address(want) == address(0), "Strategy already initialized");

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, uint256(-1)); // Give Vault unlimited access (might save gas)
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;

        // initialize variables
        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;

        vault.approve(rewards, uint256(-1)); // Allow rewards to be pulled
    }

    function setHealthCheck(address _healthCheck) external onlyVaultManagers {
        healthCheck = _healthCheck;
    }

    function setDoHealthCheck(bool _doHealthCheck) external onlyVaultManagers {
        doHealthCheck = _doHealthCheck;
    }

    /**
     * @notice
     *  Used to change `strategist`.
     *
     *  This may only be called by governance or the existing strategist.
     * @param _strategist The new address to assign as `strategist`.
     */
    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }

    /**
     * @notice
     *  Used to change `keeper`.
     *
     *  `keeper` is the only address that may call `tend()` or `harvest()`,
     *  other than `governance()` or `strategist`. However, unlike
     *  `governance()` or `strategist`, `keeper` may *only* call `tend()`
     *  and `harvest()`, and no other authorized functions, following the
     *  principle of least privilege.
     *
     *  This may only be called by governance or the strategist.
     * @param _keeper The new address to assign as `keeper`.
     */
    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `rewards`. EOA or smart contract which has the permission
     *  to pull rewards from the vault.
     *
     *  This may only be called by the strategist.
     * @param _rewards The address to use for pulling rewards.
     */
    function setRewards(address _rewards) external onlyStrategist {
        require(_rewards != address(0));
        vault.approve(rewards, 0);
        rewards = _rewards;
        vault.approve(rewards, uint256(-1));
        emit UpdatedRewards(_rewards);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `profitFactor`. `profitFactor` is used to determine
     *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _profitFactor A ratio to multiply anticipated
     * `harvest()` gas cost against.
     */
    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }

    /**
     * @notice
     *  Sets how far the Strategy can go into loss without a harvest and report
     *  being required.
     *
     *  By default this is 0, meaning any losses would cause a harvest which
     *  will subsequently report the loss to the Vault for tracking. (See
     *  `harvestTrigger()` for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _debtThreshold How big of a loss this Strategy may carry without
     * being required to report to the Vault.
     */
    function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    /**
     * @notice
     *  Used to change `metadataURI`. `metadataURI` is used to store the URI
     * of the file describing the strategy.
     *
     *  This may only be called by governance or the strategist.
     * @param _metadataURI The URI that describe the strategy.
     */
    function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }

    /**
     * Resolve governance address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
    function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `prepareReturn()`.
     */
    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _liquidatedAmount, uint256 _loss);

    /**
     * Liquidate everything and returns the amount that got freed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     */

    function liquidateAllPositions() internal virtual returns (uint256 _amountFreed);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param callCostInWei The keeper's estimated gas cost to call `tend()` (in wei).
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        // We usually don't need tend, but if there are positions that need
        // active maintainence, overriding this function is how you would
        // signal for that.
        uint256 callCost = ethToWant(callCostInWei);
        return false;
    }

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `adjustPosition()`.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     */
    function tend() external onlyKeepers {
        // Don't take profits with this call, but adjust for better gains
        adjustPosition(vault.debtOutstanding());
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold` to adjust the
     *  strategist-controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/master/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param callCostInWei The keeper's estimated gas cost to call `harvest()` (in wei).
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        uint256 callCost = ethToWant(callCostInWei);
        StrategyParams memory params = vault.strategies(address(this));

        // Should not trigger if Strategy is not activated
        if (params.activation == 0) return false;

        // Should not trigger if we haven't waited long enough since previous harvest
        if (block.timestamp.sub(params.lastReport) < minReportDelay) return false;

        // Should trigger if hasn't been called in a while
        if (block.timestamp.sub(params.lastReport) >= maxReportDelay) return true;

        // If some amount is owed, pay it back
        // NOTE: Since debt is based on deposits, it makes sense to guard against large
        //       changes to the value from triggering a harvest directly through user
        //       behavior. This should ensure reasonable resistance to manipulation
        //       from user-initiated withdrawals as the outstanding debt fluctuates.
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        // Check for profits and losses
        uint256 total = estimatedTotalAssets();
        // Trigger if we have a loss to report
        if (total.add(debtThreshold) < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

        // Otherwise, only trigger if it "makes sense" economically (gas cost
        // is <N% of value moved)
        uint256 credit = vault.creditAvailable();
        return (profitFactor.mul(callCost) < credit.add(profit));
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding.sub(amountFreed);
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed.sub(debtOutstanding);
            }
            debtPayment = debtOutstanding.sub(loss);
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }

        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        adjustPosition(debtOutstanding);

        // call healthCheck contract
        if (doHealthCheck && healthCheck != address(0)) {
            require(HealthCheck(healthCheck).check(profit, loss, debtPayment, debtOutstanding, totalDebt), "!healthcheck");
        } else {
            doHealthCheck = true;
        }

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by the Vault.
     * @dev
     * The new Strategy's Vault must be the same as this Strategy's Vault.
     *  The migration process should be carefully performed to make sure all
     * the assets are migrated to the new address, which should have never
     * interacted with the vault before.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     * ```
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     * ```
     */
    function protectedTokens() internal view virtual returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyGovernance {
        require(_token != address(want), "!want");
        require(_token != address(vault), "!shares");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}

// File: Strategy.sol

contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant MIN_ISSUE = 50 * 1e18;
    uint256 public ratioThreshold = 1e15;
    uint256 public constant MAX_RATIO = type(uint256).max;
    uint256 public constant MAX_BPS = 10_000;

    address public constant susd =
        address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IReadProxy public constant readProxy =
        IReadProxy(address(0x4E3b31eB0E5CB73641EE1E65E7dCEFe520bA3ef2));
    address public constant WETH =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ISushiRouter public constant sushiswap =
        ISushiRouter(address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F));
    ISushiRouter public constant uniswap =
        ISushiRouter(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    ISushiRouter public router =
        ISushiRouter(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));

    uint256 public targetRatioMultiplier = 12_500;
    IVault public susdVault;

    // to keep track of next entry to vest
    uint256 public entryIDIndex = 0;
    // entryIDs of escrow rewards claimed and to be claimed by the Strategy
    uint256[] public entryIDs;

    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_REWARDESCROW_V2 = "RewardEscrowV2";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";

    // ********************** EVENTS **********************

    event RepayDebt(uint256 repaidAmount, uint256 debtAfterRepayment);

    // ********************** CONSTRUCTOR **********************

    constructor(address _vault, address _susdVault)
        public
        BaseStrategy(_vault)
    {
        susdVault = IVault(_susdVault);

        // max time between harvest to collect rewards from each epoch
        maxReportDelay = 7 * 24 * 3600;

        // To deposit sUSD in the sUSD vault
        IERC20(susd).safeApprove(address(_susdVault), type(uint256).max);
        // To exchange sUSD for SNX
        IERC20(susd).safeApprove(address(uniswap), type(uint256).max);
        IERC20(susd).safeApprove(address(sushiswap), type(uint256).max);
        // To exchange SNX for sUSD
        IERC20(want).safeApprove(address(uniswap), type(uint256).max);
        IERC20(want).safeApprove(address(sushiswap), type(uint256).max);

        // healthcheck
        healthCheck = 0xDDCea799fF1699e98EDF118e0629A974Df7DF012;
        doHealthCheck = true;
    }

    // ********************** SETTERS **********************
    function setRouter(uint256 _isSushi) external onlyAuthorized {
        if (_isSushi == uint256(1)) {
            router = sushiswap;
        } else if (_isSushi == uint256(0)) {
            router = uniswap;
        } else {
            revert("!invalid-arg. Use 1 for sushi. 0 for uni");
        }
    }

    function setTargetRatioMultiplier(uint256 _targetRatioMultiplier) external {
        require(
            msg.sender == governance() ||
                msg.sender == VaultAPI(address(vault)).management()
        );
        targetRatioMultiplier = _targetRatioMultiplier;
    }

    function setRatioThreshold(uint256 _ratioThreshold) external {
        require(
            msg.sender == governance() ||
                msg.sender == VaultAPI(address(vault)).management()
        );
        ratioThreshold = _ratioThreshold;
    }

    // This method is used to migrate the vault where we deposit the sUSD for yield. It should be rarely used
    function migrateSusdVault(IVault newSusdVault, uint256 maxLoss)
        external
        onlyGovernance
    {
        // we tolerate losses to avoid being locked in the vault if things don't work out
        // governance must take this into account before migrating
        susdVault.withdraw(
            susdVault.balanceOf(address(this)),
            address(this),
            maxLoss
        );
        IERC20(susd).safeApprove(address(susdVault), 0);

        susdVault = newSusdVault;
        IERC20(susd).safeApprove(address(newSusdVault), type(uint256).max);
        newSusdVault.deposit();
    }

    // ********************** MANUAL **********************

    function manuallyRepayDebt(uint256 amount) external onlyAuthorized {
        // To be used in case of emergencies, to operate the vault manually
        repayDebt(amount);
    }

    // ********************** YEARN STRATEGY **********************

    function name() external view override returns (string memory) {
        return "StrategySynthetixSusdMinter";
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        uint256 totalAssets =
            balanceOfWant().add(
                sUSDToWant(balanceOfSusdInVault().add(balanceOfSusd()))
            );
        uint256 totalLiabilities = sUSDToWant(balanceOfDebt());
        // NOTE: the ternary operator is required because debt can be higher than assets
        // due to i) increase in debt or ii) losses in invested assets
        return
            totalAssets > totalLiabilities
                ? totalAssets.sub(totalLiabilities)
                : 0;
    }

    function delegatedAssets() external view override returns (uint256) {
        return sUSDToWant(balanceOfSusdInVault());
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;

        claimProfits();
        vestNextRewardsEntry();

        uint256 totalAssetsAfterProfit = estimatedTotalAssets();

        _profit = totalAssetsAfterProfit > totalDebt
            ? totalAssetsAfterProfit.sub(totalDebt)
            : 0;

        // if the vault is claiming repayment of debt
        if (_debtOutstanding > 0) {
            uint256 _amountFreed = 0;
            (_amountFreed, _loss) = liquidatePosition(_debtOutstanding);
            _debtPayment = Math.min(_debtOutstanding, _amountFreed);

            if (_loss > 0) {
                _profit = 0;
            }
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        if (_debtOutstanding >= balanceOfWant()) {
            return;
        }

        // compare current ratio with target ratio
        uint256 _currentRatio = getCurrentRatio();
        // NOTE: target debt ratio is over 20% to maximize APY
        uint256 _targetRatio = getTargetRatio();
        uint256 _issuanceRatio = getIssuanceRatio();
        // burn debt (sUSD) if the ratio is too high
        // collateralisation_ratio = debt / collat

        if (
            _currentRatio > _targetRatio &&
            _currentRatio.sub(_targetRatio) >= ratioThreshold
        ) {
            // NOTE: min threshold to act on differences = 1e16 (ratioThreshold)
            // current debt ratio might be unhealthy
            // we need to repay some debt to get back to the optimal range
            uint256 _debtToRepay =
                balanceOfDebt().sub(getTargetDebt(_collateral()));
            repayDebt(_debtToRepay);
        } else if (
            _issuanceRatio > _currentRatio &&
            _issuanceRatio.sub(_currentRatio) >= ratioThreshold
        ) {
            // NOTE: min threshold to act on differences = 1e16 (ratioThreshold)
            // if there is enough collateral to issue Synth, issue it
            // this should put the c-ratio around 500% (i.e. debt ratio around 20%)
            uint256 _maxSynths = _synthetix().maxIssuableSynths(address(this));
            uint256 _debtBalance = balanceOfDebt();
            // only issue new debt if it is going to be used
            if (
                _maxSynths > _debtBalance &&
                _maxSynths.sub(_debtBalance) >= MIN_ISSUE
            ) {
                _synthetix().issueMaxSynths();
            }
        }

        // If there is susd in the strategy, send it to the susd vault
        // We do MIN_ISSUE instead of 0 since it might be dust
        if (balanceOfSusd() >= MIN_ISSUE) {
            susdVault.deposit();
        }
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        // if unlocked collateral balance is not enough, repay debt to unlock
        // enough `want` to repay debt.
        // unlocked collateral includes profit just claimed in `prepareReturn`
        uint256 unlockedWant = _unlockedWant();
        if (unlockedWant < _amountNeeded) {
            // NOTE: we use _unlockedWant because `want` balance is the total amount of staked + unstaked want (SNX)
            reduceLockedCollateral(_amountNeeded.sub(unlockedWant));
        }

        // Fetch the unlocked collateral for a second time
        // to update after repaying debt
        unlockedWant = _unlockedWant();
        // if not enough want in balance, it means the strategy lost `want`
        if (_amountNeeded > unlockedWant) {
            _liquidatedAmount = unlockedWant;
            _loss = _amountNeeded.sub(unlockedWant);
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        // totalDebt is 0 at this point
        liquidatePosition(balanceOfWant());
    }

    // ********************** OPERATIONS FUNCTIONS **********************

    function reduceLockedCollateral(uint256 amountToFree) internal {
        // amountToFree cannot be higher than the amount that is unlockable
        amountToFree = Math.min(amountToFree, _unlockableWant());

        if (amountToFree == 0) {
            return;
        }
        uint256 _currentDebt = balanceOfDebt();
        uint256 _newCollateral = balanceOfWant().sub(amountToFree); // in want (SNX)
        uint256 _targetDebt =
            wantToSUSD(_newCollateral).mul(getIssuanceRatio()).div(1e18); // in sUSD

        // NOTE: _newCollateral will always be < _lockedCollateral() so _targetDebt will always be < _currentDebt
        uint256 _amountToRepay = _currentDebt.sub(_targetDebt);

        repayDebt(_amountToRepay);
    }

    function repayDebt(uint256 amountToRepay) internal {
        // debt can grow over the amount of sUSD minted (see Synthetix docs)
        // if that happens, we might not have enough sUSD to repay debt
        // if we withdraw in this situation, we need to sell `want` to repay debt and would have losses
        // this can only be done if c-Ratio is over 272% (otherwise there is not enough unlocked)
        if (amountToRepay == 0) {
            return;
        }
        uint256 repaidAmount = 0;
        uint256 _debtBalance = balanceOfDebt();
        // max amount to be repaid is the total balanceOfDebt
        amountToRepay = Math.min(_debtBalance, amountToRepay);

        // in case the strategy is going to repay almost all debt, it should repay the total amount of debt
        if (
            _debtBalance > amountToRepay &&
            _debtBalance.sub(amountToRepay) <= MIN_ISSUE
        ) {
            amountToRepay = _debtBalance;
        }

        uint256 currentSusdBalance = balanceOfSusd();
        if (amountToRepay > currentSusdBalance) {
            // there is not enough balance in strategy to repay debt

            // we withdraw from susdvault
            uint256 _withdrawAmount = amountToRepay.sub(currentSusdBalance);
            withdrawFromSUSDVault(_withdrawAmount);
            // we fetch sUSD balance for a second time and check if now there is enough
            currentSusdBalance = balanceOfSusd();
            if (amountToRepay > currentSusdBalance) {
                // there was not enough balance in strategy and sUSDvault to repay debt

                // debt is too high to be repaid using current funds, the strategy should:
                // 1. repay max amount of debt
                // 2. sell unlocked want to buy required sUSD to pay remaining debt
                // 3. repay debt

                if (currentSusdBalance > 0) {
                    // we burn the full sUSD balance to unlock `want` (SNX) in order to sell
                    if (burnSusd(currentSusdBalance)) {
                        // subject to minimumStakePeriod
                        // if successful burnt, update remaining amountToRepay
                        // repaidAmount is previous debt minus current debt
                        repaidAmount = _debtBalance.sub(balanceOfDebt());
                    }
                }
                // buy enough sUSD to repay outstanding debt, selling `want` (SNX)
                // or maximum sUSD with `want` available
                uint256 amountToBuy =
                    Math.min(
                        _getSusdForWant(_unlockedWant()),
                        amountToRepay.sub(repaidAmount)
                    );
                if (amountToBuy > 0) {
                    buySusdWithWant(amountToBuy);
                }
                // amountToRepay should equal balanceOfSusd() (we just bought `amountToRepay` sUSD)
            }
        }

        // repay sUSD debt by burning the synth
        if (amountToRepay > repaidAmount) {
            if (burnSusd(amountToRepay.sub(repaidAmount))) {
                // this method is subject to minimumStakePeriod (see Synthetix docs)
                repaidAmount = amountToRepay;
            }
        }
        emit RepayDebt(repaidAmount, balanceOfDebt());
    }

    // two profit sources: Synthetix protocol and Yearn sUSD Vault
    function claimProfits() internal returns (bool) {
        uint256 feesAvailable;
        uint256 rewardsAvailable;
        (feesAvailable, rewardsAvailable) = _getFeesAvailable();

        if (feesAvailable > 0 || rewardsAvailable > 0) {
            // claim fees from Synthetix
            // claim fees (in sUSD) and rewards (in want (SNX))
            // Synthetix protocol requires issuers to have a c-ratio above 500%
            // to be able to claim fees so we need to burn some sUSD

            // NOTE: we use issuanceRatio because that is what will put us on 500% c-ratio (i.e. 20% debt ratio)
            uint256 _targetDebt =
                getIssuanceRatio().mul(wantToSUSD(_collateral())).div(1e18);
            uint256 _balanceOfDebt = balanceOfDebt();
            bool claim = true;

            if (_balanceOfDebt > _targetDebt) {
                uint256 _requiredPayment = _balanceOfDebt.sub(_targetDebt);
                uint256 _maxCash =
                    balanceOfSusd().add(balanceOfSusdInVault()).mul(50).div(
                        100
                    );
                // only claim rewards if the required payment to burn debt up to c-ratio 500%
                // is less than 50% of available cash (both in strategy and in sUSD vault)
                claim = _requiredPayment <= _maxCash;
            }

            if (claim) {
                // we need to burn sUSD to target
                burnSusdToTarget();

                // if a vesting entry is going to be created,
                // we save its ID to keep track of its vesting
                if (rewardsAvailable > 0) {
                    entryIDs.push(_rewardEscrowV2().nextEntryId());
                }
                // claimFees() will claim both sUSD fees and put SNX rewards in the escrow (in the prev. saved entry)
                _feePool().claimFees();
            }
        }

        // claim profits from Yearn sUSD Vault
        if (balanceOfDebt() < balanceOfSusdInVault()) {
            // balance
            uint256 _valueToWithdraw =
                balanceOfSusdInVault().sub(balanceOfDebt());
            withdrawFromSUSDVault(_valueToWithdraw);
        }

        // sell profits in sUSD for want (SNX) using router
        uint256 _balance = balanceOfSusd();
        if (_balance > 0) {
            buyWantWithSusd(_balance);
        }
    }

    function vestNextRewardsEntry() internal {
        // Synthetix protocol sends SNX staking rewards to a escrow contract that keeps them 52 weeks, until they vest
        // each time we claim the SNX rewards, a VestingEntry is created in the escrow contract for the amount that was owed
        // we need to keep track of those VestingEntries to know when they vest and claim them
        // after they vest and we claim them, we will receive them in our balance (strategy's balance)
        if (entryIDs.length == 0) {
            return;
        }

        // The strategy keeps track of the next VestingEntry expected to vest and only when it has vested, it checks the next one
        // this works because the VestingEntries record has been saved in chronological order and they will vest in chronological order too
        IRewardEscrowV2 re = _rewardEscrowV2();
        uint256 nextEntryID = entryIDs[entryIDIndex];
        uint256 _claimable =
            re.getVestingEntryClaimable(address(this), nextEntryID);
        // check if we need to vest
        if (_claimable == 0) {
            return;
        }

        // vest entryID
        uint256[] memory params = new uint256[](1);
        params[0] = nextEntryID;
        re.vest(params);

        // we update the nextEntryID to point to the next VestingEntry
        entryIDIndex++;
    }

    function tendTrigger(uint256 callCost) public view override returns (bool) {
        uint256 _currentRatio = getCurrentRatio(); // debt / collateral
        uint256 _targetRatio = getTargetRatio(); // max debt ratio. over this number, we consider debt unhealthy
        uint256 _issuanceRatio = getIssuanceRatio(); // preferred debt ratio by Synthetix (See protocol docs)

        if (_currentRatio < _issuanceRatio) {
            // strategy needs to take more debt
            // only return true if the difference is greater than a threshold
            return _issuanceRatio.sub(_currentRatio) >= ratioThreshold;
        } else if (_currentRatio <= _targetRatio) {
            // strategy is in optimal range (a bit undercollateralised)
            return false;
        } else if (_currentRatio > _targetRatio) {
            // the strategy needs to repay debt to exit the danger zone
            // only return true if the difference is greater than a threshold
            return _currentRatio.sub(_targetRatio) >= ratioThreshold;
        }

        return false;
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    // ********************** SUPPORT FUNCTIONS  **********************

    function burnSusd(uint256 _amount) internal returns (bool) {
        // returns false if unsuccessful
        if (_issuer().canBurnSynths(address(this))) {
            _synthetix().burnSynths(_amount);
            return true;
        } else {
            return false;
        }
    }

    function burnSusdToTarget() internal returns (uint256) {
        // we use this method to be able to avoid the waiting period
        // (see Synthetix Protocol)
        // it burns enough Synths to get back to 500% c-ratio
        // we need to have enough sUSD to burn to target
        uint256 _debtBalance = balanceOfDebt();
        // NOTE: amount of synths at 500% c-ratio (with current collateral)
        uint256 _maxSynths = _synthetix().maxIssuableSynths(address(this));
        if (_debtBalance <= _maxSynths) {
            // we are over the 500% c-ratio (i.e. below 20% debt ratio), we don't need to burn sUSD
            return 0;
        }
        uint256 _amountToBurn = _debtBalance.sub(_maxSynths);
        uint256 _balance = balanceOfSusd();
        if (_balance < _amountToBurn) {
            // if we do not have enough in balance, we withdraw funds from sUSD vault
            withdrawFromSUSDVault(_amountToBurn.sub(_balance));
        }

        if (_amountToBurn > 0) _synthetix().burnSynthsToTarget();
        return _amountToBurn;
    }

    function withdrawFromSUSDVault(uint256 _amount) internal {
        // Don't leave less than MIN_ISSUE sUSD in the vault
        if (
            _amount > balanceOfSusdInVault() ||
            balanceOfSusdInVault().sub(_amount) <= MIN_ISSUE
        ) {
            susdVault.withdraw();
        } else {
            uint256 _sharesToWithdraw =
                _amount.mul(1e18).div(susdVault.pricePerShare());
            susdVault.withdraw(_sharesToWithdraw);
        }
    }

    function buyWantWithSusd(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        address[] memory path = new address[](3);
        path[0] = address(susd);
        path[1] = address(WETH);
        path[2] = address(want);

        router.swapExactTokensForTokens(_amount, 0, path, address(this), now);
    }

    function buySusdWithWant(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        address[] memory path = new address[](3);
        path[0] = address(want);
        path[1] = address(WETH);
        path[2] = address(susd);

        // we use swapTokensForExactTokens because we need an exact sUSD amount
        router.swapTokensForExactTokens(
            _amount,
            type(uint256).max,
            path,
            address(this),
            now
        );
    }

    // ********************** CALCS **********************
    function ethToWant(uint256 _amtInWei)
        public
        view
        override
        returns (uint256)
    {
        if (_amtInWei == 0) {
            return 0;
        }
        address[] memory path = new address[](2);
        path[0] = address(want);
        path[1] = address(WETH);

        uint256[] memory amounts = router.getAmountsOut(_amtInWei, path);
        return amounts[amounts.length - 1];
    }

    function liquidateAllPositions()
        internal
        override
        returns (uint256 _amountFreed)
    {
        // NOTE: we try to unlock all of the collateral in the strategy (which should be == totalDebt)
        (_amountFreed, ) = liquidatePosition(vault.debtOutstanding());
    }

    function estimatedProfit() public view returns (uint256) {
        uint256 availableFees; // in sUSD

        (availableFees, ) = _getFeesAvailable();

        return sUSDToWant(availableFees);
    }

    function getTargetDebt(uint256 _targetCollateral)
        internal
        view
        returns (uint256)
    {
        uint256 _targetRatio = getTargetRatio();
        uint256 _collateralInSUSD = wantToSUSD(_targetCollateral);
        return _targetRatio.mul(_collateralInSUSD).div(1e18);
    }

    function sUSDToWant(uint256 _amount) internal view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        return _amount.mul(1e18).div(_exchangeRates().rateForCurrency("SNX"));
    }

    function wantToSUSD(uint256 _amount) internal view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        return _amount.mul(_exchangeRates().rateForCurrency("SNX")).div(1e18);
    }

    function _getSusdForWant(uint256 _wantAmount)
        internal
        view
        returns (uint256)
    {
        if (_wantAmount == 0) {
            return 0;
        }
        address[] memory path = new address[](3);
        path[0] = address(want);
        path[1] = address(WETH);
        path[2] = address(susd);

        uint256[] memory amounts = router.getAmountsOut(_wantAmount, path);
        return amounts[amounts.length - 1];
    }

    // ********************** BALANCES & RATIOS **********************
    function _lockedCollateral() internal view returns (uint256) {
        // collateral includes `want` balance (both locked and unlocked) AND escrowed balance
        uint256 _collateral = _synthetix().collateral(address(this));

        return _collateral.sub(_unlockedWant());
    }

    // amount of `want` (SNX) that can be transferred, sold, ...
    function _unlockedWant() internal view returns (uint256) {
        return _synthetix().transferableSynthetix(address(this));
    }

    function _unlockableWant() internal view returns (uint256) {
        // collateral includes escrowed SNX, we may not be able to unlock the full
        // we can only unlock this by repaying debt
        return balanceOfWant().sub(_unlockedWant());
    }

    function _collateral() internal view returns (uint256) {
        return _synthetix().collateral(address(this));
    }

    // returns fees and rewards
    function _getFeesAvailable() internal view returns (uint256, uint256) {
        // fees in sUSD
        // rewards in `want` (SNX)
        return _feePool().feesAvailable(address(this));
    }

    function getCurrentRatio() public view returns (uint256) {
        // ratio = debt / collateral
        // i.e. ratio is 0 if debt is 0
        // NOTE: collateral includes SNX in account + escrowed balance
        return _issuer().collateralisationRatio(address(this));
    }

    function getIssuanceRatio() public view returns (uint256) {
        return _issuer().issuanceRatio();
    }

    function getTargetRatio() public view returns (uint256) {
        return getIssuanceRatio().mul(targetRatioMultiplier).div(MAX_BPS);
    }

    function balanceOfEscrowedWant() public view returns (uint256) {
        return _rewardEscrowV2().balanceOf(address(this));
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfSusd() public view returns (uint256) {
        return IERC20(susd).balanceOf(address(this));
    }

    function balanceOfDebt() public view returns (uint256) {
        return _synthetix().debtBalanceOf(address(this), "sUSD");
    }

    function balanceOfSusdInVault() public view returns (uint256) {
        return
            susdVault
                .balanceOf(address(this))
                .mul(susdVault.pricePerShare())
                .div(1e18);
    }

    // ********************** ADDRESS RESOLVER SHORTCUTS **********************

    function resolver() public view returns (IAddressResolver) {
        return IAddressResolver(readProxy.target());
    }

    function _synthetix() internal view returns (ISynthetix) {
        return ISynthetix(resolver().getAddress(CONTRACT_SYNTHETIX));
    }

    function _feePool() internal view returns (IFeePool) {
        return IFeePool(resolver().getAddress(CONTRACT_FEEPOOL));
    }

    function _issuer() internal view returns (IIssuer) {
        return IIssuer(resolver().getAddress(CONTRACT_ISSUER));
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(resolver().getAddress(CONTRACT_EXRATES));
    }

    function _rewardEscrowV2() internal view returns (IRewardEscrowV2) {
        return IRewardEscrowV2(resolver().getAddress(CONTRACT_REWARDESCROW_V2));
    }
}