/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.6.6;

// SPDX-License-Identifier: MIT
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
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT
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
  constructor() internal {
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
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
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
interface IERC1155 {
  event TransferSingle(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256 _id,
    uint256 _amount
  );

  event TransferBatch(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  event URI(string _amount, uint256 indexed _id);

  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes calldata _data
  ) external;

  function create(
    uint256 _maxSupply,
    uint256 _initialSupply,
    string calldata _uri,
    bytes calldata _data
  ) external returns (uint256 tokenId);

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external;

  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  function setApprovalForAll(address _operator, bool _approved) external;

  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

// SPDX-License-Identifier: MIT
/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role, address account) internal {
    require(!has(role, account), "Roles: account already has role");
    role.bearer[account] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role, address account) internal {
    require(has(role, account), "Roles: account does not have role");
    role.bearer[account] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), "Roles: account is the zero address");
    return role.bearer[account];
  }
}

// SPDX-License-Identifier: MIT
contract PauserRole is Context {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private _pausers;

  constructor() internal {
    _addPauser(_msgSender());
  }

  modifier onlyPauser() {
    require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return _pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(_msgSender());
  }

  function _addPauser(address account) internal {
    _pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    _pausers.remove(account);
    emit PauserRemoved(account);
  }
}

// SPDX-License-Identifier: MIT
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
  /**
   * @dev Emitted when the pause is triggered by a pauser (`account`).
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by a pauser (`account`).
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state. Assigns the Pauser role
   * to the deployer.
   */
  constructor() internal {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused, "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused, "Pausable: not paused");
    _;
  }

  /**
   * @dev Called by a pauser to pause, triggers stopped state.
   */
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Called by a pauser to unpause, returns to normal state.
   */
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

// SPDX-License-Identifier: MIT
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

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
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

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
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

// SPDX-License-Identifier: MIT
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
    // solhint-disable-next-line max-line-length
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
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance =
      token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT
contract PoolTokenWrapper {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  IERC20 public token;

  constructor(IERC20 _erc20Address) public {
    token = IERC20(_erc20Address);
  }

  uint256 private _totalSupply;
  // Objects balances [id][address] => balance
  mapping(uint256 => mapping(address => uint256)) internal _balances;
  mapping(address => uint256) private _accountBalances;
  mapping(uint256 => uint256) private _poolBalances;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOfAccount(address account) public view returns (uint256) {
    return _accountBalances[account];
  }

  function balanceOfPool(uint256 id) public view returns (uint256) {
    return _poolBalances[id];
  }

  function balanceOf(address account, uint256 id) public view returns (uint256) {
    return _balances[id][account];
  }

  function stake(uint256 id, uint256 amount) public virtual {
    _totalSupply = _totalSupply.add(amount);
    _poolBalances[id] = _poolBalances[id].add(amount);
    _accountBalances[msg.sender] = _accountBalances[msg.sender].add(amount);
    _balances[id][msg.sender] = _balances[id][msg.sender].add(amount);
    token.safeTransferFrom(msg.sender, address(this), amount);
  }

  function withdraw(uint256 id, uint256 amount) public virtual {
    _totalSupply = _totalSupply.sub(amount);
    _poolBalances[id] = _poolBalances[id].sub(amount);
    _accountBalances[msg.sender] = _accountBalances[msg.sender].sub(amount);
    _balances[id][msg.sender] = _balances[id][msg.sender].sub(amount);
    token.safeTransfer(msg.sender, amount);
  }

  function transfer(
    uint256 fromId,
    uint256 toId,
    uint256 amount
  ) public virtual {
    _poolBalances[fromId] = _poolBalances[fromId].sub(amount);
    _balances[fromId][msg.sender] = _balances[fromId][msg.sender].sub(amount);

    _poolBalances[toId] = _poolBalances[toId].add(amount);
    _balances[toId][msg.sender] = _balances[toId][msg.sender].add(amount);
  }

  function _rescuePoints(address account, uint256 id) internal {
    uint256 amount = _balances[id][account];

    _totalSupply = _totalSupply.sub(amount);
    _poolBalances[id] = _poolBalances[id].sub(amount);
    _accountBalances[msg.sender] = _accountBalances[msg.sender].sub(amount);
    _balances[id][account] = _balances[id][account].sub(amount);
    token.safeTransfer(account, amount);
  }
}

