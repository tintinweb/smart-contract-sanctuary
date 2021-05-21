//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
 * @title Token pools that allows different ERC20 tokens and ETH deposits and withdrawals
 * with penalty and bonus mechanisms to encaurage long term holding. 
 * Each token has one independent pool. i.e. all accounting is separate for each token.
 * @author artdgn (@github)
 * @notice The mechanism rules:
 * - A depositor is committing for the "commitment period", after which the
 *   deposit can be withdrawn with its share of the bonus pool.
 * - Bonus pool is populated from the penalties for early withdrawals,
 *   which are withdrawals done before each deposit's commitment period is elapsed.
 * - The share of the bonus pool is equal to the share of the deposit from all deposits
 *   at the time of withdrawal.
 * - Withdrawal before commitment period is not entitled to any part of the bonus
 *   and is instead "slashed" with a penalty (that is added to the bonus pool).
 * - The penalty percent is decreasing linearly from 
 *   initialPenaltyPercent to 0 with time (for the duration of the commitPeriod). 
 * - Any additional deposit is added to the current deposit and "resets" the
 *   commitment period required to wait.
 * @dev For safety and clarity, the withdrawal functionality is split into 
 * two methods, one for withdrawing with penalty, and the other one for withdrawing
 * with bonus.
 * Also, the ERC20 token and ETH functionality is split into separate methods.
 * The total deposits amount is tracked per token contract in 
 * depositSums, bonuses in bonusSums.
 */
