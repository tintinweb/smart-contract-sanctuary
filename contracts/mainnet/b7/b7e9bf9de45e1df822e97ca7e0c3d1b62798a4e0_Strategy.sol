// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.6.0;

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
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;









struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtLimit;
    uint256 rateLimit;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalReturns;
}

interface VaultAPI is IERC20 {
    function apiVersion() external view returns (string memory);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    /*
     * View how much the Vault would increase this strategy's borrow limit,
     * based on it's present performance (since its last report). Can be used to
     * determine expectedReturn in your strategy.
     */
    function creditAvailable() external view returns (uint256);

    /*
     * View how much the Vault would like to pull back from the Strategy,
     * based on it's present performance (since its last report). Can be used to
     * determine expectedReturn in your strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /*
     * View how much the Vault expect this strategy to return at the current block,
     * based on it's present performance (since its last report). Can be used to
     * determine expectedReturn in your strategy.
     */
    function expectedReturn() external view returns (uint256);

    /*
     * This is the main contact point where the strategy interacts with the Vault.
     * It is critical that this call is handled as intended by the Strategy.
     * Therefore, this function will be called by BaseStrategy to make sure the
     * integration is correct.
     */
    function report(uint256 _harvest) external returns (uint256);

    /*
     * This function is used in the scenario where there is a newer strategy that
     * would hold the same positions as this one, and those positions are easily
     * transferrable to the newer strategy. These positions must be able to be
     * transferred at the moment this call is made, if any prep is required to
     * execute a full transfer in one transaction, that must be accounted for
     * separately from this call.
     */
    function migrateStrategy(address _newStrategy) external;

    /*
     * This function should only be used in the scenario where the strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits it's position as fast as possible, such as a sudden change in market
     * conditions leading to losses, or an imminent failure in an external
     * dependency.
     */
    function revokeStrategy() external;

    /*
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     *
     */
    function governance() external view returns (address);
}

/*
 * This interface is here for the keeper bot to use
 */
interface StrategyAPI {
    function apiVersion() external pure returns (string memory);

    function name() external pure returns (string memory);

    function vault() external view returns (address);

    function keeper() external view returns (address);

    function strategist() external view returns (address);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(uint256 profit);
}

/*
 * BaseStrategy implements all of the required functionality to interoperate closely
 * with the core protocol. This contract should be inherited and the abstract methods
 * implemented to adapt the strategy to the particular needs it has to create a return.
 */

