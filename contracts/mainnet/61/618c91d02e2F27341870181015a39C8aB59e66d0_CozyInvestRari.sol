// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/ICozyInvest.sol";
import "./lib/CozyInvestHelpers.sol";

interface IRariPool is IERC20 {
  function deposit(string calldata currencyCode, uint256 amount) external;

  function withdraw(string calldata currencyCode, uint256 amount) external returns (uint256);

  function rariFundToken() external view returns (address);
}

/**
 * @notice On-chain scripts for borrowing from the Cozy-DAI-Rari Trigger protection market, and
 * depositing it to the Rari DAI pool.
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 * @dev This contract won't work if `token` is like USDT in that it's `approve` method tries to mitigate the ERC-20
 * approval attack described here: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
 */
contract CozyInvestRari is CozyInvestHelpers, ICozyInvest2, ICozyDivest2 {
  /// @notice The unprotected money market we borrow from / repay to
  address public immutable moneyMarket;
  /// @notice The protected version of the market
  address public immutable protectionMarket;
  /// @notice Rari pool manager
  address public immutable poolManager;
  /// @notice Rari receipt token
  address public immutable rariPoolToken;
  /// @notice Rari market this invest integration is for (e.g. DAI, USDC)
  address public immutable token;

  constructor(
    address _moneyMarket,
    address _protectionMarket,
    address _poolManager,
    address _token
  ) {
    moneyMarket = _moneyMarket;
    protectionMarket = _protectionMarket;
    poolManager = _poolManager;
    rariPoolToken = IRariPool(_poolManager).rariFundToken();
    token = _token;
  }

  /**
   * @notice invest method for borrowing from a given market address and then depositing to the Rari pool
   * @param _marketAddress Market address to borrow from
   * @param _borrowAmount Amount to borrow and deposit into the Rari pool
   */
  function invest(address _marketAddress, uint256 _borrowAmount) external {
    require((_marketAddress == moneyMarket || _marketAddress == protectionMarket), "Invalid borrow market");
    ICozyToken _market = ICozyToken(_marketAddress);

    // Borrow from market
    require(_market.borrow(_borrowAmount) == 0, "Borrow failed");

    // Approve the pool manager to spend. We only approve the borrow amount for security because
    // the pool mananger is an upgradeable proxy
    // Skip allowance check and just always approve, it's a minor swing in gas (0.08%) and makes it
    // cheaper to deploy
    TransferHelper.safeApprove(token, poolManager, _borrowAmount);

    // Deposit into the pool
    IRariPool(poolManager).deposit(IERC20Metadata(token).symbol(), _borrowAmount);
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _marketAddress Market address to repay to
   * @param _recipient Address where any leftover tokens should be transferred
   * @param _withdrawAmount Amount to withdraw
   * @param _excessTokens Quantity to transfer from the caller into this address to ensure
   * the borrow can be repaid in full. Only required if you want to repay the full borrow amount and the
   * amount obtained from withdrawing from Rari will not cover the full debt. A value of zero will not
   * attempt to transfer tokens from the caller, and the transfer will not be attempted if it's not required
   */
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _excessTokens
  ) external {
    // Check trigger
    require((_marketAddress == moneyMarket || _marketAddress == protectionMarket), "Invalid borrow market");

    // Withdraw from pool
    IRariPool(poolManager).withdraw(IERC20Metadata(token).symbol(), _withdrawAmount);

    // Pay back as much of the borrow as possible, excess is refunded to `recipient`
    executeMaxRepay(_marketAddress, token, _excessTokens);

    // Transfer any remaining tokens to the user after paying back borrow
    TransferHelper.safeTransfer(token, _recipient, IERC20(token).balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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