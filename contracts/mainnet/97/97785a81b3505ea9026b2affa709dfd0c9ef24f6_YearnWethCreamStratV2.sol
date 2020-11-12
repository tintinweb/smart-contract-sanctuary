// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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


// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol


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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol


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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol


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

// File: contracts\strategies\Interfaces\Compound\CTokenI.sol

pragma solidity >=0.5.0;

interface CTokenI{

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function accrualBlockNumber() external view returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function totalBorrows() external view returns (uint);
    function totalSupply() external view returns (uint);

}

// File: contracts\strategies\Interfaces\Compound\CEtherI.sol

pragma solidity >=0.5.16;

interface CEtherI is CTokenI{
    function redeemUnderlying(uint redeemAmount) external returns (uint);
      function redeem(uint redeemTokens) external returns (uint);
    function liquidateBorrow(address borrower, CTokenI cTokenCollateral) external payable;
    function mint() external payable;
}

// File: contracts\strategies\Interfaces\UniswapInterfaces\IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
}

// File: contracts\strategies\Interfaces\Yearn\IController.sol

pragma solidity >=0.6.9;

interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);

    function approveStrategy(address, address) external;

    function setStrategy(address, address) external;

    function strategies(address) external view returns (address);
}

// File: contracts\strategies\BaseStrategy.sol

pragma solidity >=0.6.0 <0.7.0;



struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtLimit;
    uint256 rateLimit;
    uint256 lastSync;
    uint256 totalDebt;
    uint256 totalReturns;
}

interface VaultAPI {
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
    function vault() external view returns (address);

    function keeper() external view returns (address);

    function tendTrigger(uint256 gasCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 gasCost) external view returns (bool);

    function harvest() external;

    event Harvested(uint256 wantEarned, uint256 lifetimeEarned);
}

/*
 * BaseStrategy implements all of the required functionality to interoperate closely
 * with the core protocol. This contract should be inherited and the abstract methods
 * implemented to adapt the strategy to the particular needs it has to create a return.
 */