abstract contract BaseStrategy {
    using SafeMath for uint256;

    // Version of this contract's StrategyAPI (must match Vault)
    function apiVersion() public pure returns (string memory) {
        return "0.1.3";
    }

    // Name of this contract's Strategy (Must override!)
    // NOTE: You can use this field to manage the "version" of this strategy
    //       e.g. `StrategySomethingOrOtherV1`. It's up to you!
    function name() external virtual pure returns (string memory);

    VaultAPI public vault;
    address public strategist;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(uint256 profit);

    // The minimum number of blocks between harvest calls
    // NOTE: Override this value with your own, or set dynamically below
    uint256 public minReportDelay = 6300; // ~ once a day

    // The minimum multiple that `callCost` must be above the credit/profit to be "justifiable"
    // NOTE: Override this value with your own, or set dynamically below
    uint256 public profitFactor = 100;

    // Use this to adjust the threshold at which running a debt causes a harvest trigger
    uint256 public debtThreshold = 0;

    // Adjust this using `setReserve(...)` to keep some of the position in reserve in the strategy,
    // to accomodate larger variations needed to sustain the strategy's core positon(s)
    uint256 private reserve = 0;

    function getReserve() internal view returns (uint256) {
        return reserve;
    }

    function setReserve(uint256 _reserve) internal {
        if (_reserve != reserve) reserve = _reserve;
    }

    bool public emergencyExit;

    constructor(address _vault) public {
        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.approve(_vault, uint256(-1)); // Give Vault unlimited access (might save gas)
        strategist = msg.sender;
        keeper = msg.sender;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        strategist = _strategist;
    }

    function setKeeper(address _keeper) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        keeper = _keeper;
    }

    function setMinReportDelay(uint256 _delay) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        minReportDelay = _delay;
    }

    function setProfitFactor(uint256 _profitFactor) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        profitFactor = _profitFactor;
    }

    function setDebtThreshold(uint256 _debtThreshold) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        debtThreshold = _debtThreshold;
    }

    /*
     * Resolve governance address from Vault contract, used to make
     * assertions on protected functions in the Strategy
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    /*
     * Provide an accurate estimate for the total amount of assets (principle + return)
     * that this strategy is currently managing, denominated in terms of `want` tokens.
     * This total should be "realizable" e.g. the total value that could *actually* be
     * obtained from this strategy if it were to divest it's entire position based on
     * current on-chain conditions.
     *
     * NOTE: care must be taken in using this function, since it relies on external
     *       systems, which could be manipulated by the attacker to give an inflated
     *       (or reduced) value produced by this function, based on current on-chain
     *       conditions (e.g. this function is possible to influence through flashloan
     *       attacks, oracle manipulations, or other DeFi attack mechanisms).
     *
     * NOTE: It is up to governance to use this function to correctly order this strategy
     *       relative to its peers in the withdrawal queue to minimize losses for the Vault
     *       based on sudden withdrawals. This value should be higher than the total debt of
     *       the strategy and higher than it's expected value to be "safe".
     */
    function estimatedTotalAssets() public virtual view returns (uint256);

    /*
     * Perform any strategy unwinding or other calls necessary to capture
     * the "free return" this strategy has generated since the last time it's
     * core position(s) were adusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and should
     * be optimized to minimize losses as much as possible. It is okay to report
     * "no returns", however this will affect the credit limit extended to the
     * strategy and reduce it's overall position if lower than expected returns
     * are sustained for long periods of time.
     */
    function prepareReturn(uint256 _debtOutstanding) internal virtual returns (uint256 _profit);

    /*
     * Perform any adjustments to the core position(s) of this strategy given
     * what change the Vault made in the "investable capital" available to the
     * strategy. Note that all "free capital" in the strategy after the report
     * was made is available for reinvestment. Also note that this number could
     * be 0, and you should handle that scenario accordingly.
     */
    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    /*
     * Make as much capital as possible "free" for the Vault to take. Some slippage
     * is allowed, since when this method is called the strategist is no longer receiving
     * their performance fee. The goal is for the strategy to divest as quickly as possible
     * while not suffering exorbitant losses. This function is used during emergency exit
     * instead of `prepareReturn()`
     */
    function exitPosition() internal virtual;

    /*
     * Vault calls this function after shares are created during `Vault.report()`.
     * You can customize this function to any share distribution mechanism you want.
     */
    function distributeRewards(uint256 _shares) external virtual {
        // Send 100% of newly-minted shares to the strategist.
        vault.transfer(strategist, _shares);
    }

    /*
     * Provide a signal to the keeper that `tend()` should be called. The keeper will provide
     * the estimated gas cost that they would pay to call `tend()`, and this function should
     * use that estimate to make a determination if calling it is "worth it" for the keeper.
     * This is not the only consideration into issuing this trigger, for example if the position
     * would be negatively affected if `tend()` is not called shortly, then this can return `true`
     * even if the keeper might be "at a loss" (keepers are always reimbursed by yEarn)
     *
     * NOTE: `callCost` must be priced in terms of `want`
     *
     * NOTE: this call and `harvestTrigger` should never return `true` at the same time.
     */
    function tendTrigger(uint256 callCost) public virtual view returns (bool) {
        // We usually don't need tend, but if there are positions that need active maintainence,
        // overriding this function is how you would signal for that
        return false;
    }

    function tend() external {
        if (keeper != address(0)) {
            require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance(), "!authorized");
        }

        // Don't take profits with this call, but adjust for better gains
        adjustPosition(vault.debtOutstanding());
    }

    /*
     * Provide a signal to the keeper that `harvest()` should be called. The keeper will provide
     * the estimated gas cost that they would pay to call `harvest()`, and this function should
     * use that estimate to make a determination if calling it is "worth it" for the keeper.
     * This is not the only consideration into issuing this trigger, for example if the position
     * would be negatively affected if `harvest()` is not called shortly, then this can return `true`
     * even if the keeper might be "at a loss" (keepers are always reimbursed by yEarn)
     *
     * NOTE: `callCost` must be priced in terms of `want`
     *
     * NOTE: this call and `tendTrigger` should never return `true` at the same time.
     */
    function harvestTrigger(uint256 callCost) public virtual view returns (bool) {
        StrategyParams memory params = vault.strategies(address(this));

        // Should not trigger if strategy is not activated
        if (params.activation == 0) return false;

        // Should trigger if hadn't been called in a while
        if (block.number.sub(params.lastReport) >= minReportDelay) return true;

        // If some amount is owed, pay it back
        // NOTE: Since debt is adjusted in step-wise fashion, it is appropiate to always trigger here,
        //       because the resulting change should be large (might not always be the case)
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > 0) return true;

        // Check for profits and losses
        uint256 total = estimatedTotalAssets();
        // Trigger if we have a loss to report
        if (total.add(debtThreshold) < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

        // Otherwise, only trigger if it "makes sense" economically (gas cost is <N% of value moved)
        uint256 credit = vault.creditAvailable();
        return (profitFactor * callCost < credit.add(profit));
    }

    function harvest() external {
        if (keeper != address(0)) {
            require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance(), "!authorized");
        }

        uint256 profit = 0;
        if (emergencyExit) {
            exitPosition(); // Free up as much capital as possible
            // NOTE: Don't take performance fee in this scenario
        } else {
            profit = prepareReturn(vault.debtOutstanding()); // Free up returns for Vault to pull
        }

        if (reserve > want.balanceOf(address(this))) reserve = want.balanceOf(address(this));

        // Allow Vault to take up to the "harvested" balance of this contract, which is
        // the amount it has earned since the last time it reported to the Vault
        uint256 outstanding = vault.report(want.balanceOf(address(this)).sub(reserve));

        // Check if free returns are left, and re-invest them
        adjustPosition(outstanding);

        emit Harvested(profit);
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amountNeeded`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _amountFreed);

    function withdraw(uint256 _amountNeeded) external {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amount`
        uint256 amountFreed = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.transfer(msg.sender, amountFreed);
        // Adjust reserve to what we have after the freed amount is sent to the Vault
        reserve = want.balanceOf(address(this));
    }

    /*
     * Do anything necesseary to prepare this strategy for migration, such
     * as transfering any reserve or LP tokens, CDPs, or other tokens or stores of value.
     */
    function prepareMigration(address _newStrategy) internal virtual;

    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault) || msg.sender == governance());
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.transfer(_newStrategy, want.balanceOf(address(this)));
    }

    function setEmergencyExit() external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        emergencyExit = true;
        exitPosition();
        vault.revokeStrategy();
        if (reserve > want.balanceOf(address(this))) reserve = want.balanceOf(address(this));
    }

    // Override this to add all tokens/tokenized positions this contract manages
    // on a *persistant* basis (e.g. not just for swapping back to want ephemerally)
    // NOTE: Do *not* include `want`, already included in `sweep` below
    //
    // Example:
    //
    //    function protectedTokens() internal override view returns (address[] memory) {
    //      address[] memory protected = new address[](3);
    //      protected[0] = tokenA;
    //      protected[1] = tokenB;
    //      protected[2] = tokenC;
    //      return protected;
    //    }
    function protectedTokens() internal virtual view returns (address[] memory);

    function sweep(address _token) external {
        require(msg.sender == governance(), "!authorized");
        require(_token != address(want), "!want");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).transfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}
pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


pragma solidity ^0.6.0;

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
pragma solidity 0.6.12;
abstract contract IGenericLender {
    

    VaultAPI public vault;
    BaseStrategy public strategy;
    IERC20 public want;
    string public lenderName;

    constructor(address _strategy, string memory name) public {
        strategy = BaseStrategy(_strategy);
        vault = VaultAPI(strategy.vault());
        want = IERC20(vault.token());
        lenderName = name;
        
        want.approve(_strategy, uint256(-1));

    }

    function nav() external virtual view  returns (uint256);
    function apr() external virtual view  returns (uint256);
    function weightedApr() external virtual view  returns (uint256);
    function withdraw(uint256 amount) external virtual  returns (uint256);
    function emergencyWithdraw(uint256 amount) external virtual;
    function deposit() external virtual;
    function withdrawAll() external virtual returns (bool);
    function enabled() external virtual view returns (bool);
    function hasAssets() external virtual view returns (bool);
    function aprAfterDeposit(uint256 amount) external virtual view returns (uint256);


    function sweep(address _token) external management {
        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).transfer(vault.governance(), IERC20(_token).balanceOf(address(this)));
    }
    function protectedTokens() internal virtual view returns (address[] memory);

    

    //make sure to use
    modifier management(){
        require(msg.sender == address(strategy) ||
        msg.sender == vault.governance() || msg.sender == strategy.strategist(), "!management");
        _;
    }
}




