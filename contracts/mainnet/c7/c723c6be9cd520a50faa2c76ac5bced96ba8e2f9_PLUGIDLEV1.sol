/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

//SPDX-License-Identifier: MIT
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
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
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
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
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
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    using SafeMath for uint256;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPLUGV1 {
    function upgradePlug(uint256 nextLevelCap) external;
    function chargePlug(uint256 amount) external;
    function dischargePlug(uint256 plugPercentage) external;
    function rebalancePlug() external;
    function tokenWant() external view returns(address);
    function tokenStrategy() external view returns(address);
    function tokenReward() external view returns(address);
}


abstract contract IdleYield {
    function mintIdleToken(uint256 amount, bool skipRebalance, address referral) external virtual returns(uint256);
    function redeemIdleToken(uint256 amount) external virtual returns(uint256);
    function balanceOf(address user) external virtual returns(uint256);
    function tokenPrice() external virtual view returns(uint256);
    function userAvgPrices(address user) external virtual view returns(uint256);
    function fee() external virtual view returns(uint256);
}

contract PLUGIDLEV1 is IPLUGV1, Ownable, Pausable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 private constant ONE_18 = 10**18;
    uint256 private constant FULL_ALLOC = 100000;
    
    address public constant override tokenWant = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC
    address public constant override tokenStrategy = address(0x5274891bEC421B39D23760c04A6755eCB444797C); // IDLEUSDC
    address public override tokenReward = address(0x20a68F9e34076b2dc15ce726d7eEbB83b694702d); // ISLA
    IdleYield strategy = IdleYield(tokenStrategy);
    IERC20 iTokenWant = IERC20(tokenWant);
    
    // addresses to send interests generated
    address public rewardOutOne;
    address public rewardOutTwo;
    // it should be used only when plug balance has to move to another plug
    address public plugHelper;
    
    // Plug parameter
    uint256 public currentLevelCap = uint256(150000).mul(ONE_18); // 150K token want
    uint256 public plugLimit = uint256(50000).mul(ONE_18); // 50K plug limit
    uint256 public plugLevel;
    mapping (address => uint256) public tokenStrategyAmounts;
    mapping (address => uint256) public tokenWantAmounts;
    mapping (address => uint256) public tokenWantDonated;
    uint256 public usersTokenWant;
    uint256 public lastRebalanceTs;
    uint256 twInStrategyLastRebalance;
    uint256 public rebalancePeriod = 3 days;
    uint256 public rewardRate = ONE_18;

    event PlugCharged(address user, uint256 amount, uint256 amountMinted);
    event PlugDischarged(address user, uint256 userAmount, uint256 rewardForUSer, uint256 rewardForPlug);
    event SentRewardToOutOne(address token, uint256 amount);
    event SentRewardToOutTwo(address token, uint256 amount);
    event Rebalance(uint256 amountEarned);

    constructor() {
        iTokenWant.approve(tokenStrategy, uint256(-1));
    }

    /**
     * Charge plug staking token want into idle.
     */
    function chargePlug(uint256 _amount) external override whenNotPaused() {
        usersTokenWant = usersTokenWant.add(_amount);
        require(usersTokenWant < plugLimit);
        iTokenWant.safeTransferFrom(msg.sender, address(this), _amount);
        require(_getPlugBalance(tokenWant) >= _amount);
        uint256 amountMinted = strategy.mintIdleToken(_amount, true, address(0));
        
        tokenStrategyAmounts[msg.sender] = tokenStrategyAmounts[msg.sender].add(amountMinted);
        tokenWantAmounts[msg.sender] = tokenWantAmounts[msg.sender].add(_amount);
        emit PlugCharged(msg.sender, _amount, amountMinted);
    }
    
    /**
     * Discharge plug withdrawing all token staked into idle
     * Choose the percentage to donate into the plug (0, 50, 100)
     * If there is any reward active it will be send respecting the actual reward rate
     */
    function dischargePlug(uint256 _plugPercentage) external override whenNotPaused() {
        _dischargePlug(_plugPercentage);
    }
    
    /**
     * Internal function to discharge plug
     */
    function _dischargePlug(uint256 _plugPercentage) internal {
        require(_plugPercentage == 0 || _plugPercentage == 50 || _plugPercentage == 100);
        uint256 userAmount = tokenWantAmounts[msg.sender];
        require(userAmount > 0);

        // transfer token want from IDLE to plug
        uint256 amountRedeemed = strategy.redeemIdleToken(tokenStrategyAmounts[msg.sender]);
        usersTokenWant = usersTokenWant.sub(userAmount); 

        // token want earned
        uint256 tokenEarned;
        uint256 rewardForUser;
        uint256 rewardForPlug;
        uint256 amountToDischarge;

        // it should be always greater, added for safe
        if (amountRedeemed <= userAmount) {
            tokenEarned = 0;
            userAmount = amountRedeemed;
        } else {
            tokenEarned = amountRedeemed.sub(userAmount);
            rewardForUser = tokenEarned; 
        }
        
        // calculate token earned percentage to donate into plug 
        if (_plugPercentage > 0 && tokenEarned > 0) {
            rewardForPlug = tokenEarned;
            rewardForUser = 0;
            if (_plugPercentage == 50) {
                rewardForPlug = rewardForPlug.div(2);
                rewardForUser = tokenEarned.sub(rewardForPlug);
            }
            uint256 rewardLeft = _getPlugBalance(tokenReward);
            if (rewardLeft > 0) {
                uint256 rewardWithRate = rewardForPlug.mul(rewardRate).div(ONE_18);
                _sendReward(rewardLeft, rewardWithRate); 
            }
            tokenWantDonated[msg.sender] = tokenWantDonated[msg.sender].add(rewardForPlug);
        }

        // transfer tokenWant userAmount to user
        amountToDischarge = userAmount.add(rewardForUser);
        _dischargeUser(amountToDischarge);
        emit PlugDischarged(msg.sender, userAmount, rewardForUser, rewardForPlug);
    }

    /**
     * Sending all token want owned by an user.
     */
    function _dischargeUser(uint256 _amount) internal {
        _sendTokenWant(_amount);
        tokenWantAmounts[msg.sender] = 0;
        tokenStrategyAmounts[msg.sender] = 0;
    }

    /**
     * Send token want to msg.sender.
     */
    function _sendTokenWant(uint256 _amount) internal {
        iTokenWant.safeTransfer(msg.sender, _amount); 
    }

    /**
     * Send token reward to users,
     */
    function _sendReward(uint256 _rewardLeft, uint256 _rewardWithRate) internal {
        if (_rewardLeft >= _rewardWithRate) {
            IERC20(tokenReward).safeTransfer(msg.sender, _rewardWithRate); 
        } else {
            IERC20(tokenReward).safeTransfer(msg.sender, _rewardLeft); 
        } 
    }
    
    /**
     * Rebalance plug every rebalance period.
     */
    function rebalancePlug() external override whenNotPaused() {
        _rebalancePlug();
    }
    
    /**
     * Internsal function for rebalance.
     */
    function _rebalancePlug() internal {
        require(lastRebalanceTs.add(rebalancePeriod) < block.timestamp);
        lastRebalanceTs = block.timestamp;
        
        uint256 twPlug = iTokenWant.balanceOf(address(this));
        
        uint256 twInStrategy;
        uint256 teInStrategy;
        uint256 teByPlug;
        
        // reinvest token want to strategy
        if (plugLevel == 0) {
            _rebalanceAtLevel0(twPlug);
        } else {
            twInStrategy = _getTokenWantInS();
            teInStrategy = twInStrategy.sub(twInStrategyLastRebalance);
            teByPlug = twPlug.add(teInStrategy);
            if (plugLevel == 1) {
                _rebalanceAtLevel1Plus(teByPlug.div(2));
            } else {
                _rebalanceAtLevel1Plus(teByPlug.div(3));
            }
        }
        twInStrategyLastRebalance = _getTokenWantInS();
    }
    
    /**
     * Rebalance plug at level 0
     * Mint all tokens want owned by plug to idle pool 
     */
    function _rebalanceAtLevel0(uint256 _amount) internal {
        uint256 mintedTokens = strategy.mintIdleToken(_amount, true, address(0));
        tokenStrategyAmounts[address(this)] = tokenStrategyAmounts[address(this)].add(mintedTokens); 
    }
    
    /**
     * Rebalance plug at level1+.
     * level1 -> 50% remain into plug and 50% send to reward1
     * level2+ -> 33.3% to plug 33.3% to reward1 and 33.3% to reward2
     */
    function _rebalanceAtLevel1Plus(uint256 _amount) internal {
        uint256 plugAmount = _getPlugBalance(tokenWant);
        uint256 amountToSend = _amount;
        
        if (plugLevel > 1) {
            amountToSend = amountToSend.mul(2);
        }
        
        if (plugAmount < amountToSend) {
            uint256 amountToRetrieveFromS = amountToSend.sub(plugAmount);
            uint256 amountToRedeem = amountToRetrieveFromS.div(_getRedeemPrice()).mul(ONE_18);
            strategy.redeemIdleToken(amountToRedeem);
            tokenStrategyAmounts[address(this)] = tokenStrategyAmounts[address(this)].sub(amountToRedeem);
        }
        
        // send to reward out 1
        _transferToOutside(tokenWant, rewardOutOne, _amount);
        
        if (plugLevel > 1) {
            _transferToOutside(tokenWant, rewardOutTwo, _amount);
        }
        
        //send all remain token want from plug to idle strategy
        uint256 balanceLeft = plugAmount.sub(amountToSend);
        if (balanceLeft > 0) {
            _rebalanceAtLevel0(balanceLeft);
        }
    }

    /**
     * Upgrade plug to the next level.
     */
    function upgradePlug(uint256 _nextLevelCap) external override onlyOwner {
        require(_nextLevelCap > currentLevelCap && plugTotalAmount() > currentLevelCap);
        require(rewardOutOne != address(0));
        if (plugLevel >= 1) {
            require(rewardOutTwo != address(0));
            require(plugHelper != address(0));
        }
        plugLevel = plugLevel + 1;
        currentLevelCap = _nextLevelCap;
    }
    
    /**
     * Redeem all token owned by plug from idle strategy.
     */
    function safePlugExitStrategy(uint256 _amount) external onlyOwner {
        strategy.redeemIdleToken(_amount);
        tokenStrategyAmounts[address(this)] = tokenStrategyAmounts[address(this)].sub(_amount);
        twInStrategyLastRebalance = _getTokenWantInS();
    }
    
    /**
     * Transfer token want to factory.
     */
    function transferToHelper() external onlyOwner {
        require(plugHelper != address(0));
        uint256 amount = iTokenWant.balanceOf(address(this));
        _transferToOutside(tokenWant, plugHelper, amount);
    }
    
    /**
     * Transfer token different than token strategy to external allowed address (ex IDLE, COMP, ecc).
     */
    function transferToRewardOut(address _token, address _rewardOut) external onlyOwner {
        require(_token != address(0) && _rewardOut != address(0));
        require(_rewardOut == rewardOutOne || _rewardOut == rewardOutTwo);
        // it prevents to tranfer idle tokens outside
        require(_token != tokenStrategy);
        uint256 amount = IERC20(_token).balanceOf(address(this));
        _transferToOutside(_token, _rewardOut, amount);
    }
    
    /**
     * Transfer any token to external address.
     */
    function _transferToOutside(address _token, address _outside, uint256 _amount) internal {
      IERC20(_token).safeTransfer(_outside, _amount);  
    }

    /**
     * Approve token to spender.
     */
    function safeTokenApprore(address _token, address _spender, uint256 _amount) external onlyOwner {
        IERC20(_token).approve(_spender, _amount);
    }
    
    /**
     * Set the current level cap.
     */
    function setCurrentLevelCap(uint256 _newCap) external onlyOwner {
        require(_newCap > plugTotalAmount());
        currentLevelCap = _newCap;
    }
    
    /**
     * Set a new token reward.
     */
    function setTokenReward(address _tokenReward) external onlyOwner {
        tokenReward = _tokenReward;
    }

    /**
     * Set the new reward rate in decimals (18).
     */
    function setRewardRate(uint256 _rate) external onlyOwner {
        rewardRate = _rate;
    }
    
    /**
     * Set the first reward pool address.
     */
    function setRewardOutOne(address _reward) external onlyOwner {
        rewardOutOne = _reward;
    }
    
    /**
     * Set the second reward pool address.
     */
    function setRewardOutTwo(address _reward) external onlyOwner {
        rewardOutTwo = _reward;
    }
    
    /**
     * Set the plug helper address.
     */
    function setPlugHelper(address _plugHelper) external onlyOwner {
        plugHelper = _plugHelper;
    }
    
    /**
     * Set the new rebalance period duration.
     */ 
    function setRebalancePeriod(uint256 _newPeriod) external onlyOwner {
        // at least 12 hours (60 * 60 * 12)
        require(_newPeriod >= 43200);
        rebalancePeriod = _newPeriod;
    }

    /**
     * Set the new plug cap for token want to store in it.
     */ 
    function setPlugUsersLimit(uint256 _newLimit) external onlyOwner {
        require(_newLimit > plugLimit);
        plugLimit = _newLimit;
    }

    /**
     * Get the current reedem price.
     * @notice function helper for retrieving the idle token price counting fees, developed by @emilianobonassi
     * https://github.com/emilianobonassi/idle-token-helper
     */
    function _getRedeemPrice() view internal returns (uint256 redeemPrice) {
        uint256 userAvgPrice = strategy.userAvgPrices(address(this));
        uint256 currentPrice = strategy.tokenPrice();

        // When no deposits userAvgPrice is 0 equiv currentPrice
        // and in the case of issues
        if (userAvgPrice == 0 || currentPrice < userAvgPrice) {
            redeemPrice = currentPrice;
        } else {
            uint256 fee = strategy.fee();

            redeemPrice = ((currentPrice.mul(FULL_ALLOC))
                .sub(
                    fee.mul(
                         currentPrice.sub(userAvgPrice)
                    )
                )).div(FULL_ALLOC);
        }

        return redeemPrice;
    }

    /**
     * Get the plug balance of a token.
     */
    function _getPlugBalance(address _token) internal view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * Get the plug balance of token want into idle strategy.
     */
    function _getTokenWantInS() internal view returns (uint256) {
        uint256 tokenPrice = _getRedeemPrice();
        return tokenStrategyAmounts[address(this)].mul(tokenPrice).div(ONE_18);
    }

    /**
     * Get the plug total amount between the ineer and the amount store into idle.
     */
    function plugTotalAmount() public view returns(uint256) {
        uint256 tokenWantInStrategy = _getTokenWantInS();
        return iTokenWant.balanceOf(address(this)).add(tokenWantInStrategy);
    }
}