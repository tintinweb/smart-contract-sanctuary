/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;


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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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


// File contracts/Vesting.sol

pragma solidity ^0.8.0;
contract Vesting {
    using SafeERC20 for IERC20;
    event Released( address indexed beneficiary, uint256 amount);
    enum VestingPlan {
        Team,
        SeedRound,
        PrivateRound,
        StrategicPartners,
        Advisors,
        Treasury,
        Ecosystem,
        LiquidityPool
    }
    struct TokenAward {
        uint256 amount;
        uint256 released;
        VestingPlan vestingPlan;
    }
    uint256 constant public RESOLUTION = 1000000;
    // Tracks the token awards for each user (user => award)
    mapping(address => TokenAward) public awards;
    uint256 immutable public secondsInDay;
    uint256 immutable public vestingStart;
    IERC20 public targetToken;

    uint256 constant public cliffPeriodInMonthsTeamSeed = 2;
    uint256 constant public cliffPeriodInMonthsPrivate = 2;
    uint256 constant public cliffPeriodInMonthsStrategic = 3;
    uint256 constant public cliffPeriodInMonthsAdvisors = 6;

    uint256 constant public deltaPeriodInMonthsTeamSeed = 3;
    uint256 constant public deltaPeriodInMonthsPrivate = 2;
    uint256 constant public deltaPeriodInMonthsStrategic = 2;
    uint256 constant public deltaPeriodInMonthsAdvisors = 6;

    uint256 constant public quotaPercentagePrivate = 10 * 10000;  // 10 %
    uint256 constant public quotaPercentageStrategic = 7.6923 * 10000; // 7.6923 %
    uint256 constant public quotaPercentageAdvisors = 20 * 10000; //  20 %
    uint256 constant public quotaPercentageLiquidityPool = 25 * 10000; // 25 %

    uint256 constant public vestingEventsLiquidityPoolCount = 10;
    uint256 constant public sumTotalMonthsForVesting = 666; // sum(1:36)
    uint256 constant public totalMonthsOfVesting = 36;

    constructor(
     IERC20 _targetToken,
     address[] memory beneficiaries,
     TokenAward[] memory _awards,
     uint _secondsInDay,
     uint256 totalAwards
     ) {
        vestingStart = block.timestamp;
        targetToken = _targetToken;
        initAwards(beneficiaries, _awards, totalAwards);
        secondsInDay = _secondsInDay;
    }

    function release(address beneficiary) external {
        uint256 unreleased = getReleasableAmount(beneficiary);
        require(unreleased > 0, "Nothing to release");
        targetToken.safeTransfer(beneficiary, unreleased);
        emit Released(beneficiary, unreleased);
    }

    function getReleasableAmount(address beneficiary) public returns (uint256) {
        uint256 monthsPassed = (block.timestamp - vestingStart) / (secondsInDay * 30);
        uint256 vestedAmount;
        TokenAward storage award = awards[beneficiary];
        uint256 awardAmount = award.amount;
        VestingPlan vestingPlan = award.vestingPlan;

        if (vestingPlan <= VestingPlan.SeedRound) {
            vestedAmount = getAmountForTeamSeed(awardAmount, monthsPassed);
        } else if (
            vestingPlan > VestingPlan.SeedRound &&
            vestingPlan <= VestingPlan.Advisors
        ) {
            uint256 percentage;
            uint256 cliffPeriodInMonths;
            uint256 deltaPeriodInMonths;
            if (vestingPlan == VestingPlan.PrivateRound){
                percentage = quotaPercentagePrivate;
                cliffPeriodInMonths = cliffPeriodInMonthsPrivate;
                deltaPeriodInMonths = deltaPeriodInMonthsPrivate;
            } else if (vestingPlan == VestingPlan.StrategicPartners){
                percentage = quotaPercentageStrategic;
                cliffPeriodInMonths = cliffPeriodInMonthsStrategic;
                deltaPeriodInMonths = deltaPeriodInMonthsStrategic;
            } else {
                percentage = quotaPercentageAdvisors;
                cliffPeriodInMonths = cliffPeriodInMonthsAdvisors;
                deltaPeriodInMonths = deltaPeriodInMonthsAdvisors;
            }
            vestedAmount = getAmountForPrivateStrategicAdvisors(awardAmount, monthsPassed, percentage, cliffPeriodInMonths, deltaPeriodInMonths);
        } else if (
            vestingPlan > VestingPlan.Advisors &&
            vestingPlan <= VestingPlan.Ecosystem
        ) {
            vestedAmount = getAmountForTreasuryEcosystem(awardAmount, monthsPassed, vestingPlan);
        } else if (vestingPlan == VestingPlan.LiquidityPool) {
            vestedAmount = getAmountForLiquidityPool(awardAmount, monthsPassed, quotaPercentageLiquidityPool);
        } else {
            vestedAmount = 0;
        }

        
        uint256 amountToWithdraw = vestedAmount - award.released;
        award.released += amountToWithdraw;
        require(award.released <= awardAmount, "cannot release more than allocated");
        return amountToWithdraw;
    }

    function getAmountForTeamSeed(uint256 awardAmount, uint256 monthsPassed)
        public
        pure
        returns (uint256)
    {
        if (monthsPassed < cliffPeriodInMonthsTeamSeed) {
            return 0;
        }
        uint256 accumulatedPercentage;
        if (monthsPassed > cliffPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 5 * 10000;
        }
        if (monthsPassed > cliffPeriodInMonthsTeamSeed + 1 * deltaPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 7.5 * 10000;
        }
        if (monthsPassed > cliffPeriodInMonthsTeamSeed + 2 * deltaPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 10 * 10000;
        }
        if (monthsPassed > cliffPeriodInMonthsTeamSeed + 3 * deltaPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 15 * 10000;
        }
        if (monthsPassed > cliffPeriodInMonthsTeamSeed + 4 * deltaPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 15 * 10000;
        }
        if (monthsPassed > cliffPeriodInMonthsTeamSeed + 5 * deltaPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 10 * 10000;
        }
        if (monthsPassed > cliffPeriodInMonthsTeamSeed + 6 * deltaPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 10 * 10000;
        }
        if (monthsPassed > cliffPeriodInMonthsTeamSeed + 7 * deltaPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 10 * 10000;
        }
        if (monthsPassed > cliffPeriodInMonthsTeamSeed + 8 * deltaPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 10 * 10000;
        }
        if (monthsPassed > cliffPeriodInMonthsTeamSeed + 9 * deltaPeriodInMonthsTeamSeed) {
            accumulatedPercentage += 7.5 * 10000;
        }

        return ((awardAmount * accumulatedPercentage) / RESOLUTION);
    }

    function getAmountForPrivateStrategicAdvisors(uint256 awardAmount, uint256 monthsPassed, uint256 percentage, uint256 cliffPeriodInMonths, uint256 deltaPeriodInMonths)
        public
        pure
        returns (uint256)
    {
        
        if (monthsPassed < cliffPeriodInMonths ) {
            return 0;
        }

        uint256 amountToWithdraw =
            (( (monthsPassed - cliffPeriodInMonths + deltaPeriodInMonths) / deltaPeriodInMonths) *
                awardAmount *
                percentage) / (RESOLUTION);

        return amountToWithdraw < awardAmount ? amountToWithdraw : awardAmount;

        
    }

    function getAmountForTreasuryEcosystem(uint256 awardAmount, uint256 monthsPassed, VestingPlan vestingPlan) public pure returns (uint256) {
        uint256 amountToWithdraw;
        for (uint256 i = 0; i <= monthsPassed; i++){
            uint256 coefficient = 0;
            if (vestingPlan == VestingPlan.Ecosystem){
                coefficient = i + 1;
            } else {
                coefficient = totalMonthsOfVesting - i;
            }
            amountToWithdraw += (awardAmount / sumTotalMonthsForVesting) * coefficient;
        }
        return amountToWithdraw;
    }

    function getAmountForLiquidityPool(uint256 awardAmount, uint256 monthsPassed, uint256 percentage)
        public
        pure
        returns (uint256)
    {
        uint256 amountToWithdraw = (percentage * awardAmount) / RESOLUTION ;
        if (monthsPassed >= 1) {
            uint256 amount =
                ((monthsPassed) * awardAmount * ((RESOLUTION - percentage) / vestingEventsLiquidityPoolCount)) / RESOLUTION;
            amountToWithdraw += amount;
        }
        amountToWithdraw = amountToWithdraw > awardAmount ? awardAmount : amountToWithdraw;
        return amountToWithdraw;
    }
     
    function initAwards(address[] memory  beneficiaries, TokenAward[] memory _awards, uint256 totalAwards) internal{
        uint256 _totalAwards = 0;
        for(uint256 i = 0; i < beneficiaries.length; i++){
            require(awards[beneficiaries[i]].amount == 0, "duplicated beneficiary");
            awards[beneficiaries[i]] = _awards[i];
            _totalAwards += _awards[i].amount;
        }
        require(_totalAwards == totalAwards, "different awards amount");
    }
}