/********************
 *   A lender optimisation strategy for any erc20 asset
 *   Made by SamPriestley.com
 *   https://github.com/Grandthrax/yearnv2/blob/master/contracts/LenderYieldOptimiser.sol
 *
 ********************* */


contract Strategy is BaseStrategy{

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IGenericLender[] public lenders;


    constructor(address _vault) public BaseStrategy(_vault) {
 
        // You can set these parameters on deployment to whatever you want
        minReportDelay = 6300;
        profitFactor = 100;
        debtThreshold = 1 gwei;

        //we do this horrible thing because you can't compare strings in solidity
        require(keccak256(bytes(apiVersion())) == keccak256(bytes(VaultAPI(_vault).apiVersion())), "WRONG VERSION");
    }


    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external override pure returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamYFI"
        return "StrategyLenderYieldOptimiser";
    }

    //management functions
    function addLender(address a) public management{
       IGenericLender n = IGenericLender(a);

        for(uint i = 0; i < lenders.length; i++){
            require(a != address(lenders[i]), "Already Added");
        }
        lenders.push(n);
    }
    function safeRemoveLender(address a) public management{
        _removeLender(a, false);
    }

    function forceRemoveLender(address a) public management{
        _removeLender(a, true);
       
    }
    function _removeLender(address a, bool force) internal {
        for(uint i = 0; i < lenders.length; i++){
            
            if(a == address(lenders[i])){

                bool allWithdrawn = lenders[i].withdrawAll();

                if(!force){
                    require(allWithdrawn, "WITHDRAW FAILED");
                }
                

                //put the last index here
                //remove last index
                if(i != lenders.length){
                    lenders[i] = lenders[lenders.length-1];
                }
                delete lenders[lenders.length-1];

                //if balance to spend
                if(want.balanceOf(address(this)) > 0){
                    adjustPosition(0);
                }
                return;
            }
        }
        require(false, "NOT LENDER");
        

    }

    struct lendStatus{
        string name;
        uint256 assets;
        uint256 rate;
    }
    
    function lendStatuses() public view returns(lendStatus[] memory){
        lendStatus[] memory statuses = new lendStatus[](lenders.length);
         for(uint i = 0; i < lenders.length; i++){
            lendStatus memory s;
            s.name = lenders[i].lenderName();
            s.assets = lenders[i].nav();
            s.rate = lenders[i].apr();
            statuses[i] = s;
        }

        return statuses;
    }


    // lent assets plus loose assets
    function estimatedTotalAssets() public override view returns (uint256) {
        
        uint256 nav = lentTotalAssets();
        nav += want.balanceOf(address(this));

        return nav;
    }

    function numLenders() public view returns (uint256) {
        return lenders.length;

    }

    function estimatedAPR() public view returns (uint256) {
        uint256 weightedAPR = 0;
        
        for(uint i = 0; i < lenders.length; i++){
            weightedAPR += lenders[i].weightedApr();
        }

        uint256 bal = estimatedTotalAssets();

        return weightedAPR.div(bal);
    }
    function _estimateDebtLimitIncrease(uint256 change) internal view returns (uint256){
        uint256 highestAPR = 0;
        uint256 aprChoice = 0;
        uint256 assets = 0;

        for(uint i = 0; i < lenders.length; i++){
            uint256 apr = lenders[i].aprAfterDeposit(change);
            if(apr > highestAPR){
                aprChoice = i;
                highestAPR = apr;
                assets = lenders[i].nav();
            }
        }


        uint256 weightedAPR =highestAPR.mul(assets.add(change));

        for(uint i = 0; i < lenders.length; i++){
            if(i != aprChoice){
                weightedAPR += lenders[i].weightedApr();                   
            }
        }

        uint256 bal = estimatedTotalAssets().add(change);

        return weightedAPR.div(bal);
    }


    //TODO: needs improvement. more complicated than limit increase
    function _estimateDebtLimitDecrease(uint256 change) internal view returns (uint256){
         uint256 lowestApr = uint256(-1);
        uint256 aprChoice = 0;

        for(uint i = 0; i < lenders.length; i++){
            uint256 apr = lenders[i].aprAfterDeposit(change);
            if(apr < lowestApr){
                aprChoice = i;
                lowestApr = apr;
            }
        }


        uint256 weightedAPR =0;

        for(uint i = 0; i < lenders.length; i++){
            if(i != aprChoice){
                weightedAPR += lenders[i].weightedApr();
            }else{
                uint256 asset  = lenders[i].nav();
                if(asset < change){
                    //simplistic. not accurate
                    change = asset;
                }
                weightedAPR += lowestApr.mul(change);
            }
        }
        uint256 bal = estimatedTotalAssets().add(change);
        return weightedAPR.div(bal);
    }

    function estimatedFutureAPR(uint256 newDebtLimit) public view returns (uint256) {

        uint256 oldDebtLimit = vault.strategies(address(this)).totalDebt;
        uint256 change;
        if(oldDebtLimit < newDebtLimit){
            change = newDebtLimit - oldDebtLimit;
            return _estimateDebtLimitIncrease(change);
        }else{
            change = oldDebtLimit - newDebtLimit;
            return _estimateDebtLimitDecrease(change);
        }

       
       
    }

    //cycle all lenders and collect balances
    function lentTotalAssets() public view returns (uint256) {
        uint nav = 0;
        for(uint i = 0; i < lenders.length; i++){
            nav += lenders[i].nav();
        }
        return nav;
     }

    //we need to free up profit plus _debtOutstanding. 
    //If _debtOutstanding is more than we can free we get as much as possible
    function prepareReturn(uint256 _debtOutstanding) internal override returns (uint256 _profit) {
        uint256 lentAssets = lentTotalAssets();

        uint256 looseAssets = want.balanceOf(address(this));

        uint256 total = looseAssets.add(lentAssets);


        if (lentAssets == 0) {
            //no position to harvest or profit to report
            if(_debtOutstanding > looseAssets){
                setReserve(0);
            }else{
                setReserve(looseAssets.sub(_debtOutstanding));
            }
            
            return 0;
        }
        if (getReserve() != 0) {
            //reset reserve so it doesnt interfere anywhere else
            setReserve(0);
        }

        uint256 debt = vault.strategies(address(this)).totalDebt;

        if(total > debt){
            uint profit = total-debt;
            uint amountToFree = profit.add(_debtOutstanding);

            //we need to add outstanding to our profit
            if(looseAssets >= amountToFree){
                setReserve(looseAssets - amountToFree);
            }else{
                //change profit to what we can withdraw
                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));

                if(newLoose > amountToFree){
                    setReserve(newLoose - amountToFree);
                }else{
                    setReserve(0);
                }

            }

            return profit;

        } else {
        
            if(looseAssets <= _debtOutstanding){
                     setReserve(0);
            }else{
                setReserve(looseAssets - _debtOutstanding);
            }

            return 0;
        }
    }

    /*
    * Key logic.
    *   The algorithm moves assets from lowest return to highest
    *   like a very slow idiots bubble sort
    *   we ignore debt outstanding for an easy life
    *
    */
    function adjustPosition(uint256 _debtOutstanding) internal override {

        _debtOutstanding; //ignored
        //emergency exit is dealt with at beginning of harvest
        if (emergencyExit) {
            return;
        }
        //reset reserve and refund some gas
        setReserve(0);

        //all loose assets are to be invested
        uint256 looseAssets = want.balanceOf(address(this));

        // our simple algo
        // get the lowest apr strat
        // cycle through and see who could take its funds plus want for the highest apr
        uint256 lowestApr = uint256(-1);
        uint256 lowest = 0;
        uint256 lowestNav = 0;
        for(uint i = 0; i < lenders.length; i++){
            if(lenders[i].hasAssets()){
                uint256 apr = lenders[i].apr();
                if(apr < lowestApr){
                    lowestApr = apr;
                    lowest = i;
                    lowestNav = lenders[i].nav();
                }
             }
        }

        uint256 toAdd = lowestNav.add(looseAssets);

        uint256 highestApr = 0;
        uint256 highest = 0;

        for(uint i = 0; i < lenders.length; i++){

           
            uint256 apr;
            apr = lenders[i].aprAfterDeposit(looseAssets);
           
            if(apr > highestApr){
                highestApr = apr;
                highest = i;
            }
             
        }

        //if we can improve apr by withdrawing we do so
        uint256 potential = lenders[highest].aprAfterDeposit(toAdd);
        if(potential > lowestApr){
            //apr should go down after deposit so wont be withdrawing from self
            lenders[lowest].withdrawAll();
        }

        want.safeTransfer(address(lenders[highest]), want.balanceOf(address(this)));
        lenders[highest].deposit();

    }

    struct lenderRatio{
        address lender;
        //share x 1000
        uint16 share;
    }

    //share should add up to 1000.
    function manualAllocation(lenderRatio[] memory _newPositions) public management {
        uint256 share = 0;

        for(uint i = 0; i < lenders.length; i++){
            lenders[i].withdrawAll();
        }

        uint256 assets = want.balanceOf(address(this));

        for(uint i = 0; i < _newPositions.length; i++){
            bool found = false;

            //might be annoying and expensive to do this second loop but worth it for safety
            for(uint j = 0; j < lenders.length; j++){
                if(address(lenders[j]) ==_newPositions[j].lender ){
                    found = true;
                }
            }
            require(found, "NOT LENDER");

            share+= _newPositions[i].share;
            uint256 toSend = assets.mul(_newPositions[i].share).div(1000);
            want.safeTransfer(_newPositions[i].lender, toSend);
            IGenericLender(_newPositions[i].lender).deposit();
        }

        require(share == 1000, "SHARE!=1000");

    }


    //cycle through withdrawing from worst rate first
    function _withdrawSome(uint256 _amount) internal returns(uint256 amountWithdrawn) {
     
        //most situations this will only run once. Only big withdrawals will be a gas guzzler
        while(amountWithdrawn < _amount){
            uint256 lowestApr = uint256(-1);
            uint256 lowest = 0;
            for(uint i = 0; i < lenders.length; i++){
                if(lenders[i].hasAssets()){
                    uint256 apr = lenders[i].apr();
                    if(apr < lowestApr){
                        lowestApr = apr;
                        lowest = i;
                    }
                }
                
            }
            if(!lenders[lowest].hasAssets()){
                return amountWithdrawn;
            }
            amountWithdrawn += lenders[lowest].withdraw(_amount);
        }
    }


    function exitPosition() internal override {
        uint balance = lentTotalAssets();
        if(balance > 0){
            _withdrawSome(balance);
        }
        setReserve(0);
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amountNeeded`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed) {
         uint256 _balance = want.balanceOf(address(this));

        if(_balance >= _amountNeeded){
            //if we don't set reserve here withdrawer will be sent our full balance
            setReserve(_balance.sub(_amountNeeded));
            return _amountNeeded;
        }else{
            uint received = _withdrawSome(_amountNeeded - _balance).add(_balance);
            if(received > _amountNeeded){
                return  _amountNeeded;
            }else{
                return received;
            }

        }
    }

    // NOTE: Can override `tendTrigger` and `harvestTrigger` if necessary

    /*
     * Do anything necesseary to prepare this strategy for migration, such
     * as transfering any reserve or LP tokens, CDPs, or other tokens or stores of value.
     */
    function prepareMigration(address _newStrategy) internal override {
        exitPosition();
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    // Override this to add all tokens/tokenized positions this contract manages
    // on a *persistant* basis (e.g. not just for swapping back to want ephemerally)
    // NOTE: Do *not* include `want`, already included in `sweep` below
    //
    // Example:
    //
    //    function protectedTokens() internal override view returns (address[] memory) {
    //      address[] memory protected = new address[](3);
    //      protected[0] = tokenA;
    //      protected[1] = tokenB;
    //      protected[2] = tokenC;
    //      return protected;
    //    }
    function protectedTokens() internal override view returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        return protected;
    }

    modifier management(){
        require(msg.sender == governance() || msg.sender == strategist, "!management");
        _;
    }

}