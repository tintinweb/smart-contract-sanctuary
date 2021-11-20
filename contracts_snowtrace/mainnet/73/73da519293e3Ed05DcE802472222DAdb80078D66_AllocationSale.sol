/**
 *Submitted for verification at snowtrace.io on 2021-11-19
*/

// File: @openzeppelin/contracts/utils/Address.sol



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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/AllocationSale.sol


pragma solidity 0.8.3;



contract AllocationSale {
  using Address for address;

  uint256 public immutable max_base_allocated;
  uint256 public immutable token_per_base;
  uint256 public immutable withdrawal_unlock_time;
  uint256 public immutable finish_unlock_time;
  uint256 public immutable deposit_lock_time;
  uint256 public immutable start_time;
  uint256 public immutable max_allowed_base;
  uint256 public immutable min_allowed_base;

  IERC20 public immutable baseToken;
  IERC20 public immutable token;

  address payable public immutable dev_address;

  uint256 public base_deposited;
  uint256 public total_tokens_received;
  bool public sale_finished;

  mapping(address => uint256) public shares;
  mapping(address => uint256) public deposits;
  mapping(address => bool) public whitelist;

  // Events
  event Deposit(address indexed depositer, uint256 amount);
  event Withdraw(address indexed withdrawer, uint256 amount);
  event Finish(uint256 amount);

  /**
   * Allocation Sale Contract
   * Distribute a token that is priced on base currency of a network
   * Set distributed amount, price,
   * Withdrawal unlocks at a certain timestamp
   * Depositing locks at a certain timestamp
   * Finish ends the sale and transfers the gathered amount
   * Finish unlocks at a certain timestamp
   **/
  constructor(address acceptedToken, address _baseToken) {
    require(acceptedToken.isContract(), "The accepted token address must be a deployed contract!");
    require(_baseToken.isContract(), "The base token address must be a deployed contract!");

    max_base_allocated = 510000000000;
    token_per_base = 13333334; // Ceil for 0.075$
    withdrawal_unlock_time = 1640379600;
    finish_unlock_time = 1637614800;
    deposit_lock_time = 1637528400;
    start_time = 1637359200;
    max_allowed_base = 600000000;
    min_allowed_base = 50000000;

    baseToken = IERC20(_baseToken);
    token = IERC20(acceptedToken);
    dev_address = payable(msg.sender);

    whitelist[msg.sender] = true;
    sale_finished = false;
  }

  // Deposit a base token
  function deposit(uint256 amount) public {
    require(!sale_finished, "The sale has been finished.");
    require(block.timestamp > start_time, "The sale has not been started yet.");
    require(block.timestamp < deposit_lock_time, "Deposits have been closed.");
    require(amount >= min_allowed_base, "Insufficent allocation amount.");
    require(whitelist[msg.sender], "Not on the whitelist");

    uint256 previous_deposit = deposits[msg.sender];
    // If the user tries to allocate more than maximum allocation amount
    // dont allow
    if ((previous_deposit + amount) > max_allowed_base) {
      amount = max_allowed_base - previous_deposit;
    }
    deposits[msg.sender] += amount;
    base_deposited += amount;
    uint256 tokens_received = (amount * token_per_base) / 1e6;
    shares[msg.sender] += tokens_received;

    baseToken.transferFrom(msg.sender, address(this), amount);
    emit Deposit(msg.sender, amount);
  }

  // Withdraw distributed token
  function withdraw() public {
    require(block.timestamp > withdrawal_unlock_time, "Withdrawals have not been started yet.");
    require(deposits[msg.sender] > 0, "Deposit amount is zero.");
    require(shares[msg.sender] > 0, "Share amount is zero.");
    require(whitelist[msg.sender], "Not on the whitelist");

    uint256 share = shares[msg.sender];
    shares[msg.sender] = 0;
    token.transfer(msg.sender, share);
    emit Withdraw(msg.sender, share);
  }

  /// @dev Finish the presale
  function finish() public {
    require(block.timestamp > finish_unlock_time, "Cannot end the presale yet.");
    require(!sale_finished, "The sale has finished.");
    require(whitelist[msg.sender], "Not on the whitelist");

    uint256 base_allocated = base_deposited;
    sale_finished = true;

    // Send allocated base to the dev
    if (base_allocated > max_base_allocated) {
      base_allocated = max_base_allocated;
    }
    baseToken.transfer(dev_address, base_allocated);
    emit Finish(base_allocated);
  }

  function getBalance() public view returns (uint256) {
    return baseToken.balanceOf(address(this));
  }

  /// @dev Withdraw the remaining funds if any
  function withdrawFunds() public {
    require(block.timestamp > (finish_unlock_time + 5 days), "Cannot withdraw the funds yet.");
    require(msg.sender == dev_address, "Caller is not dev.");
    uint256 balance = baseToken.balanceOf(address(this));
    baseToken.transfer(dev_address, balance);
    balance = token.balanceOf(address(this));
    token.transfer(dev_address, balance);
  }

  function addWhitelist(address[] memory eligible) public {
    require(msg.sender == dev_address, "Caller is not dev.");

    for (uint256 i = 0; i < eligible.length; i++) {
      whitelist[eligible[i]] = true;
    }
  }
}