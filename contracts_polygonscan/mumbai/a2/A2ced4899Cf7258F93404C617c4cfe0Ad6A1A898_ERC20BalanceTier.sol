// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { TierUtil } from "../libraries/TierUtil.sol";
import { ValueTier } from "./ValueTier.sol";
import "./ReadOnlyTier.sol";

/// @title ERC20BalanceTier
///
/// The `ERC20BalanceTier` simply checks the current balance of an erc20 against tier values.
/// As the current balance is always read from the erc20 contract directly there is no historical block data.
/// All tiers held at the current value will be 0x00000000 and tiers not held will be 0xFFFFFFFF.
/// `setTier` will error as this contract has no ability to write to the erc20 contract state.
///
/// Balance tiers are useful for:
/// - Claim contracts that don't require backdated tier holding (be wary of griefing!).
/// - Assets that cannot be transferred, so are not eligible for `ERC20TransferTier`.
/// - Lightweight, realtime checks that encumber the tiered address as little as possible.
contract ERC20BalanceTier is ReadOnlyTier, ValueTier {
    IERC20 public immutable erc20;

    /// @param erc20_ The erc20 token contract to check the balance of at `report` time.
    /// @param tierValues_ 8 values corresponding to minimum erc20 balances for tiers ONE through EIGHT.
    constructor(IERC20 erc20_, uint256[8] memory tierValues_) public ValueTier(tierValues_) {
        erc20 = erc20_;
    }

    /// Report simply truncates all tiers above the highest value held.
    /// @inheritdoc ITier
    function report(address account_) public view override returns (uint256) {
        return TierUtil.truncateTiersAbove(
            0,
            valueToTier(erc20.balanceOf(account_))
        );
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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { ITier } from "../tier/ITier.sol";

/// @title TierUtil
/// Utilities to consistently read, write and manipulate tiers in reports.
/// The low-level bit shifting can be difficult to get right so this factors that out.
library TierUtil {

    /// UNINITIALIZED report is 0xFF.. as no tier has been held.
    uint256 constant public UNINITIALIZED = uint256(-1);

    /// Returns the highest tier achieved relative to a block number and report.
    ///
    /// Note that typically the report will be from the _current_ contract state.
    /// When the `report` comes from a later block than the `blockNumber` this means
    /// the user must have held the tier continuously from `blockNumber` _through_ to the report block.
    /// I.e. NOT a snapshot.
    /// @param report_ A report as per `ITier`.
    /// @param blockNumber_ The block number to check the tiers against.
    /// @return The highest tier held since `blockNumber` according to `report`.
    function tierAtBlockFromReport(
        uint256 report_,
        uint256 blockNumber_
    )
        internal pure returns (ITier.Tier)
    {
        for (uint256 i_ = 0; i_ < 8; i_++) {
            if (uint32(uint256(report_ >> (i_*32))) > uint32(blockNumber_)) {
                return ITier.Tier(i_);
            }
        }
        return ITier.Tier(8);
    }

    /// Returns the block that a given tier has been held since according to a report.
    ///
    /// The report SHOULD encode "never" as 0xFFFFFFFF.
    /// @param report_ The report to read a block number from.
    /// @param tier_ The Tier to read the block number for.
    /// @return The block number this has been held since.
    function tierBlock(uint256 report_, ITier.Tier tier_)
        internal
        pure
        returns (uint256)
    {
        // ZERO is a special case. Everyone has always been at least ZERO, since block 0.
        if (tier_ == ITier.Tier.ZERO) { return 0; }

        uint256 offset_ = (uint256(tier_) - 1) * 32;
        return uint256(uint32(
            uint256(
                report_ >> offset_
            )
        ));
    }

    /// Resets all the tiers above the reference tier to 0xFFFFFFFF.
    ///
    /// @param report_ Report to truncate with high bit 1s.
    /// @param tier_ Tier to truncate above (exclusive).
    /// @return Truncated report.
    function truncateTiersAbove(uint256 report_, ITier.Tier tier_)
        internal
        pure
        returns (uint256)
    {
        uint256 offset_ = uint256(tier_) * 32;
        uint256 mask_ = (UNINITIALIZED >> offset_) << offset_;
        return report_ | mask_;
    }

    /// Updates a report with a block number for every status integer in a range.
    ///
    /// Does nothing if the end status is equal or less than the start status.
    /// @param report_ The report to update.
    /// @param startTier_ The tierInt_ at the start of the range (exclusive).
    /// @param endTier_ The tierInt_ at the end of the range (inclusive).
    /// @param blockNumber_ The block number to set for every status in the range.
    /// @return The updated report.
    function updateBlocksForTierRange(
        uint256 report_,
        ITier.Tier startTier_,
        ITier.Tier endTier_,
        uint256 blockNumber_
    )
        internal pure returns (uint256)
    {
        uint256 offset_;
        for (uint256 i_ = uint256(startTier_); i_ < uint256(endTier_); i_++) {
            offset_ = i_ * 32;
            report_ = (report_ & ~uint256(uint256(uint32(UNINITIALIZED)) << offset_)) | uint256(blockNumber_ << offset_);
        }
        return report_;
    }

    /// Updates a report to a new status.
    ///
    /// Internally dispatches to `truncateTiersAbove` and `updateBlocksForTierRange`.
    /// The dispatch is based on whether the new tier is above or below the current tier.
    /// The `startTier_` MUST match the result of `tierAtBlockFromReport`.
    /// It is expected the caller will know the current tier when calling this function
    /// and need to do other things in the calling scope with it.
    /// @param report_ The report to update.
    /// @param startTier_ The current tier according to the report.
    /// @param endTier_ The new tier for the report.
    /// @param blockNumber_ The block number to update the tier at.
    /// @return The updated report.
    function updateReportWithTierAtBlock(
        uint256 report_,
        ITier.Tier startTier_,
        ITier.Tier endTier_,
        uint256 blockNumber_
    )
        internal pure returns (uint256)
    {
        return endTier_ < startTier_ ? truncateTiersAbove(report_, endTier_) : updateBlocksForTierRange(report_, startTier_, endTier_, blockNumber_);
    }

}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { ITier } from "./ITier.sol";

/// @title ValueTier
///
/// A contract that is `ValueTier` expects to derive tiers from explicit values.
/// For example an address must send or hold an amount of something to reach a given tier.
/// Anything with predefined values that map to tiers can be a `ValueTier`.
///
/// Note that `ValueTier` does NOT implement `ITier`.
/// `ValueTier` does include state however, to track the `tierValues` so is not a library.
contract ValueTier {
    uint256 private immutable tierOne;
    uint256 private immutable tierTwo;
    uint256 private immutable tierThree;
    uint256 private immutable tierFour;
    uint256 private immutable tierFive;
    uint256 private immutable tierSix;
    uint256 private immutable tierSeven;
    uint256 private immutable tierEight;

    /// Set the `tierValues` on construction to be referenced immutably.
    constructor(uint256[8] memory tierValues_) public {
        tierOne = tierValues_[0];
        tierTwo = tierValues_[1];
        tierThree = tierValues_[2];
        tierFour = tierValues_[3];
        tierFive = tierValues_[4];
        tierSix = tierValues_[5];
        tierSeven = tierValues_[6];
        tierEight = tierValues_[7];
    }

    /// Complements the default solidity accessor for `tierValues`.
    /// Returns all the values in a list rather than requiring an index be specified.
    /// @return tierValues_ The immutable `tierValues`.
    function tierValues() public view returns(uint256[8] memory tierValues_) {
        tierValues_[0] = tierOne;
        tierValues_[1] = tierTwo;
        tierValues_[2] = tierThree;
        tierValues_[3] = tierFour;
        tierValues_[4] = tierFive;
        tierValues_[5] = tierSix;
        tierValues_[6] = tierSeven;
        tierValues_[7] = tierEight;
        return tierValues_;
    }

    /// Converts a Tier to the minimum value it requires.
    /// Tier ZERO is always value 0 as it is the fallback.
    function tierToValue(ITier.Tier tier_) internal view returns(uint256) {
        return tier_ > ITier.Tier.ZERO ? tierValues()[uint256(tier_) - 1] : 0;
    }

    /// Converts a value to the maximum Tier it qualifies for.
    function valueToTier(uint256 value_) internal view returns(ITier.Tier) {
        for (uint256 i = 0; i < 8; i++) {
            if (value_ < tierValues()[i]) {
                return ITier.Tier(i);
            }
        }
        return ITier.Tier.EIGHT;
    }
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { ITier } from "./ITier.sol";
import { TierUtil } from "../libraries/TierUtil.sol";

/// @title ReadOnlyTier
///
/// A contract inheriting `ReadOnlyTier` cannot call `setTier`.
///
/// `ReadOnlyTier` is abstract because it does not implement `report`.
/// The expectation is that `report` will derive tiers from some external data source.
abstract contract ReadOnlyTier is ITier {
    /// Always reverts because it is not possible to set a read only tier.
    /// @inheritdoc ITier
    function setTier(
        address,
        Tier,
        bytes memory
    )
        external override
    {
        revert("SET_TIER");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

/// @title ITier
/// Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing ITier:
/// - MUST represent held tiers with the `Tier` enum.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the block each tier has been continuously held since encoded as `uint32`.
///   - The encoded tiers start at ONE; ZERO is implied if no tier has ever been held.
///   - Tier ZERO is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the block data is erased for that tier and will be set if/when the tier is regained to the new block.
///   - If the historical block information is not available the report MAY return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
/// - SHOULD implement `setTier`.
///   - Contracts SHOULD revert with `SET_TIER` error if they cannot meaningfully set a tier directly.
///     For example a contract that can only derive a membership tier by reading the state of an external contract cannot set tiers.
///   - Contracts implementing `setTier` SHOULD error with `SET_ZERO_TIER` if `Tier.ZERO` is being set.
/// - MUST emit `TierChange` when `setTier` successfully writes a new tier.
///   - Contracts that cannot meaningfully set a tier are exempt.
interface ITier {
    /// 9 Possible tiers.
    /// Fits nicely as uint32 in uint256 which is helpful for internal storage concerns.
    /// 8 tiers can be achieved, ZERO is the tier when no tier has been achieved.
    enum Tier {
        ZERO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE,
        SIX,
        SEVEN,
        EIGHT
    }

    /// Every time a Tier changes we log start and end Tier against the account.
    /// This MAY NOT be emitted if reports are being read from the state of an external contract.
    event TierChange(
        address indexed account,
        Tier indexed startTier,
        Tier indexed endTier
    );

    /// Updates the tier of an account.
    ///
    /// The implementing contract is responsible for all checks and state changes required to set the tier.
    /// For example, taking/refunding funds/NFTs etc.
    ///
    /// Contracts may disallow directly setting tiers, preferring to derive reports from other onchain data.
    /// In this case they should `revert("SET_TIER");`.
    ///
    /// @param account Account to change the tier for.
    /// @param endTier Tier after the change.
    /// @param data Arbitrary input to disambiguate ownership (e.g. NFTs to lock).
    function setTier(
        address account,
        Tier endTier,
        bytes memory data
    )
        external;

    /// Returns the earliest block the account has held each tier for continuously.
    /// This is encoded as a uint256 with blocks represented as 8x concatenated u32.
    /// I.e. Each 4 bytes of the uint256 represents a u32 tier start time.
    /// The low bits represent low tiers and high bits the high tiers.
    /// Implementing contracts should return 0xFFFFFFFF for lost & never-held tiers.
    ///
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}