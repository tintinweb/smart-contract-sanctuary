/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// File: contracts\Token\ERC20\IERC20.sol

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

// File: contracts\OpenZeppelin\Address.sol


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

// File: contracts\OpenZeppelin\SafeERC20.sol


pragma solidity ^0.8.0;



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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\MultiSigWallet\MultiSigWallet.sol

pragma solidity ^0.8.0;

/// @title Multisignature wallet by TOZEX inspired by Gnosis Multisignature project fir which we added new functionalities like transaction countdown validation .
/// @author Tozex company



contract MultiSigWallet {
  using SafeERC20 for IERC20;

  uint constant public MAX_OWNER_COUNT = 10;


  event Confirmation(address indexed sender, uint indexed transactionId);
  event Revocation(address indexed sender, uint indexed transactionId);
  event Submission(uint indexed transactionId);
  event Execution(uint indexed transactionId);
  event ExecutionFailure(uint indexed transactionId);
  event Deposit(address indexed sender, address indexed token, uint value);


  mapping(uint => Transaction) public transactions;
  mapping(uint => mapping(address => bool)) public confirmations;
  mapping(address => bool) public isOwner;
  address[] public owners;
  uint public required;
  uint public transactionCount;


  struct Transaction {
    address payable destination;
    address token;
    uint value;
    bytes data;
    bool executed;
    uint confirmTimestamp;
    uint txTimestamp;
  }

  modifier onlyWallet() {
    require(msg.sender == address(this));
    _;
  }

  modifier ownerDoesNotExist(address owner) {
    require(!isOwner[owner]);
    _;
  }

  modifier ownerExists(address owner) {
    require(isOwner[owner]);
    _;
  }

  modifier transactionExists(uint transactionId) {
    require(transactions[transactionId].destination != address(0));
    _;
  }

  modifier confirmed(uint transactionId, address owner) {
    require(confirmations[transactionId][owner]);
    _;
  }

  modifier notConfirmed(uint transactionId, address owner) {
    require(!confirmations[transactionId][owner]);
    _;
  }

  modifier notExecuted(uint transactionId) {
    require(!transactions[transactionId].executed);
    _;
  }

  modifier notNull(address _address) {
    require(_address != address(0));
    _;
  }

  modifier validRequirement(uint ownerCount, uint _required) {
    require((ownerCount <= MAX_OWNER_COUNT) || (required <= ownerCount) || (_required != 0) || (ownerCount != 0));
    _;
  }

  /** 
   * @dev Fallback function allows to deposit ether.
   */
  receive() external payable {
    if (msg.value > 0)
      emit Deposit(msg.sender, address(0), msg.value);
  }
  
  /**
   * Public functions
   * @dev Contract constructor sets initial owners and required number of confirmations.
   * @param _owners List of initial owners.
   * @param _required Number of required confirmations.
   */
  constructor (address[] memory _owners, uint _required) public validRequirement(_owners.length, _required) {
    for (uint i = 0; i < _owners.length; i++) {
      require(isOwner[_owners[i]] || _owners[i] != address(0));
      isOwner[_owners[i]] = true;
    }
    owners = _owners;
    required = _required;


  }

  function deposit(address token, uint256 amount) external {
    require(token != address(0) , "invalid token");
    require(amount > 0 , "invalid amount");
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    emit Deposit(msg.sender, token, amount);
  }
  /**
   * @dev Allows an owner to submit and confirm a transaction.
   * @param destination Transaction target address.
   * @param value Transaction ether value.
   * @param data Transaction data payload.
   */
  function submitTransaction(address payable destination, address token, uint value, bytes memory data, uint confirmTimestamp) public returns (uint transactionId) {
    uint txTimestamp = _getNow();
    transactionId = addTransaction(destination, token, value, data, confirmTimestamp, txTimestamp);
    confirmTransaction(transactionId);
  }
 
  /**
   * @dev Allows an owner to confirm a transaction.
   * @param transactionId Transaction ID.
   */
  function confirmTransaction(uint transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
    require(_getNow() < transactions[transactionId].txTimestamp + transactions[transactionId].confirmTimestamp * 1 seconds || transactions[transactionId].confirmTimestamp == 0);
    confirmations[transactionId][msg.sender] = true;
    emit Confirmation(msg.sender, transactionId);
    executeTransaction(transactionId);
  }


  /**
   * @dev Allows anyone to execute a confirmed transaction.
   * @param transactionId Transaction ID.
   */
  function executeTransaction(uint transactionId) internal notExecuted(transactionId) {
    if (isConfirmed(transactionId)) {
      Transaction storage txn = transactions[transactionId];
      require(getTokenBalance(txn.token) >= txn.value, "not enough amount to withdraw");
      txn.executed = true;
      if(txn.token == address(0)) {
        (bool transferSuccess,) =txn.destination.call{value: txn.value}(txn.data);
        if (transferSuccess)
          emit Execution(transactionId);
        else {
          emit ExecutionFailure(transactionId);
          txn.executed = false;
        }
      } else {
        IERC20(txn.token).safeTransfer(txn.destination, txn.value);
        emit Execution(transactionId);
      }
    }
  }
  
  /**
   * @dev Returns the confirmation status of a transaction.
   * @param transactionId Transaction ID.
   */
  function isConfirmed(uint transactionId) public returns (bool) {
    uint count = 0;
    for (uint i = 0; i < owners.length; i++) {
      if (confirmations[transactionId][owners[i]])
        count += 1;
      if (count == required)
        return true;
    }
  }

  /**
   * Internal functions
   *
   * @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
   * @param destination Transaction target address.
   * @param value Transaction ether value.
   * @param data Transaction data payload.
   */
  function addTransaction(address payable destination, address token, uint value, bytes memory data, uint confirmTimestamp, uint txTimestamp) internal notNull(destination) returns (uint transactionId) {
    transactionId = transactionCount;
    transactions[transactionId] = Transaction({
      destination : destination,
      token: token,
      value : value,
      data : data,
      executed : false,
      confirmTimestamp : confirmTimestamp,
      txTimestamp : txTimestamp
      });
    transactionCount += 1;
    emit Submission(transactionId);
  }


  /**
   * Web3 call functions
   *
   * @dev Returns number of confirmations of a transaction.
   * @param transactionId Transaction ID.
   */
  function getConfirmationCount(uint transactionId) public returns (uint count) {
    for (uint i = 0; i < owners.length; i++)
      if (confirmations[transactionId][owners[i]])
        count += 1;
  }

  /**
   * @dev Returns total number of transactions after filers are applied.
   * @param pending Include pending transactions.
   * @param executed Include executed transactions.
   */
  function getTransactionCount(bool pending, bool executed) public returns (uint count) {
    for (uint i = 0; i < transactionCount; i++)
      if (pending && !transactions[i].executed || executed && transactions[i].executed)
        count += 1;
  }

  /**
   * @dev Returns the balance of token amount in this address.
   * @param token The address of token contract
   */
  function getTokenBalance(address token) internal view returns (uint count) {
    if(token == address(0)) {
      return address(this).balance;
    } else {
      return IERC20(token).balanceOf(address(this));
    }
  }


  /**
   * @dev Returns array with owner addresses, which confirmed transaction.
   * @param transactionId Transaction ID.
   */
  function getConfirmations(uint transactionId) public returns (address[] memory _confirmations) {
    address[] memory confirmationsTemp = new address[](owners.length);
    uint count = 0;
    uint i;
    for (i = 0; i < owners.length; i++)
      if (confirmations[transactionId][owners[i]]) {
        confirmationsTemp[count] = owners[i];
        count += 1;
      }
    _confirmations = new address[](count);
    for (i = 0; i < count; i++)
      _confirmations[i] = confirmationsTemp[i];
  }

  /**
   * @dev Returns list of transaction IDs in defined range.
   * @param from Index start position of transaction array.
   * @param to Index end position of transaction array.
   * @param pending Include pending transactions.
   * @param executed Include executed transactions.
   */
  function getTransactionIds(uint from, uint to, bool pending, bool executed) public returns (uint[] memory _transactionIds)
  {
    uint[] memory transactionIdsTemp = new uint[](transactionCount);
    uint count = 0;
    uint i;
    for (i = 0; i < transactionCount; i++)
      if (pending && !transactions[i].executed
      || executed && transactions[i].executed)
      {
        transactionIdsTemp[count] = i;
        count += 1;
      }
    _transactionIds = new uint[](to - from);
    for (i = from; i < to; i++)
      _transactionIds[i - from] = transactionIdsTemp[i];
  }

  function _getNow() internal view returns (uint256) {
      return block.timestamp;
  }

}