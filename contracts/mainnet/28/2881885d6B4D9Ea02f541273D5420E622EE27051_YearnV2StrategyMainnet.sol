/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: IFund

interface IFund {
    function underlying() external view returns (address);

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdraw(uint256 numberOfShares) external;

    function getPricePerShare() external view returns (uint256);

    function totalValueLocked() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256);
}

// Part: IGovernable

interface IGovernable {
    function governance() external view returns (address);
}

// Part: IStrategy

interface IStrategy {
    function underlying() external view returns (address);

    function fund() external view returns (address);

    function creator() external view returns (address);

    function withdrawAllToFund() external;

    function withdrawToFund(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256);

    function doHardWork() external;

    function depositArbCheck() external view returns (bool);
}

// Part: IYVaultV2

interface IYVaultV2 {
    // ERC20 part
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint256);

    // VaultV2 view interface
    function emergencyShutdown() external view returns (bool);

    function pricePerShare() external view returns (uint256);

    // VaultV2 user interface
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Math

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// Part: OpenZeppelin/[email protected]/SafeMath

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// Part: YearnV2StrategyBase

/**
 * This strategy takes an asset (DAI, USDC), deposits into yv2 vault. Currently building only for DAI.
 */
contract YearnV2StrategyBase is IStrategy {
    enum TokenIndex {DAI, USDC}

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public override underlying;
    address public override fund;
    address public override creator;

    // the matching enum record used to determine the index
    TokenIndex tokenIndex;

    // the y-vault corresponding to the underlying asset
    address public yVault;

    // these tokens cannot be claimed by the governance
    mapping(address => bool) public canNotSweep;

    bool public investActivated;

    constructor(
        address _fund,
        address _yVault,
        uint256 _tokenIndex
    ) public {
        fund = _fund;
        underlying = IFund(fund).underlying();
        tokenIndex = TokenIndex(_tokenIndex);
        yVault = _yVault;
        creator = msg.sender;

        // restricted tokens, can not be swept
        canNotSweep[underlying] = true;
        canNotSweep[yVault] = true;

        investActivated = true;
    }

    function governance() internal view returns (address) {
        return IGovernable(fund).governance();
    }

    modifier onlyFundOrGovernance() {
        require(
            msg.sender == fund || msg.sender == governance(),
            "The sender has to be the governance or fund"
        );
        _;
    }

    /**
     *  TODO
     */

    function depositArbCheck() public view override returns (bool) {
        return true;
    }

    /**
     * Allows Governance to withdraw partial shares to reduce slippage incurred
     *  and facilitate migration / withdrawal / strategy switch
     */
    function withdrawPartialShares(uint256 shares)
        external
        onlyFundOrGovernance
    {
        IYVaultV2(yVault).withdraw(shares);
    }

    function setInvestActivated(bool _investActivated)
        external
        onlyFundOrGovernance
    {
        investActivated = _investActivated;
    }

    /**
     * Withdraws an underlying asset from the strategy to the fund in the specified amount.
     * It tries to withdraw from the strategy contract if this has enough balance.
     * Otherwise, we withdraw shares from the yv2 vault. Transfer the required underlying amount to fund,
     * and reinvest the rest. We can make it better by calculating the correct amount and withdrawing only that much.
     */
    function withdrawToFund(uint256 underlyingAmount)
        external
        override
        onlyFundOrGovernance
    {
        uint256 underlyingBalanceBefore =
            IERC20(underlying).balanceOf(address(this));

        if (underlyingBalanceBefore >= underlyingAmount) {
            IERC20(underlying).safeTransfer(fund, underlyingAmount);
            return;
        }

        uint256 shares =
            shareValueFromUnderlying(
                underlyingAmount.sub(underlyingBalanceBefore)
            );
        IYVaultV2(yVault).withdraw(shares);

        // we can transfer the asset to the fund
        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        if (underlyingBalance > 0) {
            IERC20(underlying).safeTransfer(
                fund,
                Math.min(underlyingAmount, underlyingBalance)
            );
        }
    }

    /**
     * Withdraws all assets from the yv2 vault and transfer to fund.
     */
    function withdrawAllToFund() external override onlyFundOrGovernance {
        uint256 shares = IYVaultV2(yVault).balanceOf(address(this));
        IYVaultV2(yVault).withdraw(shares);
        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        if (underlyingBalance > 0) {
            IERC20(underlying).safeTransfer(fund, underlyingBalance);
        }
    }

    /**
     * Invests all underlying assets into our yv2 vault.
     */
    function investAllUnderlying() internal {
        if (!investActivated) {
            return;
        }

        require(
            !IYVaultV2(yVault).emergencyShutdown(),
            "Vault is emergency shutdown"
        );

        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        if (underlyingBalance > 0) {
            IERC20(underlying).safeApprove(yVault, 0);
            IERC20(underlying).safeApprove(yVault, underlyingBalance);
            // deposits the entire balance to yv2 vault
            IYVaultV2(yVault).deposit(underlyingBalance);
        }
    }

    /**
     * The hard work only invests all underlying assets
     */
    function doHardWork() public override onlyFundOrGovernance {
        investAllUnderlying();
    }

    // no tokens apart from underlying should be sent to this contract. Any tokens that are sent here by mistake are recoverable by governance
    function sweep(address _token, address _sweepTo) external {
        require(governance() == msg.sender, "Not governance");
        require(!canNotSweep[_token], "Token is restricted");
        IERC20(_token).safeTransfer(
            _sweepTo,
            IERC20(_token).balanceOf(address(this))
        );
    }

    /**
     * Returns the underlying invested balance. This is the underlying amount based on shares in the yv2 vault,
     * plus the current balance of the underlying asset.
     */
    function investedUnderlyingBalance()
        external
        view
        override
        returns (uint256)
    {
        uint256 shares = IERC20(yVault).balanceOf(address(this));
        uint256 price = IYVaultV2(yVault).pricePerShare();
        uint256 precision = 10**(IYVaultV2(yVault).decimals());
        uint256 underlyingBalanceinYVault = shares.mul(price).div(precision);
        return
            underlyingBalanceinYVault.add(
                IERC20(underlying).balanceOf(address(this))
            );
    }

    /**
     * Returns the value of the underlying token in yToken
     */
    function shareValueFromUnderlying(uint256 underlyingAmount)
        internal
        view
        returns (uint256)
    {
        uint256 precision = 10**(IYVaultV2(yVault).decimals());
        return
            underlyingAmount.mul(precision).div(IYVaultV2(yVault).pricePerShare());
    }
}

// File: YearnV2StrategyMainnet.sol

/**
 * Adds the mainnet addresses to the YearnV2StrategyBase
 */
contract YearnV2StrategyMainnet is YearnV2StrategyBase {
    // token addresses
    // y-addresses are taken from: https://docs.yearn.finance/products/yvaults-1/v2-yvaults/strategies-and-yvaults-available
    address public constant dai =
        address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public constant yvdai =
        address(0x19D3364A399d251E894aC732651be8B0E4e85001);
    address public constant usdc =
        address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant yvusdc =
        address(0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9);

    // pre-defined constant mapping: underlying -> y-token
    mapping(address => address) public yVaults;

    constructor(address _fund)
        public
        YearnV2StrategyBase(_fund, address(0), 0)
    {
        yVaults[dai] = yvdai;
        yVaults[usdc] = yvusdc;
        yVault = yVaults[underlying];
        require(
            yVault != address(0),
            "underlying not supported: yVault is not defined"
        );
        if (underlying == dai) {
            tokenIndex = TokenIndex.DAI;
        } else if (underlying == usdc) {
            tokenIndex = TokenIndex.USDC;
        } else {
            revert("Asset not supported");
        }
    }
}