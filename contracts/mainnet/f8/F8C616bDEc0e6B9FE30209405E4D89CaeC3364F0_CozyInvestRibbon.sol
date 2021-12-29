// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICozy.sol";
import "./interfaces/ICozyInvest.sol";
import "./lib/CozyInvestHelpers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IRibbon {
  function depositETH() external payable;

  function initiateWithdraw(uint256 numShares) external;

  function withdrawInstantly(uint256 amount) external;

  function completeWithdraw() external;
}

/**
 * @notice On-chain scripts for borrowing from Cozy and using the borrowed funds to
 * supply to curve and then deposit into Ribbon
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestRibbon is CozyInvestHelpers, ICozyInvest2 {
  using Address for address payable;
  using SafeERC20 for IERC20;

  /// @notice The unprotected money market we borrow from / repay to
  address public immutable moneyMarket;

  /// @notice The protection market we borrow from / repay to
  address public immutable protectionMarket;

  /// @notice Maximillion contract for repaying ETH debt
  IMaximillion public constant maximillion = IMaximillion(0xf859A1AD94BcF445A406B892eF0d3082f4174088);

  /// @notice Ribbon ETH theta vault contract address
  address public immutable ribbon = 0x25751853Eab4D0eB3652B5eB6ecB102A2789644B;

  constructor(address _moneyMarket, address _protectionMarket) {
    moneyMarket = _moneyMarket;
    protectionMarket = _protectionMarket;
  }

  /**
   * @notice Invest method for borrowing ETH and depositing it to Ribbon
   * @param _market Address of the market to borrow from
   * @param _borrowAmount Amount of underlying to borrow and invest
   */
  function invest(address _market, uint256 _borrowAmount) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");
    require(ICozyToken(_market).borrow(_borrowAmount) == 0, "Borrow failed");

    IRibbon _ribbon = IRibbon(ribbon);
    _ribbon.depositETH{value: _borrowAmount}();
  }

  /**
   * @notice Instantly withdraws funds from Ribbon that are available to withdraw.
   * @param _market Address of the market to repay debt to
   * @param _recipient Address where any leftover funds should be transferred
   * @param _withdrawAmount Amount of Curve receipt tokens to redeem
   */
  function withdrawInstantly(
    address _market,
    address _recipient,
    uint256 _withdrawAmount
  ) external payable {
    // 1. Borrow underlying from cozy
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // 2. Withdraws instantly from ribbon
    IRibbon _ribbon = IRibbon(ribbon);
    _ribbon.withdrawInstantly(_withdrawAmount);

    // 3. Pay back as much of the borrow as possible, excess ETH is refunded to `recipient`
    maximillion.repayBehalfExplicit{value: address(this).balance}(address(this), ICozyEther(_market));

    // 4. Transfer any remaining funds to the user
    payable(_recipient).sendValue(address(this).balance);
  }

  /**
   * @notice Initiates two-step divest method from Ribbon. completeWithdraw() must be called later once the next round has started.
   * @param _numShares Number of shares to divest
   */
  function divest(uint256 _numShares) external {
    IRibbon _ribbon = IRibbon(ribbon);
    _ribbon.initiateWithdraw(_numShares);
  }

  /**
   * @notice Instantly withdraws funds from Ribbon that are available to withdraw. divest() must be called beforehand.
   * @param _market Address of the market to repay debt to
   * @param _recipient Address where any leftover funds should be transferred
   */
  function completeWithdraw(address _market, address _recipient) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // 1. Completes withdraw from Ribbon
    IRibbon _ribbon = IRibbon(ribbon);
    _ribbon.completeWithdraw();

    // 2. Pay back as much of the borrow as possible, excess ETH is refunded to `recipient`
    maximillion.repayBehalfExplicit{value: address(this).balance}(address(this), ICozyEther(_market));

    // 3. Transfer any remaining funds to the user
    payable(_recipient).sendValue(address(this).balance);
  }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @dev Interfaces for Cozy contracts
 */

interface ICozyShared {
  function underlying() external view returns (address);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);
}

interface ICozyToken is ICozyShared {
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);
}

interface ICozyEther is ICozyShared {
  function repayBorrowBehalf(address borrower) external payable;
}