contract HodlPoolV1 {

  using SafeERC20 for IERC20;

  struct Deposit {
    uint value;
    uint time;
  }
  
  /// @notice initial maximum percent of penalty
  uint public immutable initialPenaltyPercent;  

  /// @notice time it takes for withdrawal penalty to be reduced to 0
  uint public immutable commitPeriod;

  /// @notice WETH token contract this pool is using for handling ETH
  address public immutable WETH;

  /// @dev token deposits per token contract and per user
  /// each sender has only a single deposit 
  mapping(address => mapping(address => Deposit)) internal deposits;  

  /// @dev sum of all deposits currently held in the pool for each token contract
  mapping(address => uint) depositSums;

  /// @dev sum of all bonuses currently available for withdrawal 
  /// for each token contract
  mapping(address => uint) bonusSums;

  /*
   * @param token ERC20 token address for the deposited token
   * @param sender address that has made the deposit
   * @param amount size of new deposit, or deposit increase
   * @param time timestamp from which the commitment period will be counted
   */
  event Deposited(
    address indexed token, 
    address indexed sender, 
    uint amount, 
    uint time
  );

  /*
   * @param token ERC20 token address for the withdrawed token
   * @param sender address that has made the withdrawal
   * @param amount amount sent out to sender as withdrawal
   * @param depositAmount the original amount deposited
   * @param penalty the penalty incurred for this withdrawal
   * @param bonus the bonus included in this withdrawal
   * @param timeHeld the time in seconds the deposit was held
   */
  event Withdrawed(
    address indexed token,
    address indexed sender, 
    uint amount, 
    uint depositAmount, 
    uint penalty, 
    uint bonus,
    uint timeHeld
  );

  modifier onlyDepositors(address token) {
    require(deposits[token][msg.sender].value > 0, "no deposit");
    _;
  }

  /*
   * @param _initialPenaltyPercent the penalty percent for early withdrawal penalty 
   *   calculations.
   * @param _commitPeriod the time in seconds after the deposit at which the 
   *   penalty becomes 0
   * @param _WETH wrapped ETH contract address this pool will be using for ETH
  */
  constructor (uint _initialPenaltyPercent, uint _commitPeriod, address _WETH) {
    require(_initialPenaltyPercent > 0, "no penalty"); 
    require(_initialPenaltyPercent <= 100, "initial penalty > 100%"); 
    require(_commitPeriod >= 10 seconds, "commitment period too short");
    require(_commitPeriod <= 365 days, "commitment period too long");
    require(_WETH != address(0), "WETH address can't be 0x0");
    initialPenaltyPercent = _initialPenaltyPercent;
    commitPeriod = _commitPeriod;
    WETH = _WETH;
  }

  /// @notice contract doesn't support sending ETH directly
  receive() external payable {
    require(
      msg.sender == WETH, 
      "no receive() except from WETH contract, use depositETH()");
  }

  /*
   * @param token address of token contract
   * @param amount of token to deposit
   * @notice any subsequent deposit after the first is added to the first one,
   * and the time for waiting is "reset".
   */
  function deposit(address token, uint amount) external {
    require(amount > 0, "deposit too small");
    deposits[token][msg.sender].value += amount;
    deposits[token][msg.sender].time = block.timestamp;
    depositSums[token] += amount;
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    emit Deposited(token, msg.sender, amount, block.timestamp);
  }

  /// @notice payable method for depositing ETH with same logic as deposit()
  function depositETH() external payable {
    require(msg.value > 0, "deposit too small");
    deposits[WETH][msg.sender].value += msg.value;
    deposits[WETH][msg.sender].time = block.timestamp;
    depositSums[WETH] += msg.value;
    IWETH(WETH).deposit{value: msg.value}();
    emit Deposited(WETH, msg.sender, msg.value, block.timestamp);
  }

  /*
   * @param token address of token contract
   * @notice withdraw the full deposit with the proportional share of bonus pool.
   * will fail for early withdawals (for which there is another method)
   * @dev checks that the deposit is non-zero
   */
  function withdrawWithBonus(address token) external onlyDepositors(token) {
    require(
      penaltyOf(token, msg.sender) == 0, 
      "cannot withdraw without penalty yet, use withdrawWithPenalty()"
    );
    _withdraw(token);
  }

  /// @notice withdraw ETH with bonus with same logic as withdrawWithBonus()
  function withdrawWithBonusETH() external onlyDepositors(WETH) {
    require(
      penaltyOf(WETH, msg.sender) == 0, 
      "cannot withdraw without penalty yet, use withdrawWithPenalty()"
    );
    _withdrawETH();
  }

  /*
   * @param token address of token contract
   * @notice withdraw the deposit with any applicable penalty. Will withdraw 
   * with any available bonus if penalty is 0 (commitment period elapsed).
   * @dev checks that the deposit is non-zero
   */
  function withdrawWithPenalty(address token) external onlyDepositors(token) {
    _withdraw(token);
  }

  /// @notice withdraw ETH with penalty with same logic as withdrawWithPenalty()
  function withdrawWithPenaltyETH() external onlyDepositors(WETH) {
    _withdrawETH();
  }

  /// @param token address of token contract
  /// @param sender address of the depositor
  /// @return total deposit of the sender
  function balanceOf(address token, address sender) public view returns (uint) {
    return deposits[token][sender].value;
  }

  /// @param token address of token contract
  /// @param sender address of the depositor
  /// @return penalty for the sender's deposit if withdrawal would happen now
  function penaltyOf(address token, address sender) public view returns (uint) {
    return _depositPenalty(deposits[token][sender]);
  }

  /*
   * @param token address of token contract
   * @param sender address of the depositor
   * @return bonus share of the sender's deposit if withdrawal
   *   would happen now and there was no penalty (the potential bonus).
   * @notice bonus share can be returned with this method before
   *   commitment period is actually done, but it won't be withdrawn 
   *   if the penalty is non-0
  */
  function bonusOf(address token, address sender) public view returns (uint) {
    return _depositBonus(
      deposits[token][sender], depositSums[token], bonusSums[token]);
  }

  /// @param token address of token contract
  /// @return sum of all current deposits of the token
  function depositsSum(address token) public view returns (uint) {
    return depositSums[token];
  }

  /// @param token address of token contract
  /// @return size the current bonus pool for the token
  function bonusesPool(address token) public view returns (uint) {
    return bonusSums[token];
  }

  /// @param token address of token contract
  /// @param sender address of the depositor
  /// @return time in seconds left to wait until sender's deposit can
  function timeLeftToHoldOf(
    address token, 
    address sender
  ) public view returns (uint) {
    if (balanceOf(token, sender) == 0) return 0;
    uint timeHeld = _depositTimeHeld(deposits[token][sender]);
    return (timeHeld < commitPeriod) ? (commitPeriod - timeHeld) : 0;
  }

  function _withdraw(address token) internal {
    uint withdrawAmount = _withdrawAmountAndUpdate(token);
    IERC20(token).safeTransfer(msg.sender, withdrawAmount);
  }

  function _withdrawETH() internal {
    uint withdrawAmount = _withdrawAmountAndUpdate(WETH);
    IWETH(WETH).withdraw(withdrawAmount);
    payable(msg.sender).transfer(withdrawAmount);
  }
  
  /// @dev emits the Withdrawed event
  function _withdrawAmountAndUpdate(address token) internal returns (uint) {
    Deposit memory dep = deposits[token][msg.sender];

    // calculate penalty & bunus before making changes
    uint penalty = _depositPenalty(dep);
    // only get bonus if no penalty
    uint bonus = (penalty == 0) ? 
      _depositBonus(dep, depositSums[token], bonusSums[token]) : 0;
    uint withdrawAmount = dep.value - penalty + bonus;

    // update state
    // remove deposit
    deposits[token][msg.sender] = Deposit(0, 0);
    // update total deposits
    depositSums[token] -= dep.value;
    // update bonus
    bonusSums[token] = bonusSums[token] + penalty - bonus;
    
    // emit event here with all the data
    emit Withdrawed(
      token,
      msg.sender,
      withdrawAmount, 
      dep.value, 
      penalty, 
      bonus, 
      _depositTimeHeld(dep));
    
    return withdrawAmount;
  }

  function _depositTimeHeld(Deposit memory dep) internal view returns (uint) {
    return block.timestamp - dep.time;
  }

  function _depositPenalty(Deposit memory dep) internal view returns (uint) {
    uint timeHeld = _depositTimeHeld(dep);
    if (timeHeld >= commitPeriod) {
      return 0;
    } else {
      uint timeLeft = commitPeriod - timeHeld;
      // order important to prevent rounding to 0
      return ((dep.value * initialPenaltyPercent * timeLeft) / commitPeriod) / 100;
    }
  }

  function _depositBonus(
    Deposit memory dep, 
    uint depositsSum_,
    uint bonusSum_
  ) internal pure returns (uint) {
    if (dep.value == 0 || bonusSum_ == 0) {
      return 0;  // no luck
    } else {
      // order important to prevent rounding to 0
      return (bonusSum_ * dep.value) / depositsSum_;
    }
  }

}

/// @dev interface for interacting with WETH (wrapped ether) for handling ETH
/// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IWETH.sol
interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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