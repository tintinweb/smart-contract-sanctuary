// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/external/yearn/IVault.sol";
import "./AdapterBase.sol";

// https://docs.yearn.finance/developers/yvaults-documentation/vault-interfaces#ivault
contract YvdaiAdapter is AdapterBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public governanceAccount;
    address public underlyingAssetAddress;
    address public programAddress;
    address public farmingPoolAddress;

    IVault private _yvdai;
    IERC20 private _underlyingAsset;

    constructor(
        address underlyingAssetAddress_,
        address programAddress_,
        address farmingPoolAddress_
    ) {
        require(
            underlyingAssetAddress_ != address(0),
            "YvdaiAdapter: underlying asset address is the zero address"
        );
        require(
            programAddress_ != address(0),
            "YvdaiAdapter: yvDai address is the zero address"
        );
        require(
            farmingPoolAddress_ != address(0),
            "YvdaiAdapter: farming pool address is the zero address"
        );

        governanceAccount = msg.sender;
        underlyingAssetAddress = underlyingAssetAddress_;
        programAddress = programAddress_;
        farmingPoolAddress = farmingPoolAddress_;

        _yvdai = IVault(programAddress);
        _underlyingAsset = IERC20(underlyingAssetAddress);
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "YvdaiAdapter: sender not authorized");
        _;
    }

    function getTotalWrappedTokenAmountCore()
        internal
        view
        override
        returns (uint256)
    {
        return _yvdai.balanceOf(address(this));
    }

    function getWrappedTokenPriceInUnderlyingCore()
        internal
        view
        override
        returns (uint256)
    {
        require(
            _yvdai.decimals() <= 18,
            "YvdaiAdapter: greater than 18 decimal places"
        );

        uint256 originalPrice = _yvdai.pricePerShare();
        uint256 scale = 18 - _yvdai.decimals();

        return originalPrice.mul(10**scale);
    }

    // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
    // The reentrancy check is in farming pool.
    function depositUnderlyingToken(uint256 amount)
        external
        override
        onlyBy(farmingPoolAddress)
        returns (uint256)
    {
        require(amount != 0, "YvdaiAdapter: can't add 0");

        _underlyingAsset.safeTransferFrom(msg.sender, address(this), amount);
        _underlyingAsset.safeApprove(programAddress, amount);
        uint256 receivedWrappedTokenQuantity =
            _yvdai.deposit(amount, address(this));

        // slither-disable-next-line reentrancy-events
        emit DepositUnderlyingToken(
            underlyingAssetAddress,
            programAddress,
            amount,
            receivedWrappedTokenQuantity,
            msg.sender,
            block.timestamp
        );

        return receivedWrappedTokenQuantity;
    }

    // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
    // The reentrancy check is in farming pool.
    function redeemWrappedToken(uint256 maxAmount)
        external
        override
        onlyBy(farmingPoolAddress)
        returns (uint256, uint256)
    {
        require(maxAmount != 0, "YvdaiAdapter: can't redeem 0");

        uint256 beforeBalance = _yvdai.balanceOf(address(this));
        // The default maxLoss is 1: https://github.com/yearn/yearn-vaults/blob/v0.3.0/contracts/Vault.vy#L860
        uint256 receivedUnderlyingTokenQuantity =
            _yvdai.withdraw(maxAmount, msg.sender, 1);
        uint256 afterBalance = _yvdai.balanceOf(address(this));

        uint256 actualAmount = beforeBalance.sub(afterBalance);
        // slither-disable-next-line reentrancy-events
        emit RedeemWrappedToken(
            underlyingAssetAddress,
            programAddress,
            maxAmount,
            actualAmount,
            receivedUnderlyingTokenQuantity,
            msg.sender,
            block.timestamp
        );

        return (actualAmount, receivedUnderlyingTokenQuantity);
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newGovernanceAccount != address(0),
            "YvdaiAdapter: new governance account is the zero address"
        );

        governanceAccount = newGovernanceAccount;
    }

    function setFarmingPoolAddress(address newFarmingPoolAddress)
        external
        onlyBy(governanceAccount)
    {
        require(
            newFarmingPoolAddress != address(0),
            "YvdaiAdapter: new farming pool address is the zero address"
        );

        farmingPoolAddress = newFarmingPoolAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

// v1:
//  - https://docs.yearn.finance/developers/yvaults-documentation/vault-interfaces#ivault
//  - https://github.com/yearn/yearn-protocol/blob/develop/interfaces/yearn/IVault.sol
//
// Current:
//  - https://etherscan.io/address/0x19D3364A399d251E894aC732651be8B0E4e85001#code
//  - https://github.com/yearn/yearn-vaults/blob/v0.3.0/contracts/Vault.vy

pragma solidity ^0.7.6;

interface IVault {
    function decimals() external view returns (uint256);

    /**
     * @notice Gives the price for a single Vault share.
     * @dev See dev note on `withdraw`.
     * @return The value of a single share.
     */
    function pricePerShare() external view returns (uint256);

    /**
     * @notice
     *     Deposits `_amount` `token`, issuing shares to `recipient`. If the
     *     Vault is in Emergency Shutdown, deposits will not be accepted and this
     *     call will fail.
     * @dev
     *     Measuring quantity of shares to issues is based on the total
     *     outstanding debt that this contract has ("expected value") instead
     *     of the total balance sheet it has ("estimated value") has important
     *     security considerations, and is done intentionally. If this value were
     *     measured against external systems, it could be purposely manipulated by
     *     an attacker to withdraw more assets than they otherwise should be able
     *     to claim by redeeming their shares.
     *     On deposit, this means that shares are issued against the total amount
     *     that the deposited capital can be given in service of the debt that
     *     Strategies assume. If that number were to be lower than the "expected
     *     value" at some future point, depositing shares via this method could
     *     entitle the depositor to *less* than the deposited value once the
     *     "realized value" is updated from further reports by the Strategies
     *     to the Vaults.
     *     Care should be taken by integrators to account for this discrepancy,
     *     by using the view-only methods of this contract (both off-chain and
     *     on-chain) to determine if depositing into the Vault is a "good idea".
     * @param _amount   The quantity of tokens to deposit, defaults to all.
     * @param recipient The address to issue the shares in this Vault to. Defaults
     *                  to the caller's address.
     * @return The issued Vault shares.
     */
    function deposit(uint256 _amount, address recipient)
        external
        returns (uint256);

    /**
     * @notice
     *     Withdraws the calling account's tokens from this Vault, redeeming
     *     amount `_shares` for an appropriate amount of tokens.
     *     See note on `setWithdrawalQueue` for further details of withdrawal
     *     ordering and behavior.
     * @dev
     *     Measuring the value of shares is based on the total outstanding debt
     *     that this contract has ("expected value") instead of the total balance
     *     sheet it has ("estimated value") has important security considerations,
     *     and is done intentionally. If this value were measured against external
     *     systems, it could be purposely manipulated by an attacker to withdraw
     *     more assets than they otherwise should be able to claim by redeeming
     *     their shares.
     *     On withdrawal, this means that shares are redeemed against the total
     *     amount that the deposited capital had "realized" since the point it
     *     was deposited, up until the point it was withdrawn. If that number
     *     were to be higher than the "expected value" at some future point,
     *     withdrawing shares via this method could entitle the depositor to
     *     *more* than the expected value once the "realized value" is updated
     *     from further reports by the Strategies to the Vaults.
     *     Under exceptional scenarios, this could cause earlier withdrawals to
     *     earn "more" of the underlying assets than Users might otherwise be
     *     entitled to, if the Vault's estimated value were otherwise measured
     *     through external means, accounting for whatever exceptional scenarios
     *     exist for the Vault (that aren't covered by the Vault's own design.)
     * @param maxShares How many shares to try and redeem for tokens, defaults to
     *                  all.
     * @param recipient The address to issue the shares in this Vault to. Defaults
     *                  to the caller's address.
     * @param maxLoss   The maximum acceptable loss to sustain on withdrawal. Defaults
     *                  to 0%.
     * @return The quantity of tokens redeemed for `_shares`.
     */
    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function balanceOf(address) external view returns (uint256);

    /**
     * @notice
     *     Transfers shares from the caller's address to `receiver`. This function
     *     will always return true, unless the user is attempting to transfer
     *     shares to this contract's address, or to 0x0.
     * @param receiver  The address shares are being transferred to. Must not be
     *                   this contract's address, must not be 0x0.
     * @param amount    The quantity of shares to transfer.
     * @return
     *     True if transfer is sent to an address other than this contract's or
     *     0x0, otherwise the transaction will fail.
     */
    function transfer(address receiver, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IAdapter.sol";

abstract contract AdapterBase is IAdapter {
    using SafeMath for uint256;

    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function getTotalWrappedTokenAmountCore()
        internal
        view
        virtual
        returns (uint256);

    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function getWrappedTokenPriceInUnderlyingCore()
        internal
        view
        virtual
        returns (uint256);

    function getRedeemableUnderlyingTokensForCore(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 price = getWrappedTokenPriceInUnderlyingCore();

        return amount.mul(price).div(10**18);
    }

    function getWrappedTokenPriceInUnderlying()
        external
        view
        override
        returns (uint256)
    {
        return getWrappedTokenPriceInUnderlyingCore();
    }

    function getRedeemableUnderlyingTokensFor(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        return getRedeemableUnderlyingTokensForCore(amount);
    }

    function getTotalRedeemableUnderlyingTokens()
        external
        view
        override
        returns (uint256)
    {
        uint256 totalWrappedTokenAmount = getTotalWrappedTokenAmountCore();

        return getRedeemableUnderlyingTokensForCore(totalWrappedTokenAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IAdapter {
    /*
     * @return The wrapped token price in underlying (18 decimal places).
     */
    function getWrappedTokenPriceInUnderlying() external view returns (uint256);

    function getTotalRedeemableUnderlyingTokens()
        external
        view
        returns (uint256);

    function getRedeemableUnderlyingTokensFor(uint256 amount)
        external
        view
        returns (uint256);

    function depositUnderlyingToken(uint256 amount) external returns (uint256);

    function redeemWrappedToken(uint256 maxAmount)
        external
        returns (uint256 actualAmount, uint256 quantity);

    event DepositUnderlyingToken(
        address indexed underlyingAssetAddress,
        address indexed wrappedTokenAddress,
        uint256 underlyingAssetAmount,
        uint256 wrappedTokenQuantity,
        address operator,
        uint256 timestamp
    );

    event RedeemWrappedToken(
        address indexed underlyingAssetAddress,
        address indexed wrappedTokenAddress,
        uint256 maxWrappedTokenAmount,
        uint256 actualWrappedTokenAmount,
        uint256 underlyingAssetQuantity,
        address operator,
        uint256 timestamp
    );
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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