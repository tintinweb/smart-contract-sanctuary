// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVeFXS.sol";
import "./interfaces/IYieldDistributor.sol";
import "./interfaces/IFraxGaugeController.sol";

/// @title FxsLocker
/// @author StakeDAO
/// @notice Locks the FXS tokens to veFXS contract
contract FxsLocker {
	using SafeERC20 for IERC20;
	using Address for address;

	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public fxsDepositor;
	address public accumulator;

	address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
	address public constant veFXS = address(0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0);
	address public yieldDistributor = address(0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872);
	address public gaugeController = address(0x44ade9AA409B0C29463fF7fcf07c9d3c939166ce);

	/* ========== EVENTS ========== */
	event LockCreated(address indexed user, uint256 value, uint256 duration);
	event FXSClaimed(address indexed user, uint256 value);
	event Voted(uint256 _voteId, address indexed _votingAddress, bool _support);
	event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
	event Released(address indexed user, uint256 value);
	event GovernanceChanged(address indexed newGovernance);
	event FxsDepositorChanged(address indexed newFxsDepositor);
	event AccumulatorChanged(address indexed newAccumulator);
	event YieldDistributorChanged(address indexed newYieldDistributor);
	event GaugeControllerChanged(address indexed newGaugeController);

	/* ========== CONSTRUCTOR ========== */
	constructor(address _accumulator) {
		governance = msg.sender;
		accumulator = _accumulator;
		IERC20(fxs).approve(veFXS, type(uint256).max);
	}

	/* ========== MODIFIERS ========== */
	modifier onlyGovernance() {
		require(msg.sender == governance, "!gov");
		_;
	}

	modifier onlyGovernanceOrAcc() {
		require(msg.sender == governance || msg.sender == accumulator, "!(gov||acc)");
		_;
	}

	modifier onlyGovernanceOrDepositor() {
		require(msg.sender == governance || msg.sender == fxsDepositor, "!(gov||proxy||fxsDepositor)");
		_;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Creates a lock by locking FXS token in the veFXS contract for the specified time
	/// @dev Can only be called by governance or proxy
	/// @param _value The amount of token to be locked
	/// @param _unlockTime The duration for which the token is to be locked
	function createLock(uint256 _value, uint256 _unlockTime) external onlyGovernanceOrDepositor {
		IveFXS(veFXS).create_lock(_value, _unlockTime);
		IYieldDistributor(yieldDistributor).checkpoint();
		emit LockCreated(msg.sender, _value, _unlockTime);
	}

	/// @notice Increases the amount of FXS locked in veFXS
	/// @dev The FXS needs to be transferred to this contract before calling
	/// @param _value The amount by which the lock amount is to be increased
	function increaseAmount(uint256 _value) external onlyGovernanceOrDepositor {
		IveFXS(veFXS).increase_amount(_value);
		IYieldDistributor(yieldDistributor).checkpoint();
	}

	/// @notice Increases the duration for which FXS is locked in veFXS for the user calling the function
	/// @param _unlockTime The duration in seconds for which the token is to be locked
	function increaseUnlockTime(uint256 _unlockTime) external onlyGovernanceOrDepositor {
		IveFXS(veFXS).increase_unlock_time(_unlockTime);
		IYieldDistributor(yieldDistributor).checkpoint();
	}

	/// @notice Claim the FXS reward from the FXS Yield Distributor at 0xc6764e58b36e26b08Fd1d2AeD4538c02171fA872
	/// @param _recipient The address which will receive the claimedFXS reward
	function claimFXSRewards(address _recipient) external onlyGovernanceOrAcc {
		IYieldDistributor(yieldDistributor).getYield();
		emit FXSClaimed(_recipient, IERC20(fxs).balanceOf(address(this)));
		IERC20(fxs).safeTransfer(_recipient, IERC20(fxs).balanceOf(address(this)));
	}

	/// @notice Withdraw the FXS from veFXS
	/// @dev call only after lock time expires
	/// @param _recipient The address which will receive the released FXS
	function release(address _recipient) external onlyGovernanceOrDepositor {
		IveFXS(veFXS).withdraw();
		uint256 balance = IERC20(fxs).balanceOf(address(this));

		IERC20(fxs).safeTransfer(_recipient, balance);
		emit Released(_recipient, balance);
	}

	/// @notice Vote on Frax Gauge Controller for a gauge with a given weight
	/// @param _gauge The gauge address to vote for
	/// @param _weight The weight with which to vote
	function voteGaugeWeight(address _gauge, uint256 _weight) external onlyGovernance {
		IFraxGaugeController(gaugeController).vote_for_gauge_weights(_gauge, _weight);
		emit VotedOnGaugeWeight(_gauge, _weight);
	}

	function setGovernance(address _governance) external onlyGovernance {
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	function setFxsDepositor(address _fxsDepositor) external onlyGovernance {
		fxsDepositor = _fxsDepositor;
		emit FxsDepositorChanged(_fxsDepositor);
	}

	function setYieldDistributor(address _newYD) external onlyGovernance {
		yieldDistributor = _newYD;
		emit YieldDistributorChanged(_newYD);
	}

	function setGaugeController(address _gaugeController) external onlyGovernance {
		gaugeController = _gaugeController;
		emit GaugeControllerChanged(_gaugeController);
	}

	function setAccumulator(address _accumulator) external onlyGovernance {
		accumulator = _accumulator;
		emit AccumulatorChanged(_accumulator);
	}

	/// @notice execute a function
	/// @param to Address to sent the value to
	/// @param value Value to be sent
	/// @param data Call function data
	function execute(
		address to,
		uint256 value,
		bytes calldata data
	) external onlyGovernanceOrDepositor returns (bool, bytes memory) {
		(bool success, bytes memory result) = to.call{ value: value }(data);
		return (success, result);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IFraxGaugeController {
	function vote_for_gauge_weights(address, uint256) external;

	function vote(
		uint256,
		bool,
		bool
	) external; //voteId, support, executeIfDecided
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IveFXS {
	struct LockedBalance {
		int128 amount;
		uint256 end;
	}

	function commit_transfer_ownership(address addr) external;

	function apply_transfer_ownership() external;

	function commit_smart_wallet_checker(address addr) external;

	function apply_smart_wallet_checker() external;

	function toggleEmergencyUnlock() external;

	function recoverERC20(address token_addr, uint256 amount) external;

	function get_last_user_slope(address addr) external view returns (int128);

	function user_point_history__ts(address _addr, uint256 _idx) external view returns (uint256);

	function locked__end(address _addr) external view returns (uint256);

	function checkpoint() external;

	function deposit_for(address _addr, uint256 _value) external;

	function create_lock(uint256 _value, uint256 _unlock_time) external;

	function increase_amount(uint256 _value) external;

	function increase_unlock_time(uint256 _unlock_time) external;

	function withdraw() external;

	function balanceOf(address addr) external view returns (uint256);

	function balanceOf(address addr, uint256 _t) external view returns (uint256);

	function balanceOfAt(address addr, uint256 _block) external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function totalSupply(uint256 t) external view returns (uint256);

	function totalSupplyAt(uint256 _block) external view returns (uint256);

	function totalFXSSupply() external view returns (uint256);

	function totalFXSSupplyAt(uint256 _block) external view returns (uint256);

	function changeController(address _newController) external;

	function token() external view returns (address);

	function supply() external view returns (uint256);

	function locked(address addr) external view returns (LockedBalance memory);

	function epoch() external view returns (uint256);

	function point_history(uint256 arg0)
		external
		view
		returns (
			int128 bias,
			int128 slope,
			uint256 ts,
			uint256 blk,
			uint256 fxs_amt
		);

	function user_point_history(address arg0, uint256 arg1)
		external
		view
		returns (
			int128 bias,
			int128 slope,
			uint256 ts,
			uint256 blk,
			uint256 fxs_amt
		);

	function user_point_epoch(address arg0) external view returns (uint256);

	function slope_changes(uint256 arg0) external view returns (int128);

	function controller() external view returns (address);

	function transfersEnabled() external view returns (bool);

	function emergencyUnlockActive() external view returns (bool);

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function version() external view returns (string memory);

	function decimals() external view returns (uint256);

	function future_smart_wallet_checker() external view returns (address);

	function smart_wallet_checker() external view returns (address);

	function admin() external view returns (address);

	function future_admin() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IYieldDistributor {
	function getYield() external returns (uint256);

	function checkpoint() external;
}