abstract contract BaseStrategy {
    using SafeMath for uint256;

    // Version of this contract
    function version() external pure returns (string memory) {
        return "0.1.1";
    }

    VaultAPI public vault;
    address public strategist;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(uint256 wantEarned, uint256 lifetimeEarned);

    // Adjust this to keep some of the position in reserve in the strategy,
    // to accomodate larger variations needed to sustain the strategy's core positon(s)
    uint256 public reserve = 0;

    // This gets adjusted every time the Strategy reports to the Vault,
    // and should be used during adjustment of the strategy's positions to "deleverage"
    // in order to pay back the amount the next time it reports.
    //
    // NOTE: Do not edit this variable, for safe usage (only read from it)
    // NOTE: Strategy should not expect to increase it's working capital until this value
    //       is zero.
    uint256 public outstanding = 0;

    bool public emergencyExit;

    constructor(address _vault) public {

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.approve(_vault, uint256(-1)); // Give Vault unlimited access (might save gas)
        strategist = msg.sender;
        keeper = msg.sender;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == strategist || msg.sender == governance(), "!governance");
        strategist = _strategist;
    }

    function setKeeper(address _keeper) external {
        require(msg.sender == strategist || msg.sender == governance(), "!governance");
        keeper = _keeper;
    }

    /*
     * Resolve governance address from Vault contract, used to make
     * assertions on protected functions in the Strategy
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    /*
     * Provide an accurate expected value for the return this strategy
     * would provide to the Vault the next time `report()` is called
     * (since the last time it was called)
     */
    function expectedReturn() public virtual view returns (uint256);

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
     * NOTE: It is up to governance to use this function in order to correctly order
     *       this strategy relative to its peers in order to minimize losses for the
     *       Vault based on sudden withdrawals. This value should be higher than the
     *       total debt of the strategy and higher than it's expected value to be "safe".
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
    function prepareReturn() internal virtual;

    /*
     * Perform any adjustments to the core position(s) of this strategy given
     * what change the Vault made in the "investable capital" available to the
     * strategy. Note that all "free capital" in the strategy after the report
     * was made is available for reinvestment. Also note that this number could
     * be 0, and you should handle that scenario accordingly.
     */
    function adjustPosition() internal virtual;

    /*
     * Make as much capital as possible "free" for the Vault to take. Some slippage
     * is allowed, since when this method is called the strategist is no longer receiving
     * their performance fee. The goal is for the strategy to divest as quickly as possible
     * while not suffering exorbitant losses. This function is used during emergency exit
     * instead of `prepareReturn()`
     */
    function exitPosition() internal virtual;

    /*
     * Provide a signal to the keeper that `tend()` should be called. The keeper will provide
     * the estimated gas cost that they would pay to call `tend()`, and this function should
     * use that estimate to make a determination if calling it is "worth it" for the keeper.
     * This is not the only consideration into issuing this trigger, for example if the position
     * would be negatively affected if `tend()` is not called shortly, then this can return `true`
     * even if the keeper might be "at a loss" (keepers are always reimbursed by yEarn)
     *
     * NOTE: this call and `harvestTrigger` should never return `true` at the same time.
     * NOTE: if `tend()` is never intended to be called, it should always return `false`
     */
    function tendTrigger(uint256 gasCost) public virtual view returns (bool);

    function tend() external {
        if (keeper != address(0)) require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance());
        // NOTE: Don't take profits with this call, but adjust for better gains
        adjustPosition();
    }

    /*
     * Provide a signal to the keeper that `harvest()` should be called. The keeper will provide
     * the estimated gas cost that they would pay to call `harvest()`, and this function should
     * use that estimate to make a determination if calling it is "worth it" for the keeper.
     * This is not the only consideration into issuing this trigger, for example if the position
     * would be negatively affected if `harvest()` is not called shortly, then this can return `true`
     * even if the keeper might be "at a loss" (keepers are always reimbursed by yEarn)
     *
     * NOTE: this call and `tendTrigger` should never return `true` at the same time.
     */
    function harvestTrigger(uint256 gasCost) public virtual view returns (bool);

    function harvest() external {
        if (keeper != address(0)) require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance());

        if (emergencyExit) {
            exitPosition(); // Free up as much capital as possible
            // NOTE: Don't take performance fee in this scenario
        } else {
            prepareReturn(); // Free up returns for Vault to pull
        }

        if (reserve > want.balanceOf(address(this))) reserve = want.balanceOf(address(this));

        // Allow Vault to take up to the "harvested" balance of this contract, which is
        // the amount it has earned since the last time it reported to the Vault
        uint256 wantEarned = want.balanceOf(address(this)).sub(reserve);
        outstanding = vault.report(wantEarned);

        adjustPosition(); // Check if free returns are left, and re-invest them

        emit Harvested(wantEarned, vault.strategies(address(this)).totalReturns);
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amount`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amount) internal virtual;

    function withdraw(uint256 _amount) external {
        require(msg.sender == address(vault), "!vault");
        liquidatePosition(_amount); // Liquidates as much as possible to `want`, up to `_amount`
        want.transfer(msg.sender, want.balanceOf(address(this)).sub(reserve));
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
    }

    function setEmergencyExit() external {
        require(msg.sender == strategist || msg.sender == governance());
        emergencyExit = true;
        exitPosition();
        vault.revokeStrategy();
        if (reserve > want.balanceOf(address(this))) reserve = want.balanceOf(address(this));
        outstanding = vault.report(want.balanceOf(address(this)).sub(reserve));
    }

    // Override this to add all tokens this contract manages on a *persistant* basis
    // (e.g. not just for swapping back to want ephemerally)
    // NOTE: Must inclide `want` token
    function protectedTokens() internal virtual view returns (address[] memory) {
        address[] memory protected = new address[](1);
        protected[0] = address(want);
        return protected;
    }

    function sweep(address _token) external {
        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).transfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}

// File: contracts\strategies\YearnWethCreamStratV2.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT


//cream is fork of compound and has same interface






/********************
 *   An ETH Cream strategy with a liquidity buffer to ensure we don't end up in crisis.
 *   Made by SamPriestley.com
 *   https://github.com/Grandthrax/yearnv2/blob/master/contracts/YearnWethCreamStratV2.sol
 *
 ********************* */

contract YearnWethCreamStratV2 is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    string public constant name = "YearnWethCreamStratV2";

    //Only three tokens we use
    CEtherI public constant crETH = CEtherI(address(0xD06527D5e56A3495252A528C4987003b712860eE));

    IWETH public constant weth = IWETH(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    uint256 public maxReportDelay = 50; //6300 is once a day. lower vaule used for testing

    //Operating variables
    uint256 public liquidityCushion = 3000 ether; // 3000 ether ~ 1m usd

    uint256 public profitFactor = 50; // multiple before triggering harvest
    uint256 public dustThreshold = 0.01 ether; // multiple before triggering harvest


    constructor(address _vault) public BaseStrategy(_vault) {
        //only accept ETH vault
        require(vault.token() == address(weth), "!WETH");
    }

    //to receive eth from weth
    receive() external payable {}

    /*
     * Control Functions
     */
    function setProfitFactor(uint256 _profitFactor) external {
        require(msg.sender == governance() || msg.sender == strategist, "!management"); // dev: not governance or strategist
        profitFactor = _profitFactor;
    }
    function setLiquidityCushion(uint256 _liquidityCushion) external {
        require(msg.sender == governance() || msg.sender == strategist, "!management"); // dev: not governance or strategist
        liquidityCushion = _liquidityCushion;
    }

    /*
     * Base External Facing Functions
     */

    /*
     * Expected return this strategy would provide to the Vault the next time `report()` is called
     *
     * The total assets currently in strategy minus what vault believes we have
     */
    function expectedReturn() public override view returns (uint256) {
        uint256 estimateAssets = estimatedTotalAssets();

        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (debt > estimateAssets) {
            return 0;
        } else {
            return estimateAssets - debt;
        }
    }

    /*
     * Our balance in CrETH plus balance of want
     */
    function estimatedTotalAssets() public override view returns (uint256) {

        uint256 underlying = underlyingBalanceStored();

        return want.balanceOf(address(this)).add(underlying);
    }

    /*
     * Provide a signal to the keeper that `tend()` should be called.
     * (keepers are always reimbursed by yEarn)
     *
     * NOTE: this call and `harvestTrigger` should never return `true` at the same time.
     * If we are in liquidation cushion we move
     */
    function tendTrigger(uint256 gasCost) public override view returns (bool) {
        gasCost; // silence UI warning
        if (harvestTrigger(gasCost)) {
            //harvest takes priority
            return false;
        }
        
        //we want to tend if there is a liquidity crisis
        uint256 cashAvailable = crETH.getCash();        
        
        if(cashAvailable == 0){
            return false;
        }

        uint wethBalance = weth.balanceOf(address(this));

        uint256 toKeep = 0;

        //to keep is the amount we need to hold to make the liqudity cushion full
        if(cashAvailable.add(wethBalance.mul(2)) < liquidityCushion){
            toKeep = liquidityCushion.sub(cashAvailable.add(wethBalance));
        }

        if (toKeep > wethBalance.add(dustThreshold) && cashAvailable <= liquidityCushion && cashAvailable > dustThreshold && underlyingBalanceStored() > dustThreshold) {
            return true;
        }

        // if liquidity crisis is over
        if(wethBalance > 0 && liquidityCushion < cashAvailable){
            if(cashAvailable - liquidityCushion > gasCost.mul(profitFactor) && wethBalance > gasCost.mul(profitFactor)){
                return true;
            }
        }

        return false;
    }

    function underlyingBalanceStored() public view returns (uint256 balance){
        uint256 currentCrETH = crETH.balanceOf(address(this));
        if(currentCrETH == 0){
            balance = 0;
        }else{
            balance = currentCrETH.mul(crETH.exchangeRateStored()).div(1e18);
        }
    }

    /*
     * Provide a signal to the keeper that `harvest()` should be called.
     * gasCost is expected_gas_use * gas_price
     * (keepers are always reimbursed by yEarn)
     *
     * NOTE: this call and `tendTrigger` should never return `true` at the same time.
     */
    function harvestTrigger(uint256 gasCost) public override view returns (bool) {
         StrategyParams memory params = vault.strategies(address(this));

        // Should not trigger if strategy is not activated
        if (params.activation == 0) return false;

        // Should trigger if hadn't been called in a while
        if (block.number.sub(params.lastSync) >= maxReportDelay) return true;

        // If some amount is owed, pay it back
        // NOTE: Since debt is adjusted in step-wise fashion, it is appropiate to always trigger here,
        //       because the resulting change should be large (might not always be the case)
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > dustThreshold && crETH.getCash().add(want.balanceOf(address(this))) > 0) return true;

         // Check for profits and losses
        uint256 total = estimatedTotalAssets();
        if (total.add(dustThreshold) < params.totalDebt) return true; // We have a loss to report!

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

        // Otherwise, only trigger if it "makes sense" economically (gas cost is <N% of value moved)
        uint256 credit = vault.creditAvailable();
        return (profitFactor * gasCost < credit.add(profit));
    }

    /***********
     * internal core logic
     *********** */
    /*
     * A core method.
     */
    function prepareReturn() internal override {

        if (crETH.balanceOf(address(this)) == 0) {
            //no position to harvest
            reserve = weth.balanceOf(address(this));
            return;
        }
        if (reserve != 0) {
            //reset reserve so it doesnt interfere anywhere else
            reserve = 0;
        }

        uint256 balanceInCr = crETH.balanceOfUnderlying(address(this));
        uint256 balanceInWeth = weth.balanceOf(address(this));
        uint256 total = balanceInCr.add(balanceInWeth);

        uint256 debt = vault.strategies(address(this)).totalDebt;

        if(total > debt){
            uint profit = total-debt;
            uint amountToFree = profit.add(outstanding);

            //we need to add outstanding to our profit
            if(balanceInWeth >= amountToFree){
                reserve = weth.balanceOf(address(this)) - amountToFree;
            }else{
                //change profit to what we can withdraw
                _withdrawSome(amountToFree.sub(balanceInWeth));
                balanceInWeth = weth.balanceOf(address(this));

                if(balanceInWeth > amountToFree){
                    reserve = balanceInWeth - amountToFree;
                }else{
                    reserve = 0;
                }

                
            }
            
        }else{
            uint256 bal = weth.balanceOf(address(this));
            if(bal <= outstanding){
                    reserve = 0;
            }else{
                reserve = bal - outstanding;
            }
        }

        
    }

    /*
     * Second core function. Happens after report call.
     *
     */

    function adjustPosition() internal override {
        //emergency exit is dealt with in prepareReturn
        if (emergencyExit) {
            return;
        }

        //we did state changing call in prepare return so this will be accurate
        uint liquidity = crETH.getCash();

        if(liquidity == 0){
            return;
        }

        uint wethBalance = weth.balanceOf(address(this));

        uint256 toKeep = 0;

        //to keep is the amount we need to hold to make the liqudity cushion full
        if(liquidity < liquidityCushion){
            toKeep = liquidityCushion.sub(liquidity);
        }
        toKeep = toKeep.add(outstanding);
        //if we have more than enough weth then invest the extra
        if(wethBalance > toKeep){

            uint toInvest = wethBalance.sub(toKeep);

            //turn weth into eth first
            weth.withdraw(toInvest);
            //mint
            crETH.mint{value: toInvest}();

        }else if(wethBalance < toKeep){
            //free up the difference if we can
            uint toWithdraw = toKeep.sub(wethBalance);

            _withdrawSome(toWithdraw);
        }

    }

    /*************
     * Withdraw Up to the amount asked for
     * returns amount we really withdrew
     ******************** */
    function _withdrawSome(uint256 _amount) internal returns(uint256 amountWithdrawn) {
        
        //state changing
        uint balance = crETH.balanceOfUnderlying(address(this));
        if(_amount > balance){
            //cant withdraw more than we own
            _amount = balance;
        }

        //not state changing but OK because of previous call
        uint liquidity = crETH.getCash();
        amountWithdrawn = 0;
        if(liquidity == 0){
            return amountWithdrawn;
        }

        if(_amount <= liquidity){
                amountWithdrawn = _amount;
                //we can take all
                crETH.redeemUnderlying(amountWithdrawn);
            }else{
                //take all we can
                amountWithdrawn = liquidity-1;
                crETH.redeemUnderlying(amountWithdrawn); //safe as we return if liquidity == 0
        }

        //remember to turn eth to weth
        weth.deposit{value: address(this).balance}();
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amount`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amount) internal override {
        uint256 _balance = want.balanceOf(address(this));

        if(_balance >= _amount){
            //if we don't set reserve here withdrawer will be sent our full balance
            reserve = _balance.sub(_amount);
            return;
        }else{
            _withdrawSome(_amount - _balance);
        }
    }

    /*
     * Make as much capital as possible "free" for the Vault to take. Some slippage
     * is allowed.
     */
    function exitPosition() internal override {
        
        uint balance = crETH.balanceOfUnderlying(address(this));
        if(balance > 0){
            _withdrawSome(balance);
        }
        reserve = 0;

    }

    //lets leave
    function prepareMigration(address _newStrategy) internal override {
        crETH.transfer(_newStrategy, crETH.balanceOf(address(this)));
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    function protectedTokens() internal override view returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        protected[1] = address(crETH);
        return protected;
    }

   
}