// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IHealthCheck.sol";
import "../interfaces/IStrategy.sol";
import "./SingleAssetVaultBase.sol";
import "../access/AccessControlManager.sol";

contract SingleAssetVault is SingleAssetVaultBase, Pausable, ReentrancyGuard, AccessControlManager {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  event StrategyReported(
    address indexed _strategyAddress,
    uint256 _gain,
    uint256 _loss,
    uint256 _debtPaid,
    uint256 _totalGain,
    uint256 _totalLoss,
    uint256 _totalDebt,
    uint256 _debtAdded,
    uint256 _debtRatio
  );

  uint256 internal constant SECONDS_PER_YEAR = 31_556_952; // 365.2425 days

  /// @dev construct a vault using a single asset.
  /// @param _name the name of the vault
  /// @param _symbol the symbol of the vault
  /// @param _governance the address of the manager of the vault
  /// @param _token the address of the token asset
  /* solhint-disable no-empty-blocks */
  constructor(
    string memory _name,
    string memory _symbol,
    address _governance,
    address _gatekeeper,
    address _rewards,
    address _strategyDataStoreAddress,
    address _token
  )
    SingleAssetVaultBase(_name, _symbol, _governance, _gatekeeper, _rewards, _strategyDataStoreAddress, _token)
    AccessControlManager(new address[](0))
  {
    _pause();
  }

  /* solhint-enable */

  function pause() external {
    _onlyGovernanceOrGatekeeper();
    _pause();
  }

  function unpause() external {
    _onlyGovernanceOrGatekeeper();
    _unpause();
  }

  function addAccessControlPolicies(address[] calldata _policies) external {
    _onlyGovernanceOrGatekeeper();
    _addAccessControlPolicys(_policies);
  }

  function removeAccessControlPolicies(address[] calldata _policies) external {
    _onlyGovernanceOrGatekeeper();
    _removeAccessControlPolicys(_policies);
  }

  /// @notice Deposits `_amount` `token`, issuing shares to `recipient`. If the
  ///  Vault is in Emergency Shutdown, deposits will not be accepted and this
  ///  call will fail.
  /// @dev Measuring quantity of shares to issues is based on the total
  ///  outstanding debt that this contract has ("expected value") instead
  ///  of the total balance sheet it has ("estimated value") has important
  ///  security considerations, and is done intentionally. If this value were
  ///  measured against external systems, it could be purposely manipulated by
  ///  an attacker to withdraw more assets than they otherwise should be able
  ///  to claim by redeeming their shares.
  ///  On deposit, this means that shares are issued against the total amount
  ///  that the deposited capital can be given in service of the debt that
  ///  Strategies assume. If that number were to be lower than the "expected
  ///  value" at some future point, depositing shares via this method could
  ///  entitle the depositor to *less* than the deposited value once the
  ///  "realized value" is updated from further reports by the Strategies
  ///  to the Vaults.
  ///  Care should be taken by integrators to account for this discrepancy,
  ///  by using the view-only methods of this contract (both off-chain and
  ///  on-chain) to determine if depositing into the Vault is a "good idea".
  /// @param _amount The quantity of tokens to deposit, defaults to all.
  ///  caller's address.
  /// @param _recipient the address that will receive the vault shares
  /// @return The issued Vault shares.
  function deposit(uint256 _amount, address _recipient) external whenNotPaused nonReentrant returns (uint256) {
    _onlyNotEmergencyShutdown();
    return _deposit(_amount, _recipient);
  }

  /// @notice Withdraws the calling account's tokens from this Vault, redeeming
  ///  amount `_shares` for an appropriate amount of tokens.
  ///  See note on `setWithdrawalQueue` for further details of withdrawal
  ///  ordering and behavior.
  /// @dev Measuring the value of shares is based on the total outstanding debt
  ///  that this contract has ("expected value") instead of the total balance
  ///  sheet it has ("estimated value") has important security considerations,
  ///  and is done intentionally. If this value were measured against external
  ///  systems, it could be purposely manipulated by an attacker to withdraw
  ///  more assets than they otherwise should be able to claim by redeeming
  ///  their shares.

  ///  On withdrawal, this means that shares are redeemed against the total
  ///  amount that the deposited capital had "realized" since the point it
  ///  was deposited, up until the point it was withdrawn. If that number
  ///  were to be higher than the "expected value" at some future point,
  ///  withdrawing shares via this method could entitle the depositor to
  ///  *more* than the expected value once the "realized value" is updated
  ///  from further reports by the Strategies to the Vaults.

  ///  Under exceptional scenarios, this could cause earlier withdrawals to
  ///  earn "more" of the underlying assets than Users might otherwise be
  ///  entitled to, if the Vault's estimated value were otherwise measured
  ///  through external means, accounting for whatever exceptional scenarios
  ///  exist for the Vault (that aren't covered by the Vault's own design.)
  ///  In the situation where a large withdrawal happens, it can empty the
  ///  vault balance and the strategies in the withdrawal queue.
  ///  Strategies not in the withdrawal queue will have to be harvested to
  ///  rebalance the funds and make the funds available again to withdraw.
  /// @param _maxShares How many shares to try and redeem for tokens, defaults to all.
  /// @param _recipient The address to issue the shares in this Vault to.
  /// @param _maxLoss The maximum acceptable loss to sustain on withdrawal in basis points.
  /// @return The quantity of tokens redeemed for `_shares`.
  function withdraw(
    uint256 _maxShares,
    address _recipient,
    uint256 _maxLoss
  ) external whenNotPaused nonReentrant returns (uint256) {
    _onlyNotEmergencyShutdown();
    return _withdraw(_maxShares, _recipient, _maxLoss);
  }

  /// @notice Reports the amount of assets the calling Strategy has free (usually in terms of ROI).
  ///  The performance fee is determined here, off of the strategy's profits
  ///  (if any), and sent to governance.
  ///  The strategist's fee is also determined here (off of profits), to be
  ///  handled according to the strategist on the next harvest.
  ///  This may only be called by a Strategy managed by this Vault.
  /// @dev For approved strategies, this is the most efficient behavior.
  ///  The Strategy reports back what it has free, then Vault "decides"
  ///  whether to take some back or give it more. Note that the most it can
  ///  take is `gain + _debtPayment`, and the most it can give is all of the
  ///  remaining reserves. Anything outside of those bounds is abnormal behavior.
  ///  All approved strategies must have increased diligence around
  ///  calling this function, as abnormal behavior could become catastrophic.
  /// @param _gain Amount Strategy has realized as a gain on it's investment since its last report, and is free to be given back to Vault as earnings
  /// @param _loss Amount Strategy has realized as a loss on it's investment since its last report, and should be accounted for on the Vault's balance sheet.
  ///  The loss will reduce the debtRatio. The next time the strategy will harvest, it will pay back the debt in an attempt to adjust to the new debt limit.
  /// @param _debtPayment Amount Strategy has made available to cover outstanding debt
  /// @return Amount of debt outstanding (if totalDebt > debtLimit or emergency shutdown).
  function report(
    uint256 _gain,
    uint256 _loss,
    uint256 _debtPayment
  ) external returns (uint256) {
    address callerStrategy = _msgSender();
    _validateStrategy(callerStrategy);
    require(token.balanceOf(callerStrategy) >= _gain.add(_debtPayment), "not enough balance");

    _checkStrategyHealth(callerStrategy, _gain, _loss, _debtPayment);

    _reportLoss(callerStrategy, _loss);
    // Returns are always "realized gains"
    strategies[callerStrategy].totalGain = strategies[callerStrategy].totalGain.add(_gain);

    // Assess both management fee and performance fee, and issue both as shares of the vault
    uint256 totalFees = _assessFees(callerStrategy, _gain);
    // Compute the line of credit the Vault is able to offer the Strategy (if any)
    uint256 credit = _creditAvailable(callerStrategy);
    // Outstanding debt the Strategy wants to take back from the Vault (if any)
    // NOTE: debtOutstanding <= StrategyInfo.totalDebt
    uint256 debt = _debtOutstanding(callerStrategy);
    uint256 debtPayment = Math.min(debt, _debtPayment);

    if (debtPayment > 0) {
      _decreaseDebt(callerStrategy, debtPayment);
      debt = debt.sub(debtPayment);
    }

    // Update the actual debt based on the full credit we are extending to the Strategy
    // or the returns if we are taking funds back
    // NOTE: credit + self.strategies[msg.sender].totalDebt is always < self.debtLimit
    // NOTE: At least one of `credit` or `debt` is always 0 (both can be 0)
    if (credit > 0) {
      _increaseDebt(callerStrategy, credit);
    }

    // Give/take balance to Strategy, based on the difference between the reported gains
    // (if any), the debt payment (if any), the credit increase we are offering (if any),
    // and the debt needed to be paid off (if any)
    // NOTE: This is just used to adjust the balance of tokens between the Strategy and
    //       the Vault based on the Strategy's debt limit (as well as the Vault's).
    uint256 totalAvailable = _gain + debtPayment;
    if (totalAvailable < credit) {
      // credit surplus, give to Strategy
      token.safeTransfer(callerStrategy, credit.sub(totalAvailable));
    } else if (totalAvailable > credit) {
      // credit deficit, take from Strategy
      token.safeTransferFrom(callerStrategy, address(this), totalAvailable.sub(credit));
    }
    // else, don't do anything because it is balanced

    _updateLockedProfit(_gain, totalFees, _loss);
    // solhint-disable-next-line not-rely-on-time
    strategies[callerStrategy].lastReport = block.timestamp;
    // solhint-disable-next-line not-rely-on-time
    lastReport = block.timestamp;

    StrategyInfo memory info = strategies[callerStrategy];
    uint256 strategyDebtRatio = _strategyDataStore().strategyDebtRatio(address(this), callerStrategy);
    emit StrategyReported(
      callerStrategy,
      _gain,
      _loss,
      debtPayment,
      info.totalGain,
      info.totalLoss,
      info.totalDebt,
      credit,
      strategyDebtRatio
    );

    if (strategyDebtRatio == 0 || emergencyShutdown) {
      // Take every last penny the Strategy has (Emergency Exit/revokeStrategy)
      // NOTE: This is different than `debt` in order to extract *all* of the returns
      return IStrategy(callerStrategy).estimatedTotalAssets();
    } else {
      // Otherwise, just return what we have as debt outstanding
      return debt;
    }
  }

  function _deposit(uint256 _amount, address _recipient) internal returns (uint256) {
    require(_recipient != address(0), "invalid recipient");
    require(_hasAccess(_msgSender(), address(this)), "no access");
    //TODO: do we also want to cap the `_amount` too?
    uint256 amount = _ensureValidDepositAmount(_msgSender(), _amount);
    uint256 shares = _issueSharesForAmount(_recipient, amount);
    token.safeTransferFrom(_msgSender(), address(this), amount);
    return shares;
  }

  function _issueSharesForAmount(address _recipient, uint256 _amount) internal returns (uint256) {
    uint256 shares = 0;
    uint256 supply = totalSupply();
    if (supply > 0) {
      // Mint amount of shares based on what the Vault is managing overall
      shares = _amount.mul(supply).div(_freeFunds());
    } else {
      // no existing shares, mint 1:1
      shares = _amount;
    }

    require(shares > 0, "invalid share amount");
    _mint(_recipient, shares);
    return shares;
  }

  function _assessFees(address _strategy, uint256 _gain) internal returns (uint256) {
    uint256 totalFee_;
    uint256 performanceFee_;
    (totalFee_, performanceFee_) = _calculateFees(_strategy, _gain);

    if (totalFee_ > 0) {
      // rewards are given in the form of shares of the vault. This will allow further gain if the vault is making more profit.
      // but it does mean the strategist/governance will need to redeem the shares to get the tokens.
      // TODO: should we just transfer the token values to the rewards & strategist instead?
      uint256 rewards_ = _issueSharesForAmount(address(this), totalFee_);
      if (performanceFee_ > 0) {
        uint256 strategistReward_ = rewards_.mul(performanceFee_).div(totalFee_);
        //TODO: this transfer the rewards to the strategy, not the strategist. How does the strategist get the rewards?
        _transfer(address(this), _strategy, strategistReward_);
      }

      if (balanceOf(address(this)) > 0) {
        _transfer(address(this), rewards, balanceOf(address(this)));
      }
    }
    return totalFee_;
  }

  function _withdraw(
    uint256 _maxShares,
    address _recipient,
    uint256 _maxLoss
  ) internal returns (uint256) {
    require(_recipient != address(0), "invalid recipient");
    require(_maxLoss <= MAX_BASIS_POINTS, "invalid maxLoss");
    uint256 shares = _ensureValidShares(_msgSender(), _maxShares);
    uint256 value = _shareValue(shares);
    uint256 vaultBalance = token.balanceOf(address(this));
    uint256 totalLoss = 0;
    if (value > vaultBalance) {
      // We need to go get some from our strategies in the withdrawal queue
      // NOTE: This performs forced withdrawals from each Strategy. During
      // forced withdrawal, a Strategy may realize a loss. That loss
      // is reported back to the Vault, and the will affect the amount
      // of tokens that the withdrawer receives for their shares. They
      // can optionally specify the maximum acceptable loss (in BPS)
      // to prevent excessive losses on their withdrawals (which may
      // happen in certain edge cases where Strategies realize a loss)
      totalLoss = _withdrawFromStrategies(value);
      if (totalLoss > 0) {
        value = value.sub(totalLoss);
      }
      vaultBalance = token.balanceOf(address(this));
    }
    // NOTE: We have withdrawn everything possible out of the withdrawal queue,
    // but we still don't have enough to fully pay them back, so adjust
    // to the total amount we've freed up through forced withdrawals
    if (value > vaultBalance) {
      value = vaultBalance;
      // NOTE: Burn # of shares that corresponds to what Vault has on-hand,
      // including the losses that were incurred above during withdrawals
      shares = _sharesForAmount(value.add(totalLoss));
    }
    // NOTE: This loss protection is put in place to revert if losses from
    // withdrawing are more than what is considered acceptable.
    require(totalLoss <= _maxLoss.mul(value.add(totalLoss)).div(MAX_BASIS_POINTS), "loss is over limit");
    // burn shares
    _burn(_msgSender(), shares);

    // Withdraw remaining balance to _recipient (may be different to msg.sender) (minus fee)
    token.safeTransfer(_recipient, value);
    return value;
  }

  function _withdrawFromStrategies(uint256 _withdrawValue) internal returns (uint256) {
    uint256 totalLoss = 0;
    uint256 value = _withdrawValue;
    address[] memory withdrawQueue = _strategyDataStore().withdrawQueue(address(this));
    for (uint256 i = 0; i < withdrawQueue.length; i++) {
      address strategyAddress = withdrawQueue[i];
      IStrategy strategyToWithdraw = IStrategy(strategyAddress);
      uint256 vaultBalance = token.balanceOf(address(this));
      if (value <= vaultBalance) {
        // there are enough tokens in the vault now, no need to continue
        break;
      }
      // NOTE: Don't withdraw more than the debt so that Strategy can still
      // continue to work based on the profits it has
      // NOTE: This means that user will lose out on any profits that each
      // Strategy in the queue would return on next harvest, benefiting others
      uint256 amountNeeded = Math.min(value.sub(vaultBalance), strategies[strategyAddress].totalDebt);
      if (amountNeeded == 0) {
        // nothing to withdraw from the strategy, try the next one
        continue;
      }
      uint256 loss = strategyToWithdraw.withdraw(amountNeeded);
      uint256 withdrawAmount = token.balanceOf(address(this)).sub(vaultBalance);
      if (loss > 0) {
        value = value.sub(loss);
        totalLoss = totalLoss.add(loss);
        _reportLoss(strategyAddress, loss);
      }

      // Reduce the Strategy's debt by the amount withdrawn ("realized returns")
      // NOTE: This doesn't add to returns as it's not earned by "normal means"
      _decreaseDebt(strategyAddress, withdrawAmount);
    }
    return totalLoss;
  }

  function _reportLoss(address _strategy, uint256 _loss) internal {
    if (_loss > 0) {
      require(strategies[_strategy].totalDebt >= _loss, "invalid loss");
      uint256 totalDebtRatio_ = _strategyDataStore().vaultTotalDebtRatio(address(this));
      uint256 strategyDebtRatio_ = _strategyDataStore().strategyDebtRatio(address(this), _strategy);
      // make sure we reduce our trust with the strategy by the amount of loss
      if (totalDebtRatio_ != 0) {
        uint256 ratioChange_ = Math.min(_loss.mul(totalDebtRatio_).div(totalDebt), strategyDebtRatio_);
        _strategyDataStore().updateStrategyDebtRatio(address(this), _strategy, strategyDebtRatio_ - ratioChange_);
      }
      strategies[_strategy].totalLoss = strategies[_strategy].totalLoss.add(_loss);
      strategies[_strategy].totalDebt = strategies[_strategy].totalDebt.sub(_loss);
      totalDebt = totalDebt.sub(_loss);
    }
  }

  function _assessStrategyPerformanceFee(address _strategy, uint256 _gain) internal view returns (uint256) {
    return _gain.mul(_strategyDataStore().strategyPerformanceFee(address(this), _strategy)).div(MAX_BASIS_POINTS);
  }

  // calculate the management fee based on TVL.
  function _assessManagementFee(address _strategy) internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    uint256 duration = block.timestamp - strategies[_strategy].lastReport;
    require(duration > 0, "same block"); // should not be called twice within the same block
    // the managementFee is per year, so only charge the management fee for the period since last time it is charged.
    if (managementFee > 0) {
      uint256 strategyTVL = strategies[_strategy].totalDebt.sub(IStrategy(_strategy).delegatedAssets());
      return strategyTVL.mul(managementFee).div(MAX_BASIS_POINTS).mul(duration).div(SECONDS_PER_YEAR);
    }
    return 0;
  }

  function _ensureValidShares(address _account, uint256 _shares) internal view returns (uint256) {
    uint256 shares = _shares;
    uint256 balance = balanceOf(_account);
    if (shares > balance) {
      shares = balance;
    }
    require(shares > 0, "no shares");
    return shares;
  }

  function _increaseDebt(address _strategy, uint256 _amount) internal {
    strategies[_strategy].totalDebt = strategies[_strategy].totalDebt.add(_amount);
    totalDebt = totalDebt.add(_amount);
  }

  function _decreaseDebt(address _strategy, uint256 _amount) internal {
    strategies[_strategy].totalDebt = strategies[_strategy].totalDebt.sub(_amount);
    totalDebt = totalDebt.sub(_amount);
  }

  function _checkStrategyHealth(
    address _strategy,
    uint256 _gain,
    uint256 _loss,
    uint256 _debtPayment
  ) internal {
    if (healthCheck != address(0)) {
      IHealthCheck check = IHealthCheck(healthCheck);
      if (check.doHealthCheck(_strategy)) {
        require(
          check.check(
            _strategy,
            _gain,
            _loss,
            _debtPayment,
            _debtOutstanding(_strategy),
            strategies[_strategy].totalDebt
          ),
          "strategy is not healthy"
        );
      } else {
        check.enableCheck(_strategy);
      }
    }
  }

  function _calculateFees(address _strategy, uint256 _gain)
    internal
    view
    returns (uint256 totalFee, uint256 performanceFee)
  {
    // Issue new shares to cover fees
    // NOTE: In effect, this reduces overall share price by the combined fee
    // NOTE: may throw if Vault.totalAssets() > 1e64, or not called for more than a year
    // solhint-disable-next-line not-rely-on-time
    if (strategies[_strategy].activation == block.timestamp) {
      return (0, 0); // NOTE: Just added, no fees to assess
    }
    if (_gain == 0) {
      // The fees are not charged if there hasn't been any gains reported
      return (0, 0);
    }
    uint256 managementFee_ = _assessManagementFee(_strategy);
    uint256 strategyPerformanceFee_ = _assessStrategyPerformanceFee(_strategy, _gain);
    uint256 totalFee_ = managementFee_ + strategyPerformanceFee_;
    if (totalFee_ > _gain) {
      totalFee_ = _gain;
    }
    return (totalFee_, strategyPerformanceFee_);
  }

  function _ensureValidDepositAmount(address _account, uint256 _amount) internal view returns (uint256) {
    uint256 amount = _amount;
    uint256 balance = token.balanceOf(_account);
    if (amount > balance) {
      amount = balance;
    }
    uint256 availableLimit = _availableDepositLimit();
    if (amount > availableLimit) {
      amount = availableLimit;
    }
    require(amount > 0, "invalid amount");
    return amount;
  }

  function _updateLockedProfit(
    uint256 _gain,
    uint256 _totalFees,
    uint256 _loss
  ) internal {
    // Profit is locked and gradually released per block
    // NOTE: compute current locked profit and replace with sum of current and new
    uint256 locakedProfileBeforeLoss = _calculateLockedProfit() + _gain - _totalFees;
    if (locakedProfileBeforeLoss > _loss) {
      lockedProfit = locakedProfileBeforeLoss.sub(_loss);
    } else {
      lockedProfit = 0;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IHealthCheck {
  function check(
    address callerStrategy,
    uint256 profit,
    uint256 loss,
    uint256 debtPayment,
    uint256 debtOutstanding,
    uint256 totalDebt
  ) external view returns (bool);

  function doHealthCheck(address _strategy) external view returns (bool);

  function enableCheck(address _strategy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IStrategy {
  // *** Events *** //
  event Harvested(uint256 _profit, uint256 _loss, uint256 _debtPayment, uint256 _debtOutstanding);
  event StrategistUpdated(address _newStrategist);
  event KeeperUpdated(address _newKeeper);
  event RewardsUpdated(address _rewards);
  event MinReportDelayUpdated(uint256 _delay);
  event MaxReportDelayUpdated(uint256 _delay);
  event ProfitFactorUpdated(uint256 _profitFactor);
  event DebtThresholdUpdated(uint256 _debtThreshold);
  event EmergencyExitEnabled();

  // *** The following functions are used by the Vault *** //
  /// @notice returns the address of the token that the strategy wants
  function want() external view returns (address);

  /// @notice the address of the Vault that the strategy belongs to
  function vault() external view returns (address);

  /// @notice if the strategy is active
  function isActive() external view returns (bool);

  /// @notice migrate the strategy to the new one
  function migrate(address _newStrategy) external;

  /// @notice withdraw the amount from the strategy
  function withdraw(uint256 _amount) external returns (uint256);

  /// @notice the amount of total assets managed by this strategy that should not acount towards the TVL of the strategy
  function delegatedAssets() external view returns (uint256);

  /// @notice the total assets that the strategy is managing
  function estimatedTotalAssets() external view returns (uint256);

  // *** public read functions that can be called by anyone *** //
  function name() external view returns (string memory);

  function keeper() external view returns (address);

  function strategist() external view returns (address);

  function tendTrigger(uint256 _callCost) external view returns (bool);

  function harvestTrigger(uint256 _callCost) external view returns (bool);

  // *** write functions that can be called by the govenance, the strategist or the keeper *** //
  function tend() external;

  function harvest() external;

  // *** write functions that can be called by the govenance or the strategist ***//
  function setStrategist(address _strategist) external;

  function setKeeper(address _keeper) external;

  function setRewards(address _rewards) external;

  function setVault(address _vault) external;

  /// @notice `minReportDelay` is the minimum number of blocks that should pass for `harvest()` to be called.
  function setMinReportDelay(uint256 _delay) external;

  function setMaxReportDelay(uint256 _delay) external;

  /// @notice `profitFactor` is used to determine if it's worthwhile to harvest, given gas costs.
  function setProfitFactor(uint256 _profitFactor) external;

  /// @notice Sets how far the Strategy can go into loss without a harvest and report being required.
  function setDebtThreshold(uint256 _debtThreshold) external;

  // *** write functions that can be called by the govenance, or the strategist, or the guardian, or the management *** //
  function setEmergencyExit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseVault.sol";

abstract contract SingleAssetVaultBase is BaseVault {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /// @notice the timestamp of the last report received from a strategy
  uint256 internal lastReport;
  /// @notice how much profit is locked and cant be withdrawn
  uint256 public lockedProfit;
  /// @notice total value borrowed by all the strategies
  uint256 public totalDebt;
  address internal tokenAddress;
  IERC20 public token;

  constructor(
    string memory _name,
    string memory _symbol,
    address _governance,
    address _gatekeeper,
    address _rewards,
    address _strategyDataStoreAddress,
    address _token
  ) BaseVault(_name, _symbol, _governance, _gatekeeper, _rewards, _strategyDataStoreAddress) {
    require(_token != address(0), "invalid token address");
    tokenAddress = _token;
    token = IERC20(_token);
    // the vault decimals need to match the tokens to avoid any conversion
    vaultDecimals = ERC20(tokenAddress).decimals();
  }

  /// @notice Returns the total quantity of all assets under control of this
  ///   Vault, whether they're loaned out to a Strategy, or currently held in
  ///   the Vault.
  /// @return The total assets under control of this Vault.
  function totalAsset() external view returns (uint256) {
    return _totalAsset();
  }

  /// @notice the remaining amount of underlying tokens that still can be deposited into the vault before reaching the limit
  function availableDepositLimit() external view returns (uint256) {
    return _availableDepositLimit();
  }

  /// @notice Determines the maximum quantity of shares this Vault can facilitate a
  ///  withdrawal for, factoring in assets currently residing in the Vault,
  ///  as well as those deployed to strategies on the Vault's balance sheet.
  /// @dev Regarding how shares are calculated, see dev note on `deposit`.
  ///  If you want to calculated the maximum a user could withdraw up to,
  ///  you want to use this function.
  /// Note that the amount provided by this function is the theoretical
  ///  maximum possible from withdrawing, the real amount depends on the
  ///  realized losses incurred during withdrawal.
  /// @return The total quantity of shares this Vault can provide.
  function maxAvailableShares() external view returns (uint256) {
    return _maxAvailableShares();
  }

  /// @notice Gives the price for a single Vault share.
  /// @dev See dev note on `withdraw`.
  /// @return The value of a single share.
  function pricePerShare() external view returns (uint256) {
    return _shareValue(10**vaultDecimals);
  }

  /// @notice Determines if `_strategy` is past its debt limit and if any tokens
  ///  should be withdrawn to the Vault.
  /// @param _strategy The Strategy to check.
  /// @return The quantity of tokens to withdraw.
  function debtOutstanding(address _strategy) external view returns (uint256) {
    return _debtOutstanding(_strategy);
  }

  /// @notice Amount of tokens in Vault a Strategy has access to as a credit line.
  ///  This will check the Strategy's debt limit, as well as the tokens
  ///  available in the Vault, and determine the maximum amount of tokens
  ///  (if any) the Strategy may draw on.
  /// In the rare case the Vault is in emergency shutdown this will return 0.
  /// @param _strategy The Strategy to check.
  /// @return The quantity of tokens available for the Strategy to draw on.
  function creditAvailable(address _strategy) external view returns (uint256) {
    return _creditAvailable(_strategy);
  }

  /// @notice Provide an accurate expected value for the return this `strategy`
  /// would provide to the Vault the next time `report()` is called
  /// (since the last time it was called).
  /// @param _strategy The Strategy to determine the expected return for.
  /// @return The anticipated amount `strategy` should make on its investment since its last report.
  function expectedReturn(address _strategy) external view returns (uint256) {
    return _expectedReturn(_strategy);
  }

  /// @notice send the tokens that are not managed by the vault to the governance
  /// @param _token the token to send
  /// @param _amount the amount of tokens to send
  function sweep(address _token, uint256 _amount) external {
    _onlyGovernance();
    require(tokenAddress != _token, "invalid token");
    _sweep(_token, _amount, governance);
  }

  function _totalAsset() internal view returns (uint256) {
    return token.balanceOf(address(this)).add(totalDebt);
  }

  function _availableDepositLimit() internal view returns (uint256) {
    if (depositLimit > _totalAsset()) {
      return depositLimit.sub(_totalAsset());
    }
    return 0;
  }

  function _shareValue(uint256 _sharesAmount) internal view returns (uint256) {
    uint256 supply = totalSupply();
    // if the value is empty then the price is 1:1
    if (supply == 0) {
      return _sharesAmount;
    }
    return _sharesAmount.mul(_freeFunds()).div(supply);
  }

  function _calculateLockedProfit() internal view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    uint256 lockedFundRatio = block.timestamp.sub(lastReport).mul(lockedProfitDegradation);
    if (lockedFundRatio < DEGRADATION_COEFFICIENT) {
      return lockedProfit.sub(lockedFundRatio.mul(lockedProfit).div(DEGRADATION_COEFFICIENT));
    } else {
      return 0;
    }
  }

  function _freeFunds() internal view returns (uint256) {
    return _totalAsset().sub(_calculateLockedProfit());
  }

  function _sharesForAmount(uint256 _amount) internal view returns (uint256) {
    uint256 freeFunds_ = _freeFunds();
    if (freeFunds_ > 0) {
      return _amount.mul(totalSupply()).div(freeFunds_);
    }
    return 0;
  }

  function _maxAvailableShares() internal view returns (uint256) {
    uint256 shares_ = _sharesForAmount(token.balanceOf(address(this)));
    address[] memory withdrawQueue = _strategyDataStore().withdrawQueue(address(this));
    for (uint256 i = 0; i < withdrawQueue.length; i++) {
      shares_ = shares_.add(_sharesForAmount(strategies[withdrawQueue[i]].totalDebt));
    }
    return shares_;
  }

  function _debtOutstanding(address _strategy) internal view returns (uint256) {
    _validateStrategy(_strategy);
    if (_strategyDataStore().vaultTotalDebtRatio(address(this)) == 0) {
      return strategies[_strategy].totalDebt;
    }
    uint256 availableAssets_ = _totalAsset();
    uint256 strategyLimit_ = availableAssets_.mul(_strategyDataStore().strategyDebtRatio(address(this), _strategy)).div(
      MAX_BASIS_POINTS
    );
    uint256 strategyTotalDebt_ = strategies[_strategy].totalDebt;

    if (emergencyShutdown) {
      return strategyTotalDebt_;
    } else if (strategyTotalDebt_ <= strategyLimit_) {
      return 0;
    } else {
      return strategyTotalDebt_.sub(strategyLimit_);
    }
  }

  function _creditAvailable(address _strategy) internal view returns (uint256) {
    if (emergencyShutdown) {
      return 0;
    }
    _validateStrategy(_strategy);
    uint256 vaultTotalAsset_ = _totalAsset();
    uint256 vaultTotalDebtLimit_ = vaultTotalAsset_.mul(_strategyDataStore().vaultTotalDebtRatio(address(this))).div(
      MAX_BASIS_POINTS
    );
    uint256 vaultTotalDebt_ = totalDebt;

    uint256 strategyDebtLimit_ = vaultTotalAsset_
      .mul(_strategyDataStore().strategyDebtRatio(address(this), _strategy))
      .div(MAX_BASIS_POINTS);
    uint256 strategyTotalDebt_ = strategies[_strategy].totalDebt;
    uint256 strategyMinDebtPerHarvest_ = _strategyDataStore().strategyMinDebtPerHarvest(address(this), _strategy);
    uint256 strategyMaxDebtPerHarvest_ = _strategyDataStore().strategyMaxDebtPerHarvest(address(this), _strategy);

    if ((strategyDebtLimit_ <= strategyTotalDebt_) || (vaultTotalDebtLimit_ <= vaultTotalDebt_)) {
      return 0;
    }

    uint256 available_ = strategyDebtLimit_.sub(strategyTotalDebt_);
    available_ = Math.min(available_, vaultTotalDebtLimit_.sub(vaultTotalDebt_));
    available_ = Math.min(available_, token.balanceOf(address(this)));

    if (available_ < strategyMinDebtPerHarvest_) {
      return 0;
    } else {
      return Math.min(available_, strategyMaxDebtPerHarvest_);
    }
  }

  function _expectedReturn(address _strategy) internal view returns (uint256) {
    _validateStrategy(_strategy);
    uint256 strategyLastReport_ = strategies[_strategy].lastReport;
    // solhint-disable-next-line not-rely-on-time
    uint256 sinceLastHarvest_ = block.timestamp.sub(strategyLastReport_);
    uint256 totalHarvestTime_ = strategyLastReport_.sub(strategies[_strategy].activation);

    // NOTE: If either `sinceLastHarvest_` or `totalHarvestTime_` is 0, we can short-circuit to `0`
    if ((sinceLastHarvest_ > 0) && (totalHarvestTime_ > 0) && (IStrategy(_strategy).isActive())) {
      // # NOTE: Unlikely to throw unless strategy accumalates >1e68 returns
      // # NOTE: Calculate average over period of time where harvests have occured in the past
      return strategies[_strategy].totalGain.mul(sinceLastHarvest_).div(totalHarvestTime_);
    } else {
      return 0;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./AllowListAccessControl.sol";
import "../vaults/roles/Governable.sol";

// this interface will allow us to implement different types of access policies for Vaults.
// e.g. allowedList/blockedlist based, NFT based etc. Then a vault can reuse these to control access to them.

abstract contract AbstractAccessControlManager {
  /// @notice access policies set on the vault

  event AccessControlPolicyAdded(address _policy);
  event AccessControlPolicyRemoved(address _policy);
}

// This implementation will allow us to set an allowed list of user addresses
contract AccessControlManager is AbstractAccessControlManager {
  // Add the library methods
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet internal accessControlPolicies;

  constructor(address[] memory _accessControlPolicies) {
    _addAccessControlPolicys(_accessControlPolicies);
  }

  // Had to use memory here instead of calldata as the function is
  // used in the constructor
  function _addAccessControlPolicys(address[] memory _policies) internal {
    for (uint256 i = 0; i < _policies.length; i++) {
      if (_policies[i] != address(0)) {
        bool added = accessControlPolicies.add(_policies[i]);
        if (added) {
          emit AccessControlPolicyAdded(_policies[i]);
        }
      }
    }
  }

  function _removeAccessControlPolicys(address[] calldata _policies) internal {
    for (uint256 i = 0; i < _policies.length; i++) {
      if (_policies[i] != address(0)) {
        bool removed = accessControlPolicies.remove(_policies[i]);
        if (removed) {
          emit AccessControlPolicyRemoved(_policies[i]);
        }
      }
    }
  }

  function hasAccess(address _user, address _vault) external view returns (bool) {
    return _hasAccess(_user, _vault);
  }

  function _hasAccess(address _user, address _vault) internal view returns (bool) {
    require(_vault != address(0), "invalid vault address");
    require(_user != address(0), "invalid user address");
    // if no policies set, open by default
    if (accessControlPolicies.length() == 0) {
      return true;
    }
    bool userHasAccess = false;
    for (uint256 i = 0; i < accessControlPolicies.length(); i++) {
      if (IAccessControl(accessControlPolicies.at(i)).hasAccess(_user, _vault)) {
        userHasAccess = true;
        break;
      }
    }
    return userHasAccess;
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
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IVaultStrategyDataStore.sol";
import "./VaultMetaDataStore.sol";

// the Vault itself also represents an ERC20 token, which means it also inherits all methods that are available on the ERC20 interface.
// This token is the shares that the users will get when they deposit money into the Vault
interface IBaseVault is IERC20, IERC20Permit {
  function addStrategy(address _strategy) external returns (bool);

  function migrateStrategy(address _oldVersion, address _newVersion) external returns (bool);

  function revokeStrategy() external;
}

/// @dev This contract is marked abstract to avoid being used directly.
abstract contract BaseVault is IBaseVault, ERC20Permit, Governable, VaultMetaDataStore {
  using SafeERC20 for IERC20;

  struct StrategyInfo {
    uint256 activation;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
  }

  event StrategyAdded(address indexed _strategy);
  event StrategyMigrated(address indexed _oldVersion, address indexed _newVersion);
  event StrategyRevoked(address indexed _strategy);

  // ### Vault base properties
  uint8 internal vaultDecimals = 18;
  /// @notice timestamp for when the vault is deployed
  uint256 public immutable activation;
  mapping(address => StrategyInfo) internal strategies;

  /// @dev BaseVault constructor. The deployer will be set as the governance of the vault by default.
  /// @param _name the name of the vault
  /// @param _symbol the symbol of the vault
  /// @param _governance the address of the manager of the vault
  constructor(
    string memory _name,
    string memory _symbol,
    address _governance,
    address _gatekeeper,
    address _rewards,
    address _strategyDataStoreAddress
  )
    ERC20Permit(_name)
    ERC20(_name, _symbol)
    VaultMetaDataStore(_governance, _gatekeeper, _rewards, _strategyDataStoreAddress)
  {
    // solhint-disable-next-line not-rely-on-time
    activation = block.timestamp;
  }

  /// @notice returns decimals value of the vault
  function decimals() public view override returns (uint8) {
    return vaultDecimals;
  }

  /// @notice Init a new strategy. This should only be called by the {VaultStrategyDataStore} and should not be invoked manually.
  ///   Use {VaultStrategyDataStore.addStrategy} to manually add a strategy to a Vault.
  /// @dev This will be called by the {VaultStrategyDataStore} when a strategy is added to a given Vault.
  function addStrategy(address _strategy) external returns (bool) {
    _onlyNotEmergencyShutdown();
    _onlyStrategyDataStore();
    return _addStrategy(_strategy);
  }

  /// @notice Migrate a new strategy. This should only be called by the {VaultStrategyDataStore} and should not be invoked manually.
  ///   Use {VaultStrategyDataStore.migrateStrategy} to manually migrate a strategy for a Vault.
  /// @dev This will called be the {VaultStrategyDataStore} when a strategy is migrated.
  ///  This will then call the strategy to migrate (as the strategy only allows the vault to call the migrate function).
  function migrateStrategy(address _oldVersion, address _newVersion) external returns (bool) {
    _onlyStrategyDataStore();
    return _migrateStrategy(_oldVersion, _newVersion);
  }

  /// @notice called by the strategy to revoke itself. Should not be called by any other means.
  ///  Use {VaultStrategyDataStore.revokeStrategy} to revoke a strategy manaully.
  /// @dev The strategy could talk to the {VaultStrategyDataStore} directly when revoking itself.
  ///  However, that means we will need to change the interfaces to Strategies and make them incompatible with Yearn's strategies.
  ///  To avoid that, the strategies will continue talking to the Vault and the Vault will then let the {VaultStrategyDataStore} know.
  function revokeStrategy() external {
    require(strategies[_msgSender()].activation > 0, "not authorised");
    _strategyDataStore().revokeStrategyByStrategy(_msgSender());
    emit StrategyRevoked(_msgSender());
  }

  function _strategyDataStore() internal view returns (IVaultStrategyDataStore) {
    return IVaultStrategyDataStore(strategyDataStore);
  }

  function _onlyStrategyDataStore() internal view {
    require(_msgSender() == strategyDataStore, "only strategy store");
  }

  /// @dev ensure the vault is not in emergency shutdown mode
  function _onlyNotEmergencyShutdown() internal view {
    require(emergencyShutdown == false, "emergency shutdown");
  }

  function _validateStrategy(address _strategy) internal view {
    require(strategies[_strategy].activation > 0, "invalid strategy");
  }

  function _addStrategy(address _strategy) internal returns (bool) {
    /* solhint-disable not-rely-on-time */
    strategies[_strategy] = StrategyInfo({
      activation: block.timestamp,
      lastReport: block.timestamp,
      totalDebt: 0,
      totalGain: 0,
      totalLoss: 0
    });
    emit StrategyAdded(_strategy);
    return true;
    /* solhint-enable */
  }

  function _migrateStrategy(address _oldVersion, address _newVersion) internal returns (bool) {
    StrategyInfo memory info = strategies[_oldVersion];
    strategies[_oldVersion].totalDebt = 0;
    strategies[_newVersion] = StrategyInfo({
      activation: info.activation,
      lastReport: info.lastReport,
      totalDebt: info.lastReport,
      totalGain: 0,
      totalLoss: 0
    });
    IStrategy(_oldVersion).migrate(_newVersion);
    emit StrategyMigrated(_oldVersion, _newVersion);
    return true;
  }

  function _sweep(
    address _token,
    uint256 _amount,
    address _to
  ) internal {
    IERC20 token_ = IERC20(_token);
    if (_amount == type(uint256).max) {
      _amount = token_.balanceOf(address(this));
    }
    token_.safeTransfer(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IVaultStrategyDataStore {
  function strategyPerformanceFee(address _vault, address _strategy) external view returns (uint256);

  function strategyActivation(address _vault, address _strategy) external view returns (uint256);

  function strategyDebtRatio(address _vault, address _strategy) external view returns (uint256);

  function strategyMinDebtPerHarvest(address _vault, address _strategy) external view returns (uint256);

  function strategyMaxDebtPerHarvest(address _vault, address _strategy) external view returns (uint256);

  function vaultTotalDebtRatio(address _vault) external view returns (uint256);

  function withdrawQueue(address _vault) external view returns (address[] memory);

  function revokeStrategyByStrategy(address _strategy) external;

  function setVaultManager(address _vault, address _manager) external;

  function setMaxTotalDebtRatio(address _vault, uint256 _maxTotalDebtRatio) external;

  function addStrategy(
    address _vault,
    address _strategy,
    uint256 _debtRatio,
    uint256 _minDebtPerHarvest,
    uint256 _maxDebtPerHarvest,
    uint256 _performanceFee
  ) external;

  function updateStrategyPerformanceFee(
    address _vault,
    address _strategy,
    uint256 _performanceFee
  ) external;

  function updateStrategyDebtRatio(
    address _vault,
    address _strategy,
    uint256 _debtRatio
  ) external;

  function updateStrategyMinDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _minDebtPerHarvest
  ) external;

  function updateStrategyMaxDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _maxDebtPerHarvest
  ) external;

  function migrateStrategy(
    address _vault,
    address _oldStrategy,
    address _newStrategy
  ) external;

  function revokeStrategy(address _vault, address _strategy) external;

  function setWithdrawQueue(address _vault, address[] calldata _queue) external;

  function addStrategyToWithdrawQueue(address _vault, address _strategy) external;

  function removeStrategyFromWithdrawQueue(address _vault, address _strategy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./roles/Governable.sol";
import "./roles/Gatekeeperable.sol";

contract VaultMetaDataStore is Context, Governable, Gatekeeperable {
  using SafeMath for uint256;

  event EmergencyShutdown(bool _active);
  event HealthCheckUpdated(address indexed _healthCheck);
  event RewardsUpdated(address indexed _rewards);
  event ManagementFeeUpdated(uint256 _managementFee);
  event StrategyDataStoreUpdated(address indexed _strategyDataStore);
  event DepositLimitUpdated(uint256 _limit);
  event LockedProfitDegradationUpdated(uint256 _degradation);

  /// @notice The maximum basis points. 1 basis point is 0.01% and 100% is 10000 basis points
  uint256 internal constant MAX_BASIS_POINTS = 10_000;
  uint256 internal constant DEGRADATION_COEFFICIENT = 10**18;
  uint256 public managementFee;
  /// @notice degradation for locked profit per second
  /// @dev the value is based on 6-hour degradation period (1/(60*60*6) = 0.000046)
  ///   NOTE: This is being deprecated by Yearn. See https://github.com/yearn/yearn-vaults/pull/471
  uint256 public lockedProfitDegradation = DEGRADATION_COEFFICIENT.mul(46).div(10**6);
  uint256 public depositLimit = type(uint256).max;
  address public rewards;
  address public healthCheck;
  address public strategyDataStore;
  bool public emergencyShutdown;

  constructor(
    address _governanace,
    address _gatekeeper,
    address _rewards,
    address _strategyDataStore
  ) Governable(_governanace) Gatekeeperable(_gatekeeper) {
    _updateRewards(_rewards);
    _updateStrategyDataStore(_strategyDataStore);
  }

  /// @notice set the wallet address to send the collected fees to. Only can be called by the governance.
  /// @param _rewards the new wallet address to send the fees to.
  function setRewards(address _rewards) external onlyGovernance {
    require(_rewards != address(0), "rewards address is not valid");
    _updateRewards(_rewards);
  }

  /// @notice set the management fee in basis points. 1 basis point is 0.01% and 100% is 10000 basis points.
  function setManagementFee(uint256 _managementFee) external onlyGovernance {
    require(_managementFee < MAX_BASIS_POINTS, "invalid management fee");
    _updateManagementFee(_managementFee);
  }

  function setGatekeeper(address _gatekeeper) external onlyGovernance {
    require(_gatekeeper != address(0), "invalid gatekeeper");
    _updateGatekeeper(_gatekeeper);
  }

  function setStrategyDataStore(address _strategyDataStoreContract) external onlyGovernance {
    require(_strategyDataStoreContract != address(0), "invalid strategy manager");
    _updateStrategyDataStore(_strategyDataStoreContract);
  }

  function setHealthCheck(address _healthCheck) external {
    _onlyGovernanceOrGatekeeper();
    _updateHealthCheck(_healthCheck);
  }

  /// @notice Activates or deactivates Vault mode where all Strategies go into full withdrawal.
  /// During Emergency Shutdown:
  /// 1. No Users may deposit into the Vault (but may withdraw as usual.)
  /// 2. Governance may not add new Strategies.
  /// 3. Each Strategy must pay back their debt as quickly as reasonable to minimally affect their position.
  /// 4. Only Governance may undo Emergency Shutdown.
  ///
  /// See contract level note for further details.
  ///
  /// This may only be called by governance or the guardian.
  /// @param _active If true, the Vault goes into Emergency Shutdown. If false, the Vault goes back into Normal Operation.
  function setVaultEmergencyShutdown(bool _active) external {
    if (_active) {
      _onlyGovernanceOrGatekeeper();
    } else {
      _onlyGovernance();
    }
    if (emergencyShutdown != _active) {
      emergencyShutdown = _active;
      emit EmergencyShutdown(_active);
    }
  }

  /// @notice Changes the locked profit degradation.
  /// @param _degradation The rate of degradation in percent per second scaled to 1e18.
  function setLockedProfileDegradation(uint256 _degradation) external {
    _onlyGovernance();
    require(_degradation <= DEGRADATION_COEFFICIENT, "degradation value is too large");
    if (lockedProfitDegradation != _degradation) {
      lockedProfitDegradation = _degradation;
      emit LockedProfitDegradationUpdated(_degradation);
    }
  }

  function setDepositLimit(uint256 _limit) external {
    _onlyGovernanceOrGatekeeper();
    _updateDepositLimit(_limit);
  }

  function _onlyGovernanceOrGatekeeper() internal view {
    require((_msgSender() == governance) || (gatekeeper != address(0) && gatekeeper == _msgSender()), "not authorised");
  }

  function _updateRewards(address _rewards) internal {
    if (rewards != _rewards) {
      rewards = _rewards;
      emit RewardsUpdated(_rewards);
    }
  }

  function _updateManagementFee(uint256 _managementFee) internal {
    if (managementFee != _managementFee) {
      managementFee = _managementFee;
      emit ManagementFeeUpdated(_managementFee);
    }
  }

  function _updateHealthCheck(address _healthCheck) internal {
    if (healthCheck != _healthCheck) {
      healthCheck = _healthCheck;
      emit HealthCheckUpdated(_healthCheck);
    }
  }

  function _updateStrategyDataStore(address _strategyDataStore) internal {
    if (_strategyDataStore != address(0) && strategyDataStore != _strategyDataStore) {
      strategyDataStore = _strategyDataStore;
      emit StrategyDataStoreUpdated(_strategyDataStore);
    }
  }

  function _updateDepositLimit(uint256 _depositLimit) internal {
    if (depositLimit != _depositLimit) {
      depositLimit = _depositLimit;
      emit DepositLimitUpdated(_depositLimit);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

interface IGovernable {
  function proposeGovernance(address _pendingGovernance) external;

  function acceptGovernance() external;
}

/// @dev Add a `governance` and a `pendingGovernance` role to the contract, and implements a 2-phased nominatiom process to change the governance.
///   Also provides a modifier to allow controlling access to functions of the contract.
contract Governable is IGovernable, Context {
  event GovenanceUpdated(address _govenance);
  event GovenanceProposed(address _pendingGovenance);

  /// @notice the address of the current governance
  address public governance;
  /// @notice the address of the pending governance
  address public pendingGovernance;

  /// @dev ensure msg.send is the governanace
  modifier onlyGovernance() {
    require(_msgSender() == governance, "governance only");
    _;
  }

  /// @dev ensure msg.send is the pendingGovernance
  modifier onlyPendingGovernance() {
    require(_msgSender() == pendingGovernance, "pending governance only");
    _;
  }

  /// @dev the deployer of the contract will be set as the initial governance
  constructor(address _governance) {
    require(_msgSender() != _governance, "invalid address");
    _updateGovernance(_governance);
  }

  ///@notice propose a new governance of the vault. Only can be called by the existing governance.
  ///@param _pendingGovernance the address of the pending governance
  function proposeGovernance(address _pendingGovernance) external onlyGovernance {
    require(_pendingGovernance != address(0), "invalid address");
    require(_pendingGovernance != governance, "already the governance");
    pendingGovernance = _pendingGovernance;
    emit GovenanceProposed(_pendingGovernance);
  }

  ///@notice accept the proposal to be the governance of the vault. Only can be called by the pending governance.
  function acceptGovernance() external onlyPendingGovernance {
    _updateGovernance(pendingGovernance);
  }

  function _updateGovernance(address _pendingGovernance) internal {
    governance = _pendingGovernance;
    emit GovenanceUpdated(governance);
  }

  /// @dev provides an internal function to allow reduce the contract size
  function _onlyGovernance() internal view {
    require(_msgSender() == governance, "governance only");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

/// @dev Add the `Gatekeeper` role.
///   Gatekeepers will help ensure the security of the vaults. They can set vault limits, pause/unpause deposits or withdraws.
///   For vaults that defined restricted access, they will be able to control the access to these vaults as well.
///   This contract also provides a `onlyGatekeeper` modifier to allow controlling access to functions of the contract.
contract Gatekeeperable is Context {
  event GatekeeperUpdated(address _guardian);

  /// @notice the address of the guardian for the vault
  address public gatekeeper;

  // /// @dev make sure msg.sender is the guardian or the governance
  // modifier onlyGovernanceOrGuardian() {
  //   require((_msgSender() == governance) || (_msgSender() == guardian), "governance or guardian only");
  //   _;
  // }

  /// @dev set the initial value for the gatekeeper.
  /// @param _gatekeeper the default address of the guardian
  constructor(address _gatekeeper) {
    require(_msgSender() != _gatekeeper, "invalid address");
    _updateGatekeeper(_gatekeeper);
  }

  ///@dev this can be used internally to update the gatekeep. If you want to expose it, create an external function in the implementation contract and call this.
  function _updateGatekeeper(address _gatekeeper) internal {
    require(_gatekeeper != address(0), "management address is not valid");
    require(_gatekeeper != gatekeeper, "already the guardian");
    gatekeeper = _gatekeeper;
    emit GatekeeperUpdated(_gatekeeper);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAccessControl.sol";
import "../vaults/roles/Governable.sol";
import "./PerVaultGatekeeper.sol";

contract AllowlistAccessControl is IAccessControl, PerVaultGatekeeper {
  mapping(address => bool) public globalAccessMap;
  mapping(address => mapping(address => bool)) public vaultAccessMap;

  event GlobalAccessGranted(address indexed _user);
  event GlobalAccessRemoved(address indexed _user);
  event VaultAccessGranted(address indexed _user, address indexed _vault);
  event VaultAccessRemoved(address indexed _user, address indexed _vault);

  // solhint-disable-next-line no-empty-blocks
  constructor(address _governance) PerVaultGatekeeper(_governance) {}

  function allowGlobalAccess(address[] calldata _users) external onlyGovernance {
    _updateGlobalAccess(_users, true);
  }

  function removeGlobalAccess(address[] calldata _users) external onlyGovernance {
    _updateGlobalAccess(_users, false);
  }

  function allowVaultAccess(address[] calldata _users, address _vault) external {
    _onlyGovernanceOrGatekeeper(_vault);
    _updateAllowVaultAccess(_users, _vault, true);
  }

  function removeVaultAccess(address[] calldata _users, address _vault) external {
    _onlyGovernanceOrGatekeeper(_vault);
    _updateAllowVaultAccess(_users, _vault, false);
  }

  function _hasAccess(address _user, address _vault) internal view returns (bool) {
    require(_user != address(0), "invalid user address");
    require(_vault != address(0), "invalid vault address");
    return globalAccessMap[_user] || vaultAccessMap[_user][_vault];
  }

  function hasAccess(address _user, address _vault) external view returns (bool) {
    return _hasAccess(_user, _vault);
  }

  /// @dev updates the users global access
  function _updateGlobalAccess(address[] calldata _users, bool _permission) internal {
    for (uint256 i = 0; i < _users.length; i++) {
      require(_users[i] != address(0), "invalid address");
      /// @dev only update mappign if permissions are changed
      if (globalAccessMap[_users[i]] != _permission) {
        globalAccessMap[_users[i]] = _permission;
        if (_permission) {
          emit GlobalAccessGranted(_users[i]);
        } else {
          emit GlobalAccessRemoved(_users[i]);
        }
      }
    }
  }

  function _updateAllowVaultAccess(
    address[] calldata _users,
    address _vault,
    bool _permission
  ) internal {
    require(_vault != address(0), "invalid vault address");
    for (uint256 i = 0; i < _users.length; i++) {
      require(_users[i] != address(0), "invalid user address");
      if (vaultAccessMap[_users[i]][_vault] != _permission) {
        vaultAccessMap[_users[i]][_vault] = _permission;
        if (_permission) {
          emit VaultAccessGranted(_users[i], _vault);
        } else {
          emit VaultAccessRemoved(_users[i], _vault);
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IAccessControl {
  function hasAccess(address _user, address _vault) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import "../vaults/roles/Governable.sol";

contract PerVaultGatekeeper is Governable {
  event GatekeeperUpdated(address indexed _gatekeeper, address indexed _vault);

  mapping(address => address) public vaultGatekeepers;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _governance) Governable(_governance) {}

  function setVaultGatekeeper(address _vault, address _gatekeeper) external onlyGovernance {
    require(_vault != address(0) && _gatekeeper != address(0), "invalid address");
    vaultGatekeepers[_vault] = _gatekeeper;
    emit GatekeeperUpdated(_gatekeeper, _vault);
  }

  function _onlyGovernanceOrGatekeeper(address _vault) internal view {
    require(_msgSender() == governance || _msgSender() == vaultGatekeepers[_vault], "not authorised");
  }
}