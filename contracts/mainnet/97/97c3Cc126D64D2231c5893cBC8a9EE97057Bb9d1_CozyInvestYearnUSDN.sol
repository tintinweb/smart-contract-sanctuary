// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/ICozyInvest.sol";
import "./lib/CozyInvestHelpers.sol";

interface ICrvDepositZap {
  function token() external view returns (address);

  function add_liquidity(uint256[4] calldata amounts, uint256 minMintAmount) external payable returns (uint256);

  function remove_liquidity_one_coin(
    uint256 amount,
    int128 index,
    uint256 minAmount
  ) external returns (uint256);
}

interface IYVault is IERC20 {
  function deposit() external returns (uint256); // providing no inputs to `deposit` deposits max amount for msg.sender

  function withdraw(uint256 maxShares) external returns (uint256); // defaults to msg.sender as recipient and 0.01 BPS maxLoss
}

/**
 * @notice On-chain scripts for borrowing from Cozy and using the borrowed funds to supply to Curve, and
 * depositing those Curve receipt tokens into the Yearn USDN vault
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestYearnUSDN is CozyInvestHelpers, ICozyInvest3, ICozyDivest3 {
  // --- Cozy markets ---
  /// @notice Cozy protection market to borrow from: Cozy-USDC-3-Yearn V2 Curve USDN Trigger
  ICozyToken public constant protectionMarket = ICozyToken(0x11581582Aa816c8293e67c726AF49Fc2C8b98C6e);

  /// @notice Cozy money market with USDC underlying
  ICozyToken public constant moneyMarket = ICozyToken(0xdBDF2fC3Af896e18f2A9DC58883d12484202b57E);

  /// @notice USDC
  IERC20 public immutable underlying;

  // --- Curve parameters ---
  /// @notice Curve Deposit Zap helper contract
  ICrvDepositZap public constant depositZap = ICrvDepositZap(0x094d12e5b541784701FD8d65F11fc0598FBC6332);

  /// @notice Curve USDN receipt token
  IERC20 public immutable curveToken;

  // @dev Index to use in arrays when specifying USDC for the Curve deposit zap
  int128 internal constant usdcIndex = 2;

  // --- Yearn Parameters ---
  /// @notice Yearn USDN vault
  IYVault public constant yearn = IYVault(0x3B96d491f067912D18563d56858Ba7d6EC67a6fa);

  constructor() {
    underlying = IERC20(moneyMarket.underlying());
    curveToken = IERC20(depositZap.token());
  }

  /**
   * @notice Protected invest method for borrowing from given cozy market, using those funds to add
   * liquidity to the Curve pool, and depositing that receipt token into the Yearn vault
   * @param _market Address of the market to borrow from
   * @param _borrowAmount Amount to borrow and deposit into Curve
   * @param _curveMinAmountOut The minAmountOut we expect to receive when adding liquidity to Curve
   */
  function invest(
    address _market,
    uint256 _borrowAmount,
    uint256 _curveMinAmountOut
  ) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // Borrow USDC from Cozy
    require(ICozyToken(_market).borrow(_borrowAmount) == 0, "Borrow failed");

    // Add liquidity to Curve, which returns a receipt token
    TransferHelper.safeApprove(address(underlying), address(depositZap), type(uint256).max);
    depositZap.add_liquidity([0, 0, _borrowAmount, 0], _curveMinAmountOut);

    // Deposit the Curve USDN receipt tokens into the Yearn vault
    if (curveToken.allowance(address(this), address(yearn)) == 0) {
      // We need this allowance check first because the curve token requires that there is
      // zero allowance when calling `approve`
      TransferHelper.safeApprove(address(curveToken), address(yearn), type(uint256).max);
    }
    yearn.deposit();
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _market Address of the market to repay
   * @param _recipient Address where any leftover tokens should be transferred
   * @param _yearnRedeemAmount Amount of Yearn receipt tokens to redeem
   * @param _curveMinAmountOut The minAmountOut we expect to receive when removing liquidity from Curve
   * @param _excessTokens Quantity to transfer from the caller into this address to ensure
   * the borrow can be repaid in full. Only required if you want to repay the full borrow amount and the
   * amount obtained from withdrawing from the invest opportunity will not cover the full debt. A value of zero
   * will not attempt to transfer tokens from the caller, and the transfer will not be attempted if it's not required
   */
  function divest(
    address _market,
    address _recipient,
    uint256 _yearnRedeemAmount,
    uint256 _curveMinAmountOut,
    uint256 _excessTokens
  ) external {
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");

    // Redeem Yearn receipt tokens for Curve USDN receipt tokens
    uint256 _quantityRedeemed = yearn.withdraw(_yearnRedeemAmount);

    // Approve Curve's depositZap to spend our yearn tokens. We skip the allowance check and just always approve,
    // because it's a negligible impact in gas cost relative to transaction cost, but makes contract deploy cheaper
    // Deposit the Curve USDN receipt tokens into the Yearn vault
    if (curveToken.allowance(address(this), address(depositZap)) == 0) {
      // We need this allowance check first because the curve token requires that there is
      // zero allowance when calling `approve`
      TransferHelper.safeApprove(address(curveToken), address(depositZap), type(uint256).max);
    }

    // Redeem from Curve
    depositZap.remove_liquidity_one_coin(_quantityRedeemed, usdcIndex, _curveMinAmountOut);

    // Pay back as much of the borrow as possible, excess is refunded to `recipient`
    executeMaxRepay(_market, address(underlying), _excessTokens);

    // Transfer any remaining tokens to the user after paying back borrow
    TransferHelper.safeTransfer(address(underlying), _recipient, underlying.balanceOf(address(this)));
  }
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