/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

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
    constructor () internal { }
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
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

    constructor() internal {
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
    constructor () public {
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
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    uint256 public renounceOwnershipTimestamp;
    uint256 public transferOwnershipTimestamp;
    address public newOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        newOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

    function setTransferOwnershipTimestamp(address _newOwner) external onlyOwner{
        newOwner = _newOwner;
        transferOwnershipTimestamp = block.timestamp + 1 days;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        if(renounceOwnershipTimestamp == 0){
            renounceOwnershipTimestamp = block.timestamp + 1 days;
        }else{
            require(renounceOwnershipTimestamp <= block.timestamp, "you can't renounce the ownership");
            emit OwnershipTransferred(_owner, address(0));
            _owner = address(0);
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership() external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(transferOwnershipTimestamp <= block.timestamp, "you can't change the owner");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IVault {
  function addGovernace ( address _governance ) external;
  function addressToId ( address ) external view returns ( uint256 );
  function createPool ( address _lpToken, string memory _symbol ) external;
  function owner (  ) external view returns ( address );
  function poolInfo ( uint256 ) external view returns ( address lpToken, string memory symbol, uint256 totalSupply );
  function poolLength (  ) external view returns ( uint256 );
  function rebalanceTotalSupply ( uint256 _pid ) external;
  function removeGovernance ( address _governance ) external;
  function renounceOwnership (  ) external;
  function transferOwnership ( address newOwner ) external;
  function updatePool ( address _lpToken ) external;
  function withdraw ( uint256 _pid, uint256 amount, address receiver ) external;
  function withdrawAll ( uint256 _pid, address receiver ) external;
  function withdrawAllFromAddress ( address _contract, address receiver ) external;
  function withdrawFromAddress ( address _contract, uint256 amount, address receiver ) external;
}

contract DoubleMaster is ReentrancyGuard, Pausable, Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    struct UserInfo {
        uint256 amount; // amount of lpToken
        uint256 rewardMinusFirst;
        uint256 rewardMinusSecond;
    }
    
    struct PoolInfo {
        IERC20 lpToken; // address of the lpToken
        string symbol; // symbol of the lp token
        uint16 fee; // fees for the deposit, 200 = 2%, 100 = 1% etc..
        address vault; // the address of the vault, this could be a smart contract or an EOA
        uint256 totalSupply; //totalSupply in the farm
        uint256 firstPerBlock; //krw per block minted
        uint256 secondPerBlock;
        uint256 lastRewardBlock; // last block that minted rewards, is updated in the updatepool function
        uint256 firstRewardsPerShare;
        uint256 secondRewardsPerShare;
        IERC20 first;
        IERC20 second;
        uint256 lastBlock;
    }
    
    mapping(address => bool) public tokenAlreadyInPool;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    bool public pausedUpdatePools;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    mapping(uint256 => bool) public pausedPool;
    
    /**
     * @dev Used to get the deposited amount in a pool
     */
    function getDeposit(uint256 _pid, address account) external view returns(uint256){
        UserInfo memory user = userInfo[_pid][account];
        return user.amount;
    }
    
    /**
     * @dev used to get the pending amount in a pool
     */
    function getPendingFirst(uint256 _pid, address account) public view returns(uint256){
        UserInfo memory user = userInfo[_pid][account];
        PoolInfo memory pool = poolInfo[_pid];
        if(user.amount == 0){
          return 0;  
        }
        uint256 firstRewardToDeliver;
        if(pool.lastBlock > block.number){
            firstRewardToDeliver = pool.firstPerBlock.mul(block.number.sub(pool.lastRewardBlock));
        }else{
            firstRewardToDeliver = pool.firstPerBlock.mul(pool.lastBlock.sub(pool.lastRewardBlock));
        }
        return ((user.amount.mul(pool.firstRewardsPerShare.add((firstRewardToDeliver.mul(1e18)).div(pool.totalSupply)))).div(1e18)).sub(user.rewardMinusFirst);
    }
    
    /**
     * @dev used to get the pending amount in a pool
     */
    function getPendingSecond(uint256 _pid, address account) public view returns(uint256){
        UserInfo memory user = userInfo[_pid][account];
        PoolInfo memory pool = poolInfo[_pid];
        if(user.amount == 0){
          return 0;  
        }
        uint256 secondRewardToDeliver;
        if(pool.lastBlock > block.number){
            secondRewardToDeliver = pool.secondPerBlock.mul(block.number.sub(pool.lastRewardBlock));
        }else{
            secondRewardToDeliver = pool.secondPerBlock.mul(pool.lastBlock.sub(pool.lastRewardBlock));
        }
        return ((user.amount.mul(pool.secondRewardsPerShare.add((secondRewardToDeliver.mul(1e18)).div(pool.totalSupply)))).div(1e18)).sub(user.rewardMinusSecond);
    }
    
    /**
     * @dev Add a new lp to the pool. Can only be called by the owner.
     * Can only be called by the current owner.
     * _lpToken: the liquidity pool token that you want to use in the farm 
     * _krwPerBlock: the number of krw that you want to mint per block in this specific farm
     * _symbol: symbol of the lpToken
     * _fee: fee applied to the pool
     * _vault: the address of the vault
     * isVaultContract: false if the address of vault is an EOA, true if the vault is a smart contract
     * NOTE: mint is actually the wrong word for this case, because all the krw are pre-minted and will be just transfered when people claim their rewards
     */
    function createPool(address _lpToken, string memory _symbol, uint16 _fee, address _vault, uint256 _firstPerBlock, uint256 _secondPerBlock, address _first, address _second, uint256 _desiredBlock) external onlyOwner{
        require(!tokenAlreadyInPool[_lpToken], "Token already in a pool");
        require(_vault != address(0x0), "Vault is the zero address");
        require(_first != address(0x0), "First is the zero address");
        require(_second != address(0x0), "Second is the zero address");
        require(_fee <= 1000, "Fee is to high");
        require(_first != _lpToken, "the first token needs to be different from the lp");
        require(_second != _lpToken, "the second token needs to be different from the lp");
        require(_lpToken.isContract(), "the lp token needs to be a contract");
        require(_first.isContract(), "the first token needs to be a contract");
        require(_second.isContract(), "the second token needs to be a contract");
        poolInfo.push(PoolInfo(IERC20(_lpToken), _symbol, _fee, _vault, 0, _firstPerBlock, _secondPerBlock ,block.number, 0, 0, IERC20(_first), IERC20(_second), block.number.add(_desiredBlock)));
        tokenAlreadyInPool[_lpToken] = true;
    }
    
    /**
     * @dev Changes the vault address
     * _pid: the id of the pool that needs to change the vault address
     * _vault: the new vault address
     * _isVaultContract: variable that checks if the vault is a smart contract or an EOA and updates the vault pools accordingly
     */
    function changeVault(uint256 _pid, address _vault) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.vault = _vault;
    }
    
    function changeFirst(uint256 _pid, address _first) external onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        require(_first != address(0x0), "First is the zero address");
        require(address(_first) != address(pool.lpToken), "the first token needs to be different from the lp");
        require(pool.totalSupply == 0, "totalSupply needs to be 0 to change the address");
        require(_first.isContract(), "the token needs to be a contract");
        pool.first = IERC20(_first);
    }
    
    function changeSecond(uint256 _pid, address _second) external onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        require(_second != address(0x0), "First is the zero address");
        require(address(_second) != address(pool.lpToken), "the first token needs to be different from the lp");
        require(pool.totalSupply == 0, "totalSupply needs to be 0 to change the address");
        require(_second.isContract(), "the token needs to be a contract");
        pool.second = IERC20(_second);
    }
    
    /**
     * @dev changes the fee to enter the pool
     * _pid: is the id of the pool that you want to apply this changes
     * _fee: is the new fee of the pool
     */
    function changeFee(uint256 _pid, uint16 _fee) external onlyOwner{
        require(_fee <= 1000, "Fee is to high");
        PoolInfo storage pool = poolInfo[_pid];
        pool.fee = _fee;
    }
    
    /**
     * @dev returns the current number of pools
     */
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }
    
    /**
     * @dev changes the krw rewards per block
     * _pid: is the id of the pool that you want to apply this changes
     * _krwPerBlock: is the new reward per block
     */
    function changePoolFirstReward(uint256 _pid, uint256 _firstPerBlock) external onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        pool.firstPerBlock = _firstPerBlock;
    }
    
    /**
     * @dev changes the krw rewards per block
     * _pid: is the id of the pool that you want to apply this changes
     * _krwPerBlock: is the new reward per block
     */
    function changePoolSecondReward(uint256 _pid, uint256 _secondPerBlock) external onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        pool.secondPerBlock = _secondPerBlock;
    }
    
    /**
     * @dev changes to the last reward block
     * _pid: is the id of the pool that you want to apply this changes
     */
    function changeLastRewardBlock(uint256 _pid) internal{
        PoolInfo storage pool = poolInfo[_pid];
        pool.lastRewardBlock = block.number;
    }
    
    /**
     * @dev function used to change the last block that will create reward for all the pools
     * _lastBlock: the new number of the last block
     */
    function changeLastBlock(uint256 _pid, uint256 _lastBlock) external onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        pool.lastBlock = _lastBlock;
    }
    
    /**
     * @dev function used to update all the last reward numbers when the pause/unpaused function is used
     */
    function updateAllLastRewardNumbers() internal {
        for(uint256 i; i < poolLength(); i++){
            changeLastRewardBlock(i);
        }
    }
    
    /**
     * @dev used to pause the pools being able to deposit new lpToken
     */
    function pause() external onlyOwner{
        _pause();
        pausedUpdatePools = true;
        updateAllLastRewardNumbers();
    }
    
    /**
     * @dev used to pause a single pool from being able to deposit new lpToken
     */
    function pausePool(uint256 _pid) external onlyOwner{
        changeLastRewardBlock(_pid);
        pausedPool[_pid] = true;
    }
    
    /**
     * @dev used to unpause the pools being able to deposit new lpToken
     */
    function unpause() external onlyOwner{
        _unpause();
        pausedUpdatePools = false;
        updateAllLastRewardNumbers();
    }
    
    /**
     * @dev used to unpause a single pool
     */
    function unpausePool(uint256 _pid) external onlyOwner{
        changeLastRewardBlock(_pid);
        pausedPool[_pid] = false;
    }
    
    /**
     * @dev used to deposit the lpToken
     * _pid: is the id of the pool that you want to use
     * _amount: is the amount of tokens that you want to deposit
     */
    function deposit(uint256 _pid, uint256 _amount) external whenNotPaused nonReentrant{
        require(!pausedPool[_pid], "Pool: paused");
        require(_amount >= 10000, "Amount: too low");
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.number <= pool.lastBlock, "Last Block of the pool is anterior to the actual block number");
        uint256 fee = (_amount.mul(pool.fee)).div(10000);
        uint256 newAmount = _amount.sub(fee);
        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        if(pool.fee != 0){
            pool.lpToken.safeTransfer(address(pool.vault), fee);
        }
        user.rewardMinusFirst = user.rewardMinusFirst.add((pool.firstRewardsPerShare.mul(newAmount)).div(1e18));
        user.rewardMinusSecond = user.rewardMinusSecond.add((pool.secondRewardsPerShare.mul(newAmount)).div(1e18));
        pool.totalSupply = pool.totalSupply.add(newAmount);
        user.amount = user.amount.add(newAmount);
        emit Deposit(msg.sender, _pid, newAmount); 
    }
    
    /**
     * @dev used to withdraw the lpToken
     * _pid: is the id of the pool that you want to use
     * _amount: is the amount of tokens that you want to deposit
     */
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "Amount: amount exceedes account");
        require(_amount > 0, "Amount: amount is 0");
        updatePool(_pid);
        pool.first.safeTransfer(msg.sender, getPendingFirst(_pid, msg.sender));
        pool.second.safeTransfer(msg.sender, getPendingSecond(_pid, msg.sender));
        user.amount = user.amount.sub(_amount);
        user.rewardMinusFirst = user.amount.mul(pool.firstRewardsPerShare).div(1e18);
        user.rewardMinusSecond = user.amount.mul(pool.secondRewardsPerShare).div(1e18);
        pool.lpToken.safeTransfer(msg.sender, _amount);
        pool.totalSupply = pool.totalSupply.sub(_amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    /**
     * @dev used to withdraw all the lpToken
     * _pid: is the id of the pool that you use
     */
    function withdrawAll(uint256 _pid) external {
        UserInfo memory user = userInfo[_pid][msg.sender];
        withdraw(_pid, user.amount);
    }
    
    /**
     * @dev used to withdraw the lpToken without caring about rewards, EMERGENCY ONLY
     * _pid: is the id of the pool that you want to use
     */
    function emergencyWithdraw(uint256 _pid) external nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        pool.totalSupply = pool.totalSupply.sub(user.amount);
        user.amount = 0;
        user.rewardMinusFirst = 0;
        user.rewardMinusSecond = 0;
    }
    
    /**
     * @dev function used to update the rewards of every investor
     * _pid: is the id of the pool that you want to use
     */
    function updatePool(uint256 _pid) public{
        PoolInfo storage pool = poolInfo[_pid];
        if(pool.totalSupply == 0){
            changeLastRewardBlock(_pid);
            return;
        }
        if(!pausedUpdatePools && !pausedPool[_pid]){
            uint256 firstRewardToDeliver;
            uint256 secondRewardToDeliver;
            if(pool.lastBlock > block.number){
                firstRewardToDeliver = pool.firstPerBlock.mul(block.number.sub(pool.lastRewardBlock));
                secondRewardToDeliver = pool.secondPerBlock.mul(block.number.sub(pool.lastRewardBlock));
            }else{
                firstRewardToDeliver = pool.firstPerBlock.mul(pool.lastBlock.sub(pool.lastRewardBlock));
                secondRewardToDeliver = pool.secondPerBlock.mul(pool.lastBlock.sub(pool.lastRewardBlock));
            }
            pool.firstRewardsPerShare = pool.firstRewardsPerShare.add((firstRewardToDeliver.mul(1e18)).div(pool.totalSupply));
            pool.secondRewardsPerShare = pool.secondRewardsPerShare.add((secondRewardToDeliver.mul(1e18)).div(pool.totalSupply));
        }
        if(pool.lastBlock > block.number){
            changeLastRewardBlock(_pid);
        }else{
            pool.lastRewardBlock = pool.lastBlock;
        }
        
    }
    
    /**
     * @dev function used to withdraw the rewards earned
     * _pid: is the id of the pool that you want to use
     */
    function claimFirst(uint256 _pid) external nonReentrant{
        updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        pool.first.safeTransfer(msg.sender, getPendingFirst(_pid,msg.sender));
        user.rewardMinusFirst = user.amount.mul(pool.firstRewardsPerShare).div(1e18);
        emit Claim(msg.sender, _pid, getPendingFirst(_pid,msg.sender)); 
    }
    
    /**
     * @dev function used to withdraw the rewards earned
     * _pid: is the id of the pool that you want to use
     */
    function claimSecond(uint256 _pid) external nonReentrant{
        updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        pool.second.safeTransfer(msg.sender, getPendingSecond(_pid,msg.sender));
        user.rewardMinusSecond = user.amount.mul(pool.secondRewardsPerShare).div(1e18);
        emit Claim(msg.sender, _pid, getPendingSecond(_pid,msg.sender)); 
    }
    
    /**
     * @dev function used to withdraw the rewards earned
     * _pid: is the id of the pool that you want to use
     */
    function claimBoth(uint256 _pid) external nonReentrant{
        updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        pool.first.safeTransfer(msg.sender, getPendingFirst(_pid,msg.sender));
        user.rewardMinusFirst = user.amount.mul(pool.firstRewardsPerShare).div(1e18);
        emit Claim(msg.sender, _pid, getPendingFirst(_pid,msg.sender)); 
        pool.second.safeTransfer(msg.sender, getPendingSecond(_pid,msg.sender));
        user.rewardMinusSecond = user.amount.mul(pool.secondRewardsPerShare).div(1e18);
        emit Claim(msg.sender, _pid, getPendingSecond(_pid,msg.sender)); 
    }
    
}