/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;



// Part: Governable

contract Governable {
    address public governance;
    address public pendingGovernance;

    constructor(address _governance) public {
        require(
            _governance != address(0),
            "governable::should-not-be-zero-address"
        );
        governance = _governance;
    }

    function setPendingGovernance(address _pendingGovernance)
        external
        onlyGovernance
    {
        pendingGovernance = _pendingGovernance;
    }

    function acceptGovernance() external onlyPendingGovernance {
        governance = msg.sender;
        pendingGovernance = address(0);
    }

    modifier onlyGovernance {
        require(msg.sender == governance, "governable::only-governance");
        _;
    }

    modifier onlyPendingGovernance {
        require(
            msg.sender == pendingGovernance,
            "governable::only-pending-governance"
        );
        _;
    }
}

// Part: IRegistry

interface IRegistry {
    function latestVault(address token) external view returns (address);

    function endorseVault(address vault) external;
}

// Part: IVaultMigrator

interface IVaultMigrator {
    function migrateAll(address vaultFrom, address vaultTo) external;

    function migrateShares(
        address vaultFrom,
        address vaultTo,
        uint256 shares
    ) external;

    function migrateAllWithPermit(
        address vaultFrom,
        address vaultTo,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function migrateSharesWithPermit(
        address vaultFrom,
        address vaultTo,
        uint256 shares,
        uint256 deadline,
        bytes calldata signature
    ) external;
}

// Part: OpenZeppelin/[email protected]0/Address

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

// Part: IChiToken

interface IChiToken is IERC20 {
    function mint(uint256 value) external;

    function computeAddress2(uint256 salt) external view returns (address);

    function free(uint256 value) external returns (uint256);

    function freeUpTo(uint256 value) external returns (uint256);

    function freeFrom(address from, uint256 value) external returns (uint256);

    function freeFromUpTo(address from, uint256 value)
        external
        returns (uint256);
}

// Part: ITrustedVaultMigrator

/**

Based on https://github.com/emilianobonassi/yearn-vaults-swap

 */

interface ITrustedVaultMigrator is IVaultMigrator {
    function registry() external returns (address);

    function sweep(address _token) external;

    function setRegistry(address _registry) external;
}

// Part: IVaultAPI

interface IVaultAPI is IERC20 {
    function deposit(uint256 _amount, address recipient)
        external
        returns (uint256 shares);

    function withdraw(uint256 _shares) external;

    function token() external view returns (address);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes calldata signature
    ) external returns (bool);
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

// Part: IGasBenefactor

interface IGasBenefactor {
    event ChiTokenSet(IChiToken _chiToken);
    event Subsidized(uint256 _amount, address _subsidizor);

    function chiToken() external view returns (IChiToken);

    function setChiToken(IChiToken _chiToken) external;

    function subsidize(uint256 _amount) external;
}

// Part: VaultMigrator

contract VaultMigrator is IVaultMigrator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IVaultAPI;

    modifier onlyCompatibleVaults(address vaultA, address vaultB) {
        require(
            IVaultAPI(vaultA).token() == IVaultAPI(vaultB).token(),
            "Vaults must have the same token"
        );
        _;
    }

    function migrateAll(address vaultFrom, address vaultTo) external override {
        _migrate(
            vaultFrom,
            vaultTo,
            IVaultAPI(vaultFrom).balanceOf(msg.sender)
        );
    }

    function migrateAllWithPermit(
        address vaultFrom,
        address vaultTo,
        uint256 deadline,
        bytes calldata signature
    ) external override {
        uint256 shares = IVaultAPI(vaultFrom).balanceOf(msg.sender);

        _permit(vaultFrom, shares, deadline, signature);
        _migrate(vaultFrom, vaultTo, shares);
    }

    function migrateShares(
        address vaultFrom,
        address vaultTo,
        uint256 shares
    ) external override {
        _migrate(vaultFrom, vaultTo, shares);
    }

    function migrateSharesWithPermit(
        address vaultFrom,
        address vaultTo,
        uint256 shares,
        uint256 deadline,
        bytes calldata signature
    ) external override {
        _permit(vaultFrom, shares, deadline, signature);
        _migrate(vaultFrom, vaultTo, shares);
    }

    function _permit(
        address vault,
        uint256 value,
        uint256 deadline,
        bytes calldata signature
    ) internal {
        require(
            IVaultAPI(vault).permit(
                msg.sender,
                address(this),
                value,
                deadline,
                signature
            ),
            "Unable to permit on vault"
        );
    }