// SPDX-License-Identifier: MIT
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
  bool private _notEntered;

  constructor() internal {
    // Storing an initial non-zero value makes deployment a bit more
    // expensive, but in exchange the refund on every call to nonReentrant
    // will be lower in amount. Since refunds are capped to a percetange of
    // the total transaction's gas, it is best to keep them low in cases
    // like this one, to increase the likelihood of the full refund coming
    // into effect.
    _notEntered = true;
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
    require(_notEntered, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _notEntered = false;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _notEntered = true;
  }
}

// SPDX-License-Identifier: MIT
contract NftStake is PoolTokenWrapper, Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;
  IERC1155 public nfts;

  struct Card {
    uint256 points;
    uint256 releaseTime;
    uint256 mintFee;
  }

  struct Pool {
    uint256 periodStart;
    uint256 maxStake;
    uint256 rewardRate; // 11574074074000, 1 point per day per staked token
    uint256 feesCollected;
    uint256 spentPoints;
    uint256 controllerShare;
    address artist;
    mapping(address => uint256) lastUpdateTime;
    mapping(address => uint256) points;
    mapping(uint256 => Card) cards;
  }

  uint256 public constant MAX_CONTROLLER_SHARE = 1000;
  uint256 public constant MIN_CARD_POINTS = 1e17;
  address public controller;
  address public rescuer;
  mapping(address => uint256) public pendingWithdrawals;
  mapping(uint256 => Pool) public pools;

  event UpdatedArtist(uint256 poolId, address artist);
  event PoolAdded(uint256 poolId, address artist, uint256 periodStart, uint256 rewardRate, uint256 maxStake);
  event CardAdded(uint256 poolId, uint256 cardId, uint256 points, uint256 mintFee, uint256 releaseTime);
  event Staked(address indexed user, uint256 poolId, uint256 amount);
  event Withdrawn(address indexed user, uint256 poolId, uint256 amount);
  event Transferred(address indexed user, uint256 fromPoolId, uint256 toPoolId, uint256 amount);
  event Redeemed(address indexed user, uint256 poolId, uint256 amount);
  event CardPointsUpdated(uint256 poolId, uint256 cardId, uint256 points);

  modifier updateReward(address account, uint256 id) {
    if (account != address(0)) {
      pools[id].points[account] = earned(account, id);
      pools[id].lastUpdateTime[account] = block.timestamp;
    }
    _;
  }

  modifier poolExists(uint256 id) {
    require(pools[id].rewardRate > 0, "pool does not exists");
    _;
  }

  modifier cardExists(uint256 pool, uint256 card) {
    require(pools[pool].cards[card].points > 0, "card does not exists");
    _;
  }

  constructor(
    address _controller,
    IERC1155 _nftsAddress,
    IERC20 _tokenAddress
  ) public PoolTokenWrapper(_tokenAddress) {
    require(_controller != address(0), "Invalid controller");
    controller = _controller;
    nfts = _nftsAddress;
  }

  function cardMintFee(uint256 pool, uint256 card) public view returns (uint256) {
    return pools[pool].cards[card].mintFee;
  }

  function cardReleaseTime(uint256 pool, uint256 card) public view returns (uint256) {
    return pools[pool].cards[card].releaseTime;
  }

  function cardPoints(uint256 pool, uint256 card) public view returns (uint256) {
    return pools[pool].cards[card].points;
  }

  function earned(address account, uint256 pool) public view returns (uint256) {
    Pool storage p = pools[pool];
    uint256 blockTime = block.timestamp;
    return
      balanceOf(account, pool).mul(blockTime.sub(p.lastUpdateTime[account]).mul(p.rewardRate)).div(1e18).add(
        p.points[account]
      );
  }

  // override PoolTokenWrapper's stake() function
  function stake(uint256 pool, uint256 amount)
    public
    override
    poolExists(pool)
    updateReward(msg.sender, pool)
    whenNotPaused()
    nonReentrant
  {
    Pool memory p = pools[pool];

    require(block.timestamp >= p.periodStart, "pool not open");
    require(amount.add(balanceOf(msg.sender, pool)) <= p.maxStake, "stake exceeds max");

    super.stake(pool, amount);
    emit Staked(msg.sender, pool, amount);
  }

  // override PoolTokenWrapper's withdraw() function
  function withdraw(uint256 pool, uint256 amount)
    public
    override
    poolExists(pool)
    updateReward(msg.sender, pool)
    nonReentrant
  {
    require(amount > 0, "cannot withdraw 0");

    super.withdraw(pool, amount);
    emit Withdrawn(msg.sender, pool, amount);
  }

  // override PoolTokenWrapper's transfer() function
  function transfer(
    uint256 fromPool,
    uint256 toPool,
    uint256 amount
  )
    public
    override
    poolExists(fromPool)
    poolExists(toPool)
    updateReward(msg.sender, fromPool)
    updateReward(msg.sender, toPool)
    whenNotPaused()
    nonReentrant
  {
    Pool memory toP = pools[toPool];

    require(block.timestamp >= toP.periodStart, "pool not open");
    require(amount.add(balanceOf(msg.sender, toPool)) <= toP.maxStake, "stake exceeds max");

    super.transfer(fromPool, toPool, amount);
    emit Transferred(msg.sender, fromPool, toPool, amount);
  }

  function transferAll(uint256 fromPool, uint256 toPool) external nonReentrant {
    transfer(fromPool, toPool, balanceOf(msg.sender, fromPool));
  }

  function exit(uint256 pool) external {
    withdraw(pool, balanceOf(msg.sender, pool));
  }

  function redeem(uint256 pool, uint256 card)
    public
    payable
    poolExists(pool)
    cardExists(pool, card)
    updateReward(msg.sender, pool)
    nonReentrant
  {
    Pool storage p = pools[pool];
    Card memory c = p.cards[card];
    require(block.timestamp >= c.releaseTime, "card not released");
    require(p.points[msg.sender] >= c.points, "not enough points");
    require(msg.value == c.mintFee, "support our artists, send eth");

    if (c.mintFee > 0) {
      uint256 _controllerShare = msg.value.mul(p.controllerShare).div(MAX_CONTROLLER_SHARE);
      uint256 _artistRoyalty = msg.value.sub(_controllerShare);
      require(_artistRoyalty.add(_controllerShare) == msg.value, "problem with fee");

      p.feesCollected = p.feesCollected.add(c.mintFee);
      pendingWithdrawals[controller] = pendingWithdrawals[controller].add(_controllerShare);
      pendingWithdrawals[p.artist] = pendingWithdrawals[p.artist].add(_artistRoyalty);
    }

    p.points[msg.sender] = p.points[msg.sender].sub(c.points);
    p.spentPoints = p.spentPoints.add(c.points);
    nfts.mint(msg.sender, card, 1, "");
    emit Redeemed(msg.sender, pool, c.points);
  }

  function rescuePoints(address account, uint256 pool)
    public
    poolExists(pool)
    updateReward(account, pool)
    nonReentrant
    returns (uint256)
  {
    require(msg.sender == rescuer, "!rescuer");
    Pool storage p = pools[pool];

    uint256 earnedPoints = p.points[account];
    p.spentPoints = p.spentPoints.add(earnedPoints);
    p.points[account] = 0;

    // transfer remaining tokens to the account
    if (balanceOf(account, pool) > 0) {
      _rescuePoints(account, pool);
    }

    emit Redeemed(account, pool, earnedPoints);
    return earnedPoints;
  }

  function setArtist(uint256 pool_, address artist_) public onlyOwner poolExists(pool_) nonReentrant {
    require(artist_ != address(0), "Invalid artist");
    address oldArtist = pools[pool_].artist;
    pendingWithdrawals[artist_] = pendingWithdrawals[artist_].add(pendingWithdrawals[oldArtist]);
    pendingWithdrawals[oldArtist] = 0;
    pools[pool_].artist = artist_;

    emit UpdatedArtist(pool_, artist_);
  }

  function setController(address _controller) public onlyOwner nonReentrant {
    require(_controller != address(0), "Invalid controller");
    pendingWithdrawals[_controller] = pendingWithdrawals[_controller].add(pendingWithdrawals[controller]);
    pendingWithdrawals[controller] = 0;
    controller = _controller;
  }

  function setRescuer(address _rescuer) public onlyOwner nonReentrant {
    rescuer = _rescuer;
  }

  function setControllerShare(uint256 pool, uint256 _controllerShare) public onlyOwner poolExists(pool) nonReentrant {
    require(_controllerShare <= MAX_CONTROLLER_SHARE, "Incorrect controller share");
    pools[pool].controllerShare = _controllerShare;
  }

  function addCard(
    uint256 pool,
    uint256 id,
    uint256 points,
    uint256 mintFee,
    uint256 releaseTime
  ) public onlyOwner poolExists(pool) nonReentrant {
    require(points >= MIN_CARD_POINTS, "Points too small");
    Card storage c = pools[pool].cards[id];
    c.points = points;
    c.releaseTime = releaseTime;
    c.mintFee = mintFee;
    emit CardAdded(pool, id, points, mintFee, releaseTime);
  }

  function createCard(
    uint256 pool,
    uint256 supply,
    uint256 points,
    uint256 mintFee,
    uint256 releaseTime
  ) public onlyOwner poolExists(pool) nonReentrant returns (uint256) {
    require(points >= MIN_CARD_POINTS, "Points too small");
    uint256 tokenId = nfts.create(supply, 0, "", "");
    require(tokenId > 0, "ERC1155 create did not succeed");

    Card storage c = pools[pool].cards[tokenId];
    c.points = points;
    c.releaseTime = releaseTime;
    c.mintFee = mintFee;
    emit CardAdded(pool, tokenId, points, mintFee, releaseTime);
    return tokenId;
  }

  function createPool(
    uint256 id,
    uint256 periodStart,
    uint256 maxStake,
    uint256 rewardRate,
    uint256 controllerShare,
    address artist
  ) public onlyOwner nonReentrant returns (uint256) {
    require(rewardRate > 0, "Invalid rewardRate");
    require(pools[id].rewardRate == 0, "pool exists");
    require(artist != address(0), "Invalid artist");
    require(controllerShare <= MAX_CONTROLLER_SHARE, "Incorrect controller share");

    Pool storage p = pools[id];

    p.periodStart = periodStart;
    p.maxStake = maxStake;
    p.rewardRate = rewardRate;
    p.controllerShare = controllerShare;
    p.artist = artist;

    emit PoolAdded(id, artist, periodStart, rewardRate, maxStake);
  }

  function withdrawFee() public nonReentrant {
    uint256 amount = pendingWithdrawals[msg.sender];
    require(amount > 0, "nothing to withdraw");
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }

  // For development and QA
  function assignPointsTo(
    uint256 pool_,
    address tester_,
    uint256 points_
  ) public onlyOwner poolExists(pool_) nonReentrant returns (uint256) {
    Pool storage p = pools[pool_];
    p.points[tester_] = points_;

    // rescue continues
    return p.points[tester_];
  }

  /**
   * @dev Updates card points
   * @param poolId_ uint256 ID of the pool
   * @param cardId_ uint256 ID of the card to update
   * @param points_ uint256 new "points" value
   */
  function updateCardPoints(
    uint256 poolId_,
    uint256 cardId_,
    uint256 points_
  ) public onlyOwner poolExists(poolId_) cardExists(poolId_, cardId_) nonReentrant {
    require(points_ >= MIN_CARD_POINTS, "Points too small");
    Card storage c = pools[poolId_].cards[cardId_];
    c.points = points_;
    emit CardPointsUpdated(poolId_, cardId_, points_);
  }
}

// SPDX-License-Identifier: MIT
contract EddaNftStake is NftStake {
  constructor(
    address _controller,
    IERC1155 _nftsAddress,
    IERC20 _tokenAddress
  ) public NftStake(_controller, _nftsAddress, _tokenAddress) {}
}