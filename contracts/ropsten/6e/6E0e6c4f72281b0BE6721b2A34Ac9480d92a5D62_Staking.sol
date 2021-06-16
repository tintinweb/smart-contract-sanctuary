/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

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

    constructor () {
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


interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);

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
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
}

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

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract Staking is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint128 constant private BASE_MULTIPLIER = uint128(1 * 10 ** 18);

    // timestamp for the epoch 1
    // everything before that is considered epoch 0 which won't have a reward but allows for the initial stake
    uint256 public epoch1Start;

    // duration of each epoch
    uint256 public epochDuration;

    // holds the current balance of the user for each token
    mapping(address => mapping(address => uint256)) private balances;
    mapping(address => uint256) public stableCoinBalances;
    
    // address constant public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // address constant public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // address constant public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address constant public wbtcSwappLP = 0x5548F847Fd9a1D3487d5fbB2E8d73972803c4Cce;
    
    // address constant public cUsdc = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    // address constant public cUsdt = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;
    // address constant public cDai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    //Ropsten
    address constant public usdc = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address constant public usdt = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
    address constant public dai = 0x31F42841c2db5173425b5223809CF3A38FEde360;
    address constant public wbtcSwappLP = 0x63F7AB2f24322Ae2eaD6b971Cb9a71A1CC2eee03;

    address constant public cUsdc = 0x2973e69b20563bcc66dC63Bde153072c33eF37fe;
    address constant public cUsdt = 0xF6958Cf3127e62d3EB26c79F4f45d3F3b2CcdeD4;
    address constant public cDai = 0xbc689667C13FB2a04f09272753760E38a95B998C;
    
    // address to pay interest from Сompound
    address payable constant TEAM_ADDRESS = 0xde121Cc755c1D1786Dd46FfF7e373e9372FD79D8;

    struct Pool {
        uint256 size;
        bool set;
    }

    // for each token, we store the total pool size
    mapping(address => mapping(uint256 => Pool)) private poolSize;

    // a checkpoint of the valid balance of a user for an epoch
    struct Checkpoint {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    // balanceCheckpoints[user][token][]
    mapping(address => mapping(address => Checkpoint[])) private balanceCheckpoints;

    mapping(address => uint128) private lastWithdrawEpochId;


    //referrals
    uint256 public firstReferrerRewardPercentage;
    uint256 public secondReferrerRewardPercentage;

    struct Referrer {
        // uint256 totalReward;
        uint256 referralsCount;
        mapping(uint256 => address) referrals;
    }

    // staker to referrer
    mapping(address => address) public referrals;
    // referrer data
    mapping(address => Referrer) public referrers;

    event Deposit(address indexed user, address indexed tokenAddress, uint256 amount);
    event Withdraw(address indexed user, address indexed tokenAddress, uint256 amount);
    event ManualEpochInit(address indexed caller, uint128 indexed epochId, address[] tokens);
    event EmergencyWithdraw(address indexed user, address indexed tokenAddress, uint256 amount);
    
    event GetInterest(address indexed token, uint256 amount);
    event CheckInterest(uint256 cBalance, uint256 uBalance, uint256 interest);

    address public _owner;

    constructor () {
        epoch1Start = 1623862800; // to test ???
        epochDuration = 1800; // 28 days

        _owner = msg.sender;

        firstReferrerRewardPercentage = 100;
        secondReferrerRewardPercentage = 50;
    }

    function checkStableCoin(address token) public pure returns (bool) {
        if (token == usdc ||
            token == usdt ||
            token == dai
        ) {
            return true;
        }
        return false;
    }

    /*
     * Stores `amount` of `tokenAddress` tokens for the `user` into the vault
     */
    function deposit(address tokenAddress, uint256 amount, address referrer) public nonReentrant {
        require(amount > 0, "Staking: Amount must be > 0");
        bool isStableCoin = checkStableCoin(tokenAddress);

        require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount, "Staking: Token allowance too small");
        
        if (isStableCoin) {
            stableCoinBalances[tokenAddress] = stableCoinBalances[tokenAddress].add(amount);
            if (tokenAddress == usdt) {
                EIP20NonStandardInterface token = EIP20NonStandardInterface(tokenAddress);
                token.transferFrom(msg.sender, address(this), amount);
            } else {
                IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
            }
            _transferToCompound(tokenAddress, amount);
        } else {
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        }

        if (referrer != address(0)) {
            processReferrals(referrer);
        }

        balances[msg.sender][tokenAddress] = balances[msg.sender][tokenAddress].add(amount);

        // epoch logic
        uint128 currentEpoch = getCurrentEpoch();
        uint128 currentMultiplier = currentEpochMultiplier();

        if (!epochIsInitialized(tokenAddress, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            manualEpochInit(tokens, currentEpoch);
        }

        // update the next epoch pool size
        Pool storage pNextEpoch = poolSize[tokenAddress][currentEpoch + 1];
        if (isStableCoin) {
            pNextEpoch.size = stableCoinBalances[tokenAddress];
        } else {
            pNextEpoch.size = IERC20(tokenAddress).balanceOf(address(this));
        }
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[msg.sender][tokenAddress];

        uint256 balanceBefore = getEpochUserBalance(msg.sender, tokenAddress, currentEpoch);

        // if there's no checkpoint yet, it means the user didn't have any activity
        // we want to store checkpoints both for the current epoch and next epoch because
        // if a user does a withdraw, the current epoch can also be modified and
        // we don't want to insert another checkpoint in the middle of the array as that could be expensive
        if (checkpoints.length == 0) {
            checkpoints.push(Checkpoint(currentEpoch, currentMultiplier, 0, amount));

            // next epoch => multiplier is 1, epoch deposits is 0
            checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, amount, 0));
        } else {
            uint256 last = checkpoints.length - 1;

            // the last action happened in an older epoch (e.g. a deposit in epoch 3, current epoch is >=5)
            if (checkpoints[last].epochId < currentEpoch) {
                uint128 multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    BASE_MULTIPLIER,
                    amount,
                    currentMultiplier
                );
                checkpoints.push(Checkpoint(currentEpoch, multiplier, getCheckpointBalance(checkpoints[last]), amount));
                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, balances[msg.sender][tokenAddress], 0));
            }
            // the last action happened in the previous epoch
            else if (checkpoints[last].epochId == currentEpoch) {
                checkpoints[last].multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    checkpoints[last].multiplier,
                    amount,
                    currentMultiplier
                );
                checkpoints[last].newDeposits = checkpoints[last].newDeposits.add(amount);

                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, balances[msg.sender][tokenAddress], 0));
            }
            // the last action happened in the current epoch
            else {
                if (last >= 1 && checkpoints[last - 1].epochId == currentEpoch) {
                    checkpoints[last - 1].multiplier = computeNewMultiplier(
                        getCheckpointBalance(checkpoints[last - 1]),
                        checkpoints[last - 1].multiplier,
                        amount,
                        currentMultiplier
                    );
                    checkpoints[last - 1].newDeposits = checkpoints[last - 1].newDeposits.add(amount);
                }

                checkpoints[last].startBalance = balances[msg.sender][tokenAddress];
            }
        }

        uint256 balanceAfter = getEpochUserBalance(msg.sender, tokenAddress, currentEpoch);

        poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.add(balanceAfter.sub(balanceBefore));

        emit Deposit(msg.sender, tokenAddress, amount);
    }

    // must be in bases point ( 1,5% = 150 bp)
    function updateReferresPercentage(uint256 first, uint256 second) external {
        require(msg.sender == _owner, "Only owner can perfrom this action");
        firstReferrerRewardPercentage = first;
        secondReferrerRewardPercentage = second;
    }

    function processReferrals(address referrer) internal {
        //Return if sender has referrer alredy or referrer is contract or self ref
        if (hasReferrer(msg.sender) || !notContract(referrer) || referrer == msg.sender) {
            return;
        }

        //check cross refs 
        if (referrals[referrer] == msg.sender || referrals[referrals[referrer]] == msg.sender) {
            return;
        }
        
        //check if already has stake, do not add referrer if has
        uint256 staked = balanceOf(msg.sender, usdc).add(balanceOf(msg.sender, usdt)).add(balanceOf(msg.sender, dai)).add(balanceOf(msg.sender, wbtcSwappLP));
        if (staked > 0) {
            return;
        }

        referrals[msg.sender] = referrer;

        Referrer storage refData = referrers[referrer];

        refData.referralsCount = refData.referralsCount.add(1);
        refData.referrals[refData.referralsCount] = msg.sender;
    }

    function hasReferrer(address addr) public view returns(bool) {
        return referrals[addr] != address(0);
    }

    function getReferralById(address referrer, uint256 id) public view returns (address) {
        return referrers[referrer].referrals[id];
    }
    
    function _transferToCompound(address tokenAddress, uint256 amount) internal {
        address cToken = _getCompoundToken(tokenAddress);
        IERC20(tokenAddress).safeApprove(cToken, amount);
        CTokenInterface(cToken).mint(amount);
    }
    
    function _redeemFromCompound(address tokenAddress, uint256 amount) internal {
        address cToken = _getCompoundToken(tokenAddress);
        CTokenInterface(cToken).redeemUnderlying(amount);
    }
    
    function _getCompoundToken(address tokenAddress) internal pure returns (address cToken) {
        if (tokenAddress == usdc) {
            return cUsdc;
        }
        if (tokenAddress == usdt) {
            return cUsdt;
        }
        if (tokenAddress == dai) {
            return cDai;
        }
    }
    
    function checkInterestFromCompound(address tokenAddress) external returns (uint256 interest){
        bool isStableCoin = checkStableCoin(tokenAddress);
        require(isStableCoin, "Wrong token address");
        
        address cToken = _getCompoundToken(tokenAddress);
        uint256 cTBalance = CTokenInterface(cToken).balanceOf(address(this));
        if (cTBalance == 0) {
            emit CheckInterest(cTBalance, 0, 0);
            return 0;
        }
        
        uint256 cBalance = CTokenInterface(cToken).balanceOfUnderlying(address(this));
        uint256 balance = stableCoinBalances[tokenAddress];
        if (balance >= cBalance) {
            emit CheckInterest(cBalance, balance, 0);
            return 0;
        }
        
        uint256 _interest = cBalance.sub(balance);
        emit CheckInterest(cBalance, balance, _interest);
        return _interest;
    }
    
    //Get 80% of interest from Compound
    function getInterestFromCompound(address tokenAddress) external nonReentrant{
        bool isStableCoin = checkStableCoin(tokenAddress);
        require(isStableCoin, "Wrong token address");
        
        address cToken = _getCompoundToken(tokenAddress);
        uint256 cTBalance = CTokenInterface(cToken).balanceOf(address(this));
        require(cTBalance > 0, "There is no interest to withdraw");

        uint256 cBalance = CTokenInterface(cToken).balanceOfUnderlying(address(this));
        uint256 balance = stableCoinBalances[tokenAddress];
        require(cBalance > balance, "There is no interest to withdraw");

        uint256 interest = cBalance.sub(balance).mul(4).div(5);

        if (interest > 0) {
            CTokenInterface(cToken).redeemUnderlying(interest);
            if (tokenAddress == usdt) {
                EIP20NonStandardInterface(tokenAddress).transfer(TEAM_ADDRESS, interest);
            } else {
                IERC20(tokenAddress).transfer(TEAM_ADDRESS, interest);
            }
            emit GetInterest(tokenAddress, interest);
        }
    }
    
     //Get 100% of interest from Compound, recommended only after all users withdrawn their tokens
    function getInterest(address tokenAddress) external nonReentrant{
        bool isStableCoin = checkStableCoin(tokenAddress);
        require(isStableCoin, "Wrong token address");
        
        address cToken = _getCompoundToken(tokenAddress);
        uint256 cBalance = CTokenInterface(cToken).balanceOf(address(this));
        require(cBalance > 0, "No funds to withdraw");
        uint256 balance = stableCoinBalances[tokenAddress];
        CTokenInterface(cToken).redeem(cBalance);
        
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        
        uint256 interest = tokenBalance.sub(balance);
        if (interest > 0) {
            if (tokenAddress == usdt) {
                EIP20NonStandardInterface(tokenAddress).transfer(TEAM_ADDRESS, interest);
            } else {
                IERC20(tokenAddress).transfer(TEAM_ADDRESS, interest);
            }
            emit GetInterest(tokenAddress, interest);
        }
        
        if (balance > 0) {
            IERC20(tokenAddress).safeApprove(cToken, balance);
            CTokenInterface(cToken).mint(balance);
        }
    }
    
    /*
     * Removes the deposit of the user and sends the amount of `tokenAddress` back to the `user`
     */
    function withdraw(address tokenAddress, uint256 amount) public nonReentrant {
        require(balances[msg.sender][tokenAddress] >= amount, "Staking: balance too small");

        bool isStableCoin = checkStableCoin(tokenAddress);

        balances[msg.sender][tokenAddress] = balances[msg.sender][tokenAddress].sub(amount);

        if (isStableCoin) {
            stableCoinBalances[tokenAddress] = stableCoinBalances[tokenAddress].sub(amount);
            _redeemFromCompound(tokenAddress, amount);
            if (tokenAddress == usdt) {
                EIP20NonStandardInterface(tokenAddress).transfer(msg.sender, amount);
            } else {
                IERC20(tokenAddress).transfer(msg.sender, amount);
            }
        } else {
            IERC20(tokenAddress).transfer(msg.sender, amount);
        }

        // epoch logic
        uint128 currentEpoch = getCurrentEpoch();

        lastWithdrawEpochId[tokenAddress] = currentEpoch;

        if (!epochIsInitialized(tokenAddress, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            manualEpochInit(tokens, currentEpoch);
        }

        // update the pool size of the next epoch to its current balance
        Pool storage pNextEpoch = poolSize[tokenAddress][currentEpoch + 1];
        if (isStableCoin) {
            pNextEpoch.size = stableCoinBalances[tokenAddress];
        } else {
            pNextEpoch.size = IERC20(tokenAddress).balanceOf(address(this));
        }
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[msg.sender][tokenAddress];
        uint256 last = checkpoints.length - 1;

        // note: it's impossible to have a withdraw and no checkpoints because the balance would be 0 and revert

        // there was a deposit in an older epoch (more than 1 behind [eg: previous 0, now 5]) but no other action since then
        if (checkpoints[last].epochId < currentEpoch) {
            checkpoints.push(Checkpoint(currentEpoch, BASE_MULTIPLIER, balances[msg.sender][tokenAddress], 0));

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the `epochId - 1` epoch => we have a checkpoint for the current epoch
        else if (checkpoints[last].epochId == currentEpoch) {
            checkpoints[last].startBalance = balances[msg.sender][tokenAddress];
            checkpoints[last].newDeposits = 0;
            checkpoints[last].multiplier = BASE_MULTIPLIER;

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the current epoch
        else {
            Checkpoint storage currentEpochCheckpoint = checkpoints[last - 1];

            uint256 balanceBefore = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            // in case of withdraw, we have 2 branches:
            // 1. the user withdraws less than he added in the current epoch
            // 2. the user withdraws more than he added in the current epoch (including 0)
            if (amount < currentEpochCheckpoint.newDeposits) {
                uint128 avgDepositMultiplier = uint128(
                    balanceBefore.sub(currentEpochCheckpoint.startBalance).mul(BASE_MULTIPLIER).div(currentEpochCheckpoint.newDeposits)
                );

                currentEpochCheckpoint.newDeposits = currentEpochCheckpoint.newDeposits.sub(amount);

                currentEpochCheckpoint.multiplier = computeNewMultiplier(
                    currentEpochCheckpoint.startBalance,
                    BASE_MULTIPLIER,
                    currentEpochCheckpoint.newDeposits,
                    avgDepositMultiplier
                );
            } else {
                currentEpochCheckpoint.startBalance = currentEpochCheckpoint.startBalance.sub(
                    amount.sub(currentEpochCheckpoint.newDeposits)
                );
                currentEpochCheckpoint.newDeposits = 0;
                currentEpochCheckpoint.multiplier = BASE_MULTIPLIER;
            }

            uint256 balanceAfter = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(balanceBefore.sub(balanceAfter));

            checkpoints[last].startBalance = balances[msg.sender][tokenAddress];
        }

        emit Withdraw(msg.sender, tokenAddress, amount);
    }

    /*
     * manualEpochInit can be used by anyone to initialize an epoch based on the previous one
     * This is only applicable if there was no action (deposit/withdraw) in the current epoch.
     * Any deposit and withdraw will automatically initialize the current and next epoch.
     */
    function manualEpochInit(address[] memory tokens, uint128 epochId) public {
        require(epochId <= getCurrentEpoch(), "can't init a future epoch");

        for (uint i = 0; i < tokens.length; i++) {
            Pool storage p = poolSize[tokens[i]][epochId];

            if (epochId == 0) {
                p.size = uint256(0);
                p.set = true;
            } else {
                require(!epochIsInitialized(tokens[i], epochId), "Staking: epoch already initialized");
                require(epochIsInitialized(tokens[i], epochId - 1), "Staking: previous epoch not initialized");

                p.size = poolSize[tokens[i]][epochId - 1].size;
                p.set = true;
            }
        }

        emit ManualEpochInit(msg.sender, epochId, tokens);
    }

    function emergencyWithdraw(address tokenAddress) public {
        bool isStableCoin = checkStableCoin(tokenAddress);
        require(!isStableCoin, "Cant withdraw stable coins");
        require((getCurrentEpoch() - lastWithdrawEpochId[tokenAddress]) >= 10, "At least 10 epochs must pass without success");

        uint256 totalUserBalance = balances[msg.sender][tokenAddress];
        require(totalUserBalance > 0, "Amount must be > 0");

        balances[msg.sender][tokenAddress] = 0;

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, totalUserBalance);

        emit EmergencyWithdraw(msg.sender, tokenAddress, totalUserBalance);
    }

    /*
     * Returns the valid balance of a user that was taken into consideration in the total pool size for the epoch
     * A deposit will only change the next epoch balance.
     * A withdraw will decrease the current epoch (and subsequent) balance.
     */
    function getEpochUserBalance(address user, address token, uint128 epochId) public view returns (uint256) {
        Checkpoint[] storage checkpoints = balanceCheckpoints[user][token];

        // if there are no checkpoints, it means the user never deposited any tokens, so the balance is 0
        if (checkpoints.length == 0 || epochId < checkpoints[0].epochId) {
            return 0;
        }

        uint min = 0;
        uint max = checkpoints.length - 1;

        // shortcut for blocks newer than the latest checkpoint == current balance
        if (epochId >= checkpoints[max].epochId) {
            return getCheckpointEffectiveBalance(checkpoints[max]);
        }

        // binary search of the value in the array
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].epochId <= epochId) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return getCheckpointEffectiveBalance(checkpoints[min]);
    }

    /*
     * Returns the amount of `token` that the `user` has currently staked
     */
    function balanceOf(address user, address token) public view returns (uint256) {
        return balances[user][token];
    }

    /*
     * Returns the id of the current epoch derived from block.timestamp
     */
    function getCurrentEpoch() public view returns (uint128) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return uint128((block.timestamp - epoch1Start) / epochDuration + 1);
    }

    /*
     * Returns the total amount of `tokenAddress` that was locked from beginning to end of epoch identified by `epochId`
     */
    function getEpochPoolSize(address tokenAddress, uint128 epochId) public view returns (uint256) {
        // Premises:
        // 1. it's impossible to have gaps of uninitialized epochs
        // - any deposit or withdraw initialize the current epoch which requires the previous one to be initialized
        if (epochIsInitialized(tokenAddress, epochId)) {
            return poolSize[tokenAddress][epochId].size;
        }

        // epochId not initialized and epoch 0 not initialized => there was never any action on this pool
        if (!epochIsInitialized(tokenAddress, 0)) {
            return 0;
        }

        // epoch 0 is initialized => there was an action at some point but none that initialized the epochId
        // which means the current pool size is equal to the current balance of token held by the staking contract
        IERC20 token = IERC20(tokenAddress);

        if (checkStableCoin(tokenAddress)) {
            return stableCoinBalances[tokenAddress];
        }

        return token.balanceOf(address(this));
    }

    /*
     * Returns the percentage of time left in the current epoch
     */
    function currentEpochMultiplier() public view returns (uint128) {
        uint128 currentEpoch = getCurrentEpoch();
        uint256 currentEpochEnd = epoch1Start + currentEpoch * epochDuration;
        uint256 timeLeft = currentEpochEnd - block.timestamp;
        uint128 multiplier = uint128(timeLeft * BASE_MULTIPLIER / epochDuration);

        return multiplier;
    }

    function computeNewMultiplier(uint256 prevBalance, uint128 prevMultiplier, uint256 amount, uint128 currentMultiplier) public pure returns (uint128) {
        uint256 prevAmount = prevBalance.mul(prevMultiplier).div(BASE_MULTIPLIER);
        uint256 addAmount = amount.mul(currentMultiplier).div(BASE_MULTIPLIER);
        uint128 newMultiplier = uint128(prevAmount.add(addAmount).mul(BASE_MULTIPLIER).div(prevBalance.add(amount)));

        return newMultiplier;
    }

    /*
     * Checks if an epoch is initialized, meaning we have a pool size set for it
     */
    function epochIsInitialized(address token, uint128 epochId) public view returns (bool) {
        return poolSize[token][epochId].set;
    }

    function getCheckpointBalance(Checkpoint memory c) internal pure returns (uint256) {
        return c.startBalance.add(c.newDeposits);
    }

    function getCheckpointEffectiveBalance(Checkpoint memory c) internal pure returns (uint256) {
        return getCheckpointBalance(c).mul(c.multiplier).div(BASE_MULTIPLIER);
    }

    function notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly { size := extcodesize(_addr) }
        return (size == 0);
    }
}