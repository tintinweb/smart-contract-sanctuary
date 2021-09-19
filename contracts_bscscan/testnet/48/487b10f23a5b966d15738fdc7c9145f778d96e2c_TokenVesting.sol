/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT
//pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

//import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
//import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

//import "../IERC20Upgradeable.sol";


/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
//import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
//import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract TokenVesting {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using SafeMathUpgradeable for uint128;

    struct VestingPeriod {
        uint128 vestingDays;
        uint128 tokensPerDay;
    }

    struct VestingClaimInfo {
        uint128 lastClaim;
        uint64 periodIndex;
        uint64 daysClaimed;
    }

    //token to be distributed
    IERC20Upgradeable public token;
    //handles setup
    address public setupAdmin;
    //UTC timestamp from which first vesting period begins (i.e. tokens will first be released 30 days after this time)
    uint256 public startTime;
    //total token obligations from all unpaid vesting amounts
    uint256 public totalObligations;
    //tokens can't be claimed for lockingPeriod days
    uint256 public lockingPeriod;
    //keeps track of contract state
    bool public setupComplete;

    //list of all beneficiaries
    address[] public beneficiaries;

    //amount of tokens to be received by each beneficiary
    mapping(address => VestingPeriod[]) public vestingPeriods;
    mapping(address => VestingClaimInfo) public claimInfo;
    //tracks if addresses have already been added as beneficiaries or not
    mapping(address => bool) public beneficiaryAdded;

    event SetupCompleted();
    event BeneficiaryAdded(address indexed user, uint256 totalAmountToClaim);
    event TokensClaimed(address indexed user, uint256 amount);

    modifier setupOnly() {
        require(!setupComplete, "setup already completed");
        _;
    }

    modifier claimAllowed() {
        require(setupComplete, "setup ongoing");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == setupAdmin, "not admin");
        _;
    }

    constructor(
        IERC20Upgradeable _token,
        uint256 _startTime,
        uint256 _lockingPeriod
    )  {
        token = _token;
        lockingPeriod = _lockingPeriod;
        setupAdmin = msg.sender;
        startTime = _startTime == 0 ? block.timestamp : _startTime;
    }

    // adds a list of beneficiaries
    function addBeneficiaries(address[] memory _beneficiaries, VestingPeriod[][] memory _vestingPeriods)
        external
        onlyAdmin
        setupOnly
    {
        require(_beneficiaries.length == _vestingPeriods.length, "input length mismatch");

        uint256 _totalObligations;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address beneficiary = _beneficiaries[i];

            require(!beneficiaryAdded[beneficiary], "beneficiary already added");
            beneficiaryAdded[beneficiary] = true;

            uint256 amountToClaim;

            VestingPeriod[] memory periods = _vestingPeriods[i];
            for (uint256 j = 0; j < periods.length; j++) {
                VestingPeriod memory period = periods[j];
                amountToClaim = amountToClaim.add(
                    uint256(period.vestingDays).mul(
                        uint256(period.tokensPerDay)
                    )
                );
                vestingPeriods[beneficiary].push(period);
            }

            beneficiaries.push(beneficiary);
            _totalObligations = _totalObligations.add(amountToClaim);

            emit BeneficiaryAdded(beneficiary, amountToClaim);
        }

        totalObligations = totalObligations.add(_totalObligations);
        token.safeTransferFrom(msg.sender, address(this), _totalObligations);
    }

    function tokensToClaim(address _beneficiary) public view returns(uint256) {        
        (uint256 tokensAmount,,) = _tokensToClaim(_beneficiary, claimInfo[_beneficiary]);
        return tokensAmount;
    }

    /**
        @dev This function returns tokensAmount available to claim. Calculates it based on several vesting periods if applicable.
     */
    function _tokensToClaim(address _beneficiary, VestingClaimInfo memory claim) private view returns(uint256 tokensAmount, uint256 daysClaimed, uint256 periodIndex) {
        uint256 lastClaim = claim.lastClaim;
        if (lastClaim == 0) { // first time claim, set it to a contract start time
            lastClaim = startTime;
        }

        if (lastClaim > block.timestamp) {
            // has not started yet
            return (0, 0, 0);
        }

        uint256 daysElapsed = (block.timestamp.sub(lastClaim)).div(60 seconds);

        if (claim.lastClaim == 0)  { // first time claim
            // check for lock period
            if (daysElapsed > lockingPeriod) {
                // passed beyond locking period, adjust elapsed days by locking period
                daysElapsed = daysElapsed.sub(lockingPeriod);
            } else {
                // tokens are locked
                return (0, 0, 0);
            }
        }

        periodIndex = uint256(claim.periodIndex);
        uint256 totalPeriods = vestingPeriods[_beneficiary].length;

        // it's safe to assume that admin won't setup contract in such way, that this loop will be out of gas
        while (daysElapsed > 0 && totalPeriods > periodIndex) {
            VestingPeriod memory vestingPeriod = vestingPeriods[_beneficiary][periodIndex];

            daysClaimed = claim.daysClaimed;

            uint256 daysInPeriodToClaim = uint256(vestingPeriod.vestingDays).sub(claim.daysClaimed);
            if (daysInPeriodToClaim > daysElapsed) {
                daysInPeriodToClaim = daysElapsed;
            }

            tokensAmount = tokensAmount.add(
                uint256(vestingPeriod.tokensPerDay).mul(daysInPeriodToClaim)
            );

            daysElapsed = daysElapsed.sub(daysInPeriodToClaim);
            daysClaimed = daysClaimed.add(daysInPeriodToClaim);
            // at this point, if any days left to claim, it means that period was consumed
            // move to the next period
            claim.daysClaimed = 0;
            periodIndex++;
        }

        periodIndex--;
    }

    // claims vested tokens for a given beneficiary
    function claimFor(address _beneficiary) external claimAllowed {
        _processClaim(_beneficiary);
    }

    // convenience function for beneficiaries to call to claim all of their vested tokens
    function claimForSelf() external claimAllowed {
        _processClaim(msg.sender);
    }

    // claims vested tokens for all beneficiaries
    function claimForAll() external claimAllowed {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            _processClaim(beneficiaries[i]);
        }
    }

    // complete setup once all obligations are met, to remove the ability to
    // reclaim tokens until vesting is complete, and allow claims to start
    function endSetup() external onlyAdmin setupOnly {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= totalObligations, "obligations not yet met");
        setupComplete = true;
        setupAdmin = address(0);
        emit SetupCompleted();
    }

    // reclaim tokens if necessary prior to finishing setup. otherwise reclaim any
    // extra tokens after the end of vesting
    function reclaimTokens() external onlyAdmin setupOnly {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeTransfer(setupAdmin, tokenBalance);
    }

    // Calculates the claimable tokens of a beneficiary and sends them.
    function _processClaim(address _beneficiary) internal {
        VestingClaimInfo memory claim = claimInfo[_beneficiary];
        (uint256 amountToClaim, uint256 daysClaimed, uint256 periodIndex) = _tokensToClaim(_beneficiary, claim);

        if (amountToClaim == 0) {
            return;
        }

        claim.daysClaimed = uint64(daysClaimed);
        claim.lastClaim = uint128(block.timestamp);
        claim.periodIndex = uint64(periodIndex);
        claimInfo[_beneficiary] = claim;

        _sendTokens(_beneficiary, amountToClaim);

        emit TokensClaimed(_beneficiary, amountToClaim);
    }

    // send tokens to beneficiary and remove obligation
    function _sendTokens(address _beneficiary, uint256 _amountToSend) internal {
        totalObligations = totalObligations.sub(_amountToSend);
        token.safeTransfer(_beneficiary, _amountToSend);
    }
}