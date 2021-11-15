// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

// Import interfaces
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Delta.theta's fixed APR staking contract.
 * @author Ilia Chesnokov (gh @iliachesnokov).
 */
contract DeltaStaking is Initializable {
  using SafeERC20 for IERC20;

  /* General state */
  address private multisig; // Delta.theta team's multi-sig wallet.
  IERC20 public token; // DLTA token.

  uint256 public startTimestamp; // Staking start timestamp.
  uint256 public finishTimestamp; // Staking finish timestamp.
  uint256 public minimumHoldingInterval; // Minimum holding interval to take profit.

  uint256 public fundedAmount; // Staking funded balance.

  /* Stats state */
  uint256 public totalStaked; // Total staked amount.
  uint256 public totalWithdrawn; // Total withdrawn amount.

  /* Staking state */
  struct Deposit {
    uint256 amount; // Amount of the deposit
    uint256 start; // Accrual start timestamp
    uint256 created; // Deposit creation timestamp
  }

  mapping (address => Deposit) public deposits; // Deposits mapping.
  mapping (address => uint256) public withdrawn; // Withdrawn mapping.
  uint8 public interestRate; // Current interest rate per staking period.

  /* Events */
  event Deposited(address owner, uint256 amount);
  event Withdrawn(address owner, uint256 amount);
  event Rewarded(address owner, uint256 amount);

  /* Modifiers */
  modifier byTeam() {
    require(msg.sender == multisig, 'Only for team');
    _;
  }

  /**
   * @notice Staking initialization function.
   * @param _multisig Address of Delta.theta team's multi-sig wallet.
   * @param _token Address of DLTA token.
   * @param _start Staking start time.
   * @param _period Staking program period.
   */
  function initialize(
    address _multisig,
    address _token,
    uint256 _start,
    uint256 _period,
    uint256 _minimumHoldingInterval
  ) external initializer {
    multisig = _multisig;
    token = IERC20(_token);

    startTimestamp = _start;
    finishTimestamp = _start + _period;
    minimumHoldingInterval = _minimumHoldingInterval;
  }

  /**
   * @dev Internal function for calculating deposit parameters.
   * @return timestamp Math.min(block.timestamp, finishTimestamp).
   */
  function _getCalculationTimestamp() internal view returns (uint256 timestamp) {
    // We must stop increasing of multiplier when staking program is finished.
    timestamp = block.timestamp;
    if (timestamp > finishTimestamp) {
      timestamp = finishTimestamp;
    }
  }

  /**
   * @dev Internal function for calculating average accrual period.
   * @return period Average accrual period.
   */
  function _getAverageAccrualPeriod(
    uint256 _currentAmount,
    uint256 _start,
    uint256 _newAmount
  ) internal view returns (uint256 period) {
    period = (
      (_currentAmount * (
        _getCalculationTimestamp() - _start
      )) / _newAmount
    );
  }

  /**
   * @notice Deposit data fetching function.
   */
  function getData() external view returns (
    uint256 tStaked,
    uint256 tWithdrawn,
    uint256 cInterestRate,
    uint256 sTimestamp,
    uint256 fTimestamp,
    uint256 mhInterval
  ) {
    return (
      totalStaked,
      totalWithdrawn,
      interestRate,
      startTimestamp,
      finishTimestamp,
      minimumHoldingInterval
    );
  }

  /**
   * @notice Vault funding function (only for Delta.theta team).
   * @dev This function will be called before `finishTimestamp` to cover users rewards.
   * @param _amount Amount of DLTA tokens to fund.
   */
  function fund(
    uint256 _amount
  ) external byTeam {
    // Sufficent balance required
    require(
      token.balanceOf(msg.sender) >= _amount,
      "Low balance"
    );

    // Sufficent allowance required
    require(
      token.allowance(msg.sender, address(this)) >= _amount,
      "Low allowance"
    );

    // Increase `fundedAmount`.
    fundedAmount += _amount;

    // Transfer funds to Staking contract
    token.safeTransferFrom(msg.sender, address(this), _amount);
  }

  /**
   * @notice Vault defunding function. THIS FUNCTION CANNOT AFFECT USERS FUNDS (only for Delta.theta team).
   * @dev This function will be called only after `finishTimestamp`.
   * @param _amount Amount of DLTA tokens to defund.
   */
  function defund(
    uint256 _amount
  ) external byTeam {
    // We cannot withdraw more than current available funding.
    assert(_amount <= fundedAmount);

    // Decrease `fundedAmount`.
    fundedAmount -= _amount;

    // Transfer funds from Staking contract
    token.safeTransfer(msg.sender, _amount);
  }

  /**
   * @notice Staking interest rate updating function (only for Delta.theta team).
   * @param _interestRate New staking period interest rate.
   */
  function setInterestRate(
    uint8 _interestRate
  ) external byTeam {
    interestRate = _interestRate;
  }

  /**
   * @notice Reward calculation function. Calculates reward for deposit.
   * @param _amount Deposit amount.
   * @param _start Deposit accrual start.
   * @return reward Token reward amount.
   */
  function calculateReward(
    uint256 _amount,
    uint256 _start
  ) public view returns (uint256 reward) {
    // Get current timestamp (no more than finishTimestamp)
    uint256 timestamp = _getCalculationTimestamp();

    // Calculate reward
    reward = ((_amount * (
      (timestamp - _start) * interestRate
    )) / (finishTimestamp - startTimestamp)) / 100;
  }

  /**
   * @notice Reward calculation function. Calculates reward for deposit.
   * @param _owner Deposit owner.
   * @return reward Token reward amount.
   */
  function calculateReward(address _owner) external view returns (uint256 reward) {
    // Get owner's deposit
    Deposit memory deposit = deposits[_owner];

    // Calculate reward
    reward = calculateReward(deposit.amount, deposit.start);
  }

  /**
   * @notice The function of depositing money to the vault.
   * @param _amount Deposit amount.
   */
  function depositTokens(
    uint256 _amount
  ) external {
    // Sufficent balance required
    require(
      token.balanceOf(msg.sender) >= _amount,
      "Low balance"
    );

    // Sufficent allowance required
    require(
      token.allowance(msg.sender, address(this)) >= _amount,
      "Low allowance"
    );

    // Active staking contract state required
    require(
      block.timestamp > startTimestamp,
      "Staking is not started yet"
    );

    require(
      block.timestamp < finishTimestamp,
      "Staking is finished"
    );

    // User deposit object
    Deposit storage deposit = deposits[msg.sender];

    // If user already has a deposit
    if (deposit.amount > 0) {
      // Recalculate accrual start time to keep harvest to the same amount
      deposit.start = block.timestamp - _getAverageAccrualPeriod(
        deposit.amount,
        deposit.start,
        (deposit.amount + _amount)
      );
      deposit.amount += _amount;
    // If user doesn't have a deposit
    } else {
      // Save new deposit data
      deposit.amount = _amount;
      deposit.start = block.timestamp;
      deposit.created = block.timestamp;
    }

    // Increase `totalStaked`
    totalStaked += _amount;

    // Debit from user's balance
    token.safeTransferFrom(msg.sender, address(this), _amount);

    // Throw event
    emit Deposited(msg.sender, _amount);
  }

  /**
   * @notice The function of withdrawing harvest from the staking.
   */
  function harvest() public {
    // User deposit object
    Deposit storage deposit = deposits[msg.sender];

    // Active deposit required
    require(
      deposit.amount > 0,
      "No active deposit"
    );

    // Get calculation timestamp
    uint256 timestamp = _getCalculationTimestamp();

    // The minimum holding time for taking profit must pass
    require(
      (
        (deposit.created + minimumHoldingInterval < timestamp)
        || (timestamp == finishTimestamp)
      ),
      "Minimum interval must pass"
    );

    // Calculate reward
    uint256 reward = calculateReward(deposit.amount, deposit.start);

    // Update deposit's accrual start timestamp
    deposit.start = timestamp;

    // Update user's withdrawn amount
    withdrawn[msg.sender] += reward;

    // Update total withdrawn amount
    totalWithdrawn += reward;

    // Decrease fundedAmount
    fundedAmount -= reward;

    // Credit to user's balance
    token.safeTransfer(msg.sender, reward);

    // Throw event
    emit Rewarded(msg.sender, reward);
  }

  /**
   * @notice The function of withdrawing money from the staking.
   */
  function withdrawTokens() external {
    // User deposit object
    Deposit storage deposit = deposits[msg.sender];

    // Active deposit required
    require(
      deposit.amount > 0,
      "No active deposit"
    );

    // Get calculation timestamp
    uint256 timestamp = _getCalculationTimestamp();
    bool minimumIntervalPassed = (deposit.created + minimumHoldingInterval) < timestamp;

    // Decrease total staked
    totalStaked -= deposit.amount;

    // If there is available harvest on the deposit
    if (minimumIntervalPassed && deposit.start < timestamp) {
      // Withdraw user's harvest
      harvest();
    }

    uint256 withdrawnAmount = deposit.amount;

    deposit.amount = 0;
    deposit.start = 0;
    deposit.created = 0;
    
    // Credit to user's balance
    token.safeTransfer(msg.sender, withdrawnAmount);

    // Throw event
    emit Withdrawn(msg.sender, withdrawnAmount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
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