interface IMaximillion {
  function repayBehalfExplicit(address borrower, ICozyEther market) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @notice Interfaces for developing on-chain scripts for borrowing from the Cozy markets then supplying to
 * investment opportunities in a single transaction
 * @dev Contract developed from this interface are intended to be used by delegatecalling to it from a DSProxy
 * @dev For interactions with the Cozy Protocol, ensure the return value is zero and revert otherwise. See
 * the Cozy Protocol documentation on error codes for more info
 */
interface ICozyInvest1 {
  function invest(
    address _ethMarket,
    uint256 _borrowAmount,
    uint256 _minAmountOut
  ) external payable;
}

interface ICozyInvest2 {
  function invest(address _market, uint256 _borrowAmount) external;
}

interface ICozyInvest3 {
  // NOTE: Same signature as ICozyInvest1, but without the payable modifier
  function invest(
    address _ethMarket,
    uint256 _borrowAmount,
    uint256 _minAmountOut
  ) external;
}

interface ICozyInvest4 {
  function invest(
    address _market,
    uint256 _borrowAmount,
    uint256 _minToMint,
    uint256 _deadline
  ) external;
}

interface ICozyInvest5 {
  function invest(
    address _ethMarket,
    uint256 _borrowAmount,
    uint256 _minAmountOut
  ) external;
}

interface ICozyDivest1 {
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _redeemAmount,
    uint256 _curveMinAmountOut
  ) external payable;
}

interface ICozyDivest2 {
  // NOTE: Same signature as above (except for the payable part), but with different meanings of each input
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _excessTokens
  ) external;
}

interface ICozyDivest3 {
  function divest(
    address _market,
    address _recipient,
    uint256 _yearnRedeemAmount,
    uint256 _curveMinAmountOut,
    uint256 _excessTokens
  ) external;
}

interface ICozyDivest4 {
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _minWithdrawAmount,
    uint256 _deadline
  ) external payable;
}

interface ICozyDivest5 {
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _excessTokens,
    uint256 _curveMinAmountOut
  ) external;
}

interface ICozyDivest6 {
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _withdrawAmount
  ) external payable;
}

interface ICozyReward {
  function claimRewards(address _recipient) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interfaces/ICozy.sol";
import "./TransferHelper.sol";

abstract contract CozyInvestHelpers {

  /**
   * @notice Repays as much token debt as possible
   * @param _market Market to repay
   * @param _underlying That market's underlying token (can be obtained by a call, but passing it in saves gas)
   * @param _excessTokens Quantity to transfer from the caller into this address to ensure
   * the borrow can be repaid in full. Only required if you want to repay the full borrow amount and the
   * amount obtained from withdrawing from the invest opportunity will not cover the full debt. A value of zero
   * will not attempt to transfer tokens from the caller, and the transfer will not be attempted if it's not required
   */
  function executeMaxRepay(
    address _market,
    address _underlying,
    uint256 _excessTokens
  ) internal {
    // Pay back as much of the borrow as possible, excess is refunded to `recipient`
    uint256 _borrowBalance = ICozyToken(_market).borrowBalanceCurrent(address(this));
    uint256 _initialBalance = IERC20(_underlying).balanceOf(address(this));
    if (_initialBalance < _borrowBalance && _excessTokens > 0) {
      TransferHelper.safeTransferFrom(_underlying, msg.sender, address(this), _excessTokens);
    }
    uint256 _balance = _initialBalance + _excessTokens; // this contract's current balance
    uint256 _repayAmount = _balance >= _borrowBalance ? type(uint256).max : _balance;

    TransferHelper.safeApprove(_underlying, address(_market), _repayAmount);
    require(ICozyToken(_market).repayBorrow(_repayAmount) == 0, "Repay failed");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Based on https://github.com/Uniswap/v3-periphery/blob/80f26c86c57b8a5e4b913f42844d4c8bd274d058/contracts/libraries/TransferHelper.sol
 */
library TransferHelper {
  /**
   * @notice Transfers tokens from the targeted address to the given destination
   * @notice Errors with 'STF' if transfer fails
   * @param token The contract address of the token to be transferred
   * @param from The originating address from which the tokens will be transferred
   * @param to The destination address of the transfer
   * @param value The amount to be transferred
   */
  function safeTransferFrom(
      address token,
      address from,
      address to,
      uint256 value
  ) internal {
      (bool success, bytes memory data) =
          token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
      require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer from failed");
  }

  /**
   * @notice Transfers tokens from msg.sender to a recipient
   * @dev Errors with ST if transfer fails
   * @param token The contract address of the token which will be transferred
   * @param to The recipient of the transfer
   * @param value The value of the transfer
   */
  function safeTransfer(
      address token,
      address to,
      uint256 value
  ) internal {
      (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
      require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
  }

  /**
   * @notice Approves the stipulated contract to spend the given allowance in the given token
   * @dev Errors with 'SA' if transfer fails
   * @param token The contract address of the token to be approved
   * @param to The target of the approval
   * @param value The amount of the given token the target will be allowed to spend
   */
  function safeApprove(
      address token,
      address to,
      uint256 value
  ) internal {
      (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
      require(success && (data.length == 0 || abi.decode(data, (bool))), "Approve failed");
  }
}