    function _migrate(
        address vaultFrom,
        address vaultTo,
        uint256 shares
    ) internal virtual onlyCompatibleVaults(vaultFrom, vaultTo) {
        // Transfer in vaultFrom shares
        IVaultAPI vf = IVaultAPI(vaultFrom);

        uint256 preBalanceVaultFrom = vf.balanceOf(address(this));

        vf.safeTransferFrom(msg.sender, address(this), shares);

        uint256 balanceVaultFrom =
            vf.balanceOf(address(this)).sub(preBalanceVaultFrom);

        // Withdraw token from vaultFrom
        IERC20 token = IERC20(vf.token());

        uint256 preBalanceToken = token.balanceOf(address(this));

        vf.withdraw(balanceVaultFrom);

        uint256 balanceToken =
            token.balanceOf(address(this)).sub(preBalanceToken);

        // Deposit new vault
        token.safeIncreaseAllowance(vaultTo, balanceToken);

        IVaultAPI(vaultTo).deposit(balanceToken, msg.sender);
    }
}

// Part: GasBenefactor

abstract contract GasBenefactor is IGasBenefactor {
    using SafeERC20 for IChiToken;

    IChiToken public override chiToken;

    constructor(IChiToken _chiToken) public {
        _setChiToken(_chiToken);
    }

    modifier subsidizeUserTx {
        uint256 _gasStart = gasleft();
        _;
        // NOTE: Per EIP-2028, gas cost is 16 per (non-empty) byte in calldata
        uint256 _gasSpent =
            21000 + _gasStart - gasleft() + 16 * msg.data.length;
        // NOTE: 41947 is the estimated amount of gas refund realized per CHI redeemed
        // NOTE: 14154 is the estimated cost of the call to `freeFromUpTo`
        chiToken.freeUpTo((_gasSpent + 14154) / 41947);
    }

    modifier discountUserTx {
        uint256 _gasStart = gasleft();
        _;
        // NOTE: Per EIP-2028, gas cost is 16 per (non-empty) byte in calldata
        uint256 _gasSpent =
            21000 + _gasStart - gasleft() + 16 * msg.data.length;
        // NOTE: 41947 is the estimated amount of gas refund realized per CHI redeemed
        // NOTE: 14154 is the estimated cost of the call to `freeFromUpTo`
        chiToken.freeFromUpTo(msg.sender, (_gasSpent + 14154) / 41947);
    }

    function _subsidize(uint256 _amount) internal {
        require(_amount > 0, "GasBenefactor::_subsidize::zero-amount");
        chiToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Subsidized(_amount, msg.sender);
    }

    function _setChiToken(IChiToken _chiToken) internal {
        require(
            address(_chiToken) != address(0),
            "GasBenefactor::_setChiToken::zero-address"
        );
        chiToken = _chiToken;
        emit ChiTokenSet(_chiToken);
    }
}

// File: TrustedVaultMigrator.sol

contract TrustedVaultMigrator is
    VaultMigrator,
    Governable,
    GasBenefactor,
    ITrustedVaultMigrator
{
    address public override registry;

    modifier onlyLatestVault(address vault) {
        require(
            IRegistry(registry).latestVault(IVaultAPI(vault).token()) == vault,
            "Target vault should be the latest for token"
        );
        _;
    }

    constructor(address _registry, IChiToken _chiToken)
        public
        VaultMigrator()
        Governable(address(0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52))
        GasBenefactor(_chiToken)
    {
        require(_registry != address(0), "Registry cannot be 0");

        registry = _registry;
    }

    function _migrate(
        address vaultFrom,
        address vaultTo,
        uint256 shares
    ) internal override onlyLatestVault(vaultTo) {
        super._migrate(vaultFrom, vaultTo, shares);
    }

    function sweep(address _token) external override onlyGovernance {
        IERC20(_token).safeTransfer(
            governance,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function subsidize(uint256 _amount) external override {
        _subsidize(_amount);
    }

    // setters
    function setRegistry(address _registry) external override onlyGovernance {
        require(_registry != address(0), "Registry cannot be 0");
        registry = _registry;
    }

    function setChiToken(IChiToken _chiToken) external override onlyGovernance {
        _setChiToken(_chiToken);
    }
}