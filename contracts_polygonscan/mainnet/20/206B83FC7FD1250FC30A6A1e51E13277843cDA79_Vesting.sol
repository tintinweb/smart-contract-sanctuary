// solhint-disable not-rely-on-time
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/DecimalMath.sol";

contract Vesting {
    using SafeERC20 for IERC20;
    using DecimalMath for uint256;

    event VestInitialized(
        address indexed beneficiary,
        address indexed forward,
        uint64 forwardPct,
        uint64 startTime,
        uint64 period,
        uint256 amount,
        uint256 vestId
    );
    event Claimed(address indexed beneficiary, uint256 amount);

    struct VestInfo {
        address beneficiary;
        uint64 period;
        uint64 startTime;
        address forward;
        uint64 forwardPct;
        uint256 amount;
        uint256 claimed;
    }

    uint256 public constant RELEASE_PERIOD = 1 weeks;
    IERC20 public immutable pixtToken;

    uint256 public vestLength;
    mapping(uint256 => VestInfo) public vestInfos;

    constructor(IERC20 pixtToken_) {
        require(address(pixtToken_) != address(0), "Vesting: PIXT_ZERO_ADDRESS");
        pixtToken = pixtToken_;
    }

    function initVesting(
        uint256 amount,
        uint64 startTime,
        uint64 period,
        address beneficiary,
        address forward,
        uint64 forwardPct
    ) public {
        require(startTime > block.timestamp, "Vesting: INVALID_START_TIME");
        require(period > 0, "Vesting: INVALID_PERIOD");
        require(beneficiary != address(0), "Vesting: INVALID_BENEFICIARY");
        if (forwardPct > 0) {
            require(forward != address(0), "Vesting: INVALID_FORWARD");
        }

        pixtToken.safeTransferFrom(msg.sender, address(this), amount);

        vestInfos[vestLength] = VestInfo({
            beneficiary: beneficiary,
            forward: forward,
            forwardPct: forwardPct,
            period: period,
            startTime: startTime,
            amount: amount,
            claimed: 0
        });

        emit VestInitialized(
            beneficiary,
            forward,
            forwardPct,
            startTime,
            period,
            amount,
            vestLength
        );

        vestLength += 1;
    }

    function initVestings(
        uint256[] calldata amounts,
        uint64[] calldata startTimes,
        uint64[] calldata periods,
        address[] calldata beneficiaries,
        address[] calldata forwards,
        uint64[] calldata forwardPcts
    ) external {
        require(
            amounts.length > 0 &&
                amounts.length == startTimes.length &&
                amounts.length == periods.length &&
                amounts.length == beneficiaries.length &&
                amounts.length == forwards.length &&
                amounts.length == forwardPcts.length,
            "Vesting: INVALID_LENGTH"
        );

        uint256 len = amounts.length;
        for (uint256 i; i < len; i += 1) {
            initVesting(
                amounts[i],
                startTimes[i],
                periods[i],
                beneficiaries[i],
                forwards[i],
                forwardPcts[i]
            );
        }
    }

    function _claim(uint256 id) internal returns (uint256 claimable) {
        VestInfo storage vestInfo = vestInfos[id];
        require(vestInfo.beneficiary == msg.sender, "Vesting: INVALID_BENEFICIARY");
        if (vestInfo.amount <= vestInfo.claimed) {
            return 0;
        }
        if (vestInfo.startTime >= block.timestamp) {
            return 0;
        }

        uint64 timePassed = uint64(block.timestamp) - vestInfo.startTime;
        uint256 releaseAmount;
        if (timePassed >= vestInfo.period) {
            releaseAmount = vestInfo.amount;
        } else {
            releaseAmount =
                (vestInfo.amount * ((timePassed / RELEASE_PERIOD) * RELEASE_PERIOD)) /
                vestInfo.period;
        }

        if (releaseAmount <= vestInfo.claimed) {
            return 0;
        }

        claimable = releaseAmount - vestInfo.claimed;
        if (vestInfo.forwardPct > 0) {
            uint256 forwardAmount = claimable.decimalMul(vestInfo.forwardPct);
            pixtToken.safeTransfer(vestInfo.forward, forwardAmount);
            emit Claimed(vestInfo.forward, forwardAmount);
            claimable -= forwardAmount;
        }

        if (claimable > 0) {
            pixtToken.safeTransfer(vestInfo.beneficiary, claimable);

            emit Claimed(vestInfo.beneficiary, claimable);
        }

        vestInfo.claimed = releaseAmount;
    }

    function claim(uint256 id) public returns (uint256) {
        uint256 claimed = _claim(id);
        require(claimed > 0, "Vesting: EMPTY_BALANCE");

        return claimed;
    }

    function claimInBatch(uint256[] calldata ids) external returns (uint256) {
        uint256 len = ids.length;
        uint256 totalClaimed;
        require(len > 0, "Vesting: INVALID_LENGTH");
        for (uint256 i; i < len; i += 1) {
            totalClaimed += _claim(ids[i]);
        }
        require(totalClaimed > 0, "Vesting: EMPTY_BALANCE");

        return totalClaimed;
    }

    function getPendingAmount(uint256 id) public view returns (uint256) {
        VestInfo memory vestInfo = vestInfos[id];

        if (vestInfo.amount <= vestInfo.claimed || vestInfo.startTime >= block.timestamp) {
            return 0;
        }

        uint64 timePassed = uint64(block.timestamp) - vestInfo.startTime;
        uint256 releaseAmount;
        if (timePassed >= vestInfo.period) {
            releaseAmount = vestInfo.amount;
        } else {
            releaseAmount =
                (vestInfo.amount * ((timePassed / RELEASE_PERIOD) * RELEASE_PERIOD)) /
                vestInfo.period;
        }

        if (releaseAmount > vestInfo.claimed) {
            return releaseAmount - vestInfo.claimed;
        } else {
            return 0;
        }
    }

    function getPendingAmounts(uint256[] calldata ids) external view returns (uint256) {
        uint256 total = 0;
        uint256 len = ids.length;
        for (uint256 i; i < len; i += 1) {
            total += getPendingAmount(ids[i]);
        }

        return total;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DecimalMath {
    uint256 private constant DENOMINATOR = 10000;

    function decimalMul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / DENOMINATOR;
    }

    function isLessThanAndEqualToDenominator(uint256 x) internal pure returns (bool) {
        return x <= DENOMINATOR;
    }
}

// SPDX-License-Identifier: MIT

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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