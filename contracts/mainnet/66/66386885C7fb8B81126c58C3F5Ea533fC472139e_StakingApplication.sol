// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;


// 
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

// 
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

// 
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

// 
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

// 
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * Credit: https://github.com/OpenZeppelin/openzeppelin-upgrades/blob/master/packages/core/contracts/Initializable.sol
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// 
/**
 * @notice An account contracted created for each user address.
 * @dev Anyone can directy deposit assets to the Account contract.
 * @dev Only operators can withdraw asstes or perform operation from the Account contract.
 */
contract Account is Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Asset is withdrawn from the Account.
     */
    event Withdrawn(address indexed tokenAddress, address indexed targetAddress, uint256 amount);

    /**
     * @dev Spender is allowed to spend an asset.
     */
    event Approved(address indexed tokenAddress, address indexed targetAddress, uint256 amount);

    /**
     * @dev A transaction is invoked on the Account.
     */
    event Invoked(address indexed targetAddress, uint256 value, bytes data);

    address public owner;
    mapping(address => bool) public admins;
    mapping(address => bool) public operators;

    /**
     * @dev Initializes the owner, admin and operator roles.
     * @param _owner Address of the contract owner
     * @param _initialAdmins The list of addresses that are granted the admin role.
     */
    function initialize(address _owner, address[] memory _initialAdmins) public initializer {
        owner = _owner;
        // Grant the admin role to the initial admins
        for (uint256 i = 0; i < _initialAdmins.length; i++) {
            admins[_initialAdmins[i]] = true;
        }
    }

    /**
     * @dev Throws if called by any account that does not have operator role.
     */
    modifier onlyOperator() {
        require(isOperator(msg.sender), "not operator");
        _;
    }

    /**
     * @dev Transfers the ownership of the account to another address.
     * The new owner can be an zero address which means renouncing the ownership.
     * @param _owner New owner address
     */
    function transferOwnership(address _owner) public {
        require(msg.sender == owner, "not owner");
        owner = _owner;
    }

    /**
     * @dev Grants admin role to a new address.
     * @param _account New admin address.
     */
    function grantAdmin(address _account) public {
        require(msg.sender == owner, "not owner");
        require(!admins[_account], "already admin");

        admins[_account] = true;
    }

    /**
     * @dev Revokes the admin role from an address. Only owner can revoke admin.
     * @param _account The admin address to revoke.
     */
    function revokeAdmin(address _account) public {
        require(msg.sender == owner, "not owner");
        require(admins[_account], "not admin");

        admins[_account] = false;
    }

    /**
     * @dev Grants operator role to a new address. Only owner or admin can grant operator roles.
     * @param _account The new operator address.
     */
    function grantOperator(address _account) public {
        require(msg.sender == owner || admins[msg.sender], "not admin");
        require(!operators[_account], "already operator");

        operators[_account] = true;
    }

    /**
     * @dev Revoke operator role from an address. Only owner or admin can revoke operator roles.
     * @param _account The operator address to revoke.
     */
    function revokeOperator(address _account) public {
        require(msg.sender == owner || admins[msg.sender], "not admin");
        require(operators[_account], "not operator");

        operators[_account] = false;
    }

    /**
     * @dev Allows Account contract to receive ETH.
     */
    receive() payable external {}

    /**
     * @dev Checks whether a user is an operator of the contract.
     * Since admin role can grant operator role and owner can grant admin role, we treat both
     * admins and owner as operators!
     * @param userAddress Address to check whether it's an operator.
     */
    function isOperator(address userAddress) public view returns (bool) {
        return userAddress == owner || admins[userAddress] || operators[userAddress];
    }

    /**
     * @dev Withdraws ETH from the Account contract. Only operators can withdraw ETH.
     * @param targetAddress Address to send the ETH to.
     * @param amount Amount of ETH to withdraw.
     */
    function withdraw(address payable targetAddress, uint256 amount) public onlyOperator {
        targetAddress.transfer(amount);
        // Use address(-1) to represent ETH.
        emit Withdrawn(address(-1), targetAddress, amount);
    }

    /**
     * @dev Withdraws ERC20 token from the Account contract. Only operators can withdraw ERC20 tokens.
     * @param tokenAddress Address of the ERC20 to withdraw.
     * @param targetAddress Address to send the ERC20 to.
     * @param amount Amount of ERC20 token to withdraw.
     */
    function withdrawToken(address tokenAddress, address targetAddress, uint256 amount) public onlyOperator {
        IERC20(tokenAddress).safeTransfer(targetAddress, amount);
        emit Withdrawn(tokenAddress, targetAddress, amount);
    }

    /**
     * @dev Withdraws ERC20 token from the Account contract. If the Account contract does not have sufficient balance,
     * try to withdraw from the owner's address as well. This is useful if users wants to keep assets in their own wallet
     * by setting adequate allowance to the Account contract.
     * @param tokenAddress Address of the ERC20 to withdraw.
     * @param targetAddress Address to send the ERC20 to.
     * @param amount Amount of ERC20 token to withdraw.
     */
    function withdrawTokenFallThrough(address tokenAddress, address targetAddress, uint256 amount) public onlyOperator {
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        // If we have enough token balance, send the token directly.
        if (tokenBalance >= amount) {
            IERC20(tokenAddress).safeTransfer(targetAddress, amount);
            emit Withdrawn(tokenAddress, targetAddress, amount);
        } else {
            IERC20(tokenAddress).safeTransferFrom(owner, targetAddress, amount.sub(tokenBalance));
            IERC20(tokenAddress).safeTransfer(targetAddress, tokenBalance);
            emit Withdrawn(tokenAddress, targetAddress, amount);
        }
    }

    /**
     * @dev Allows the spender address to spend up to the amount of token.
     * @param tokenAddress Address of the ERC20 that can spend.
     * @param targetAddress Address which can spend the ERC20.
     * @param amount Amount of ERC20 that can be spent by the target address.
     */
    function approveToken(address tokenAddress, address targetAddress, uint256 amount) public onlyOperator {
        IERC20(tokenAddress).safeApprove(targetAddress, 0);
        IERC20(tokenAddress).safeApprove(targetAddress, amount);
        emit Approved(tokenAddress, targetAddress, amount);
    }

    /**
     * @notice Performs a generic transaction on the Account contract.
     * @param target The address for the target contract.
     * @param value The value of the transaction.
     * @param data The data of the transaction.
     */
    function invoke(address target, uint256 value, bytes memory data) public onlyOperator returns (bytes memory result) {
        bool success;
        (success, result) = target.call{value: value}(data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit Invoked(target, value, data);
    }
}

// 
/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 *
 * Credit: https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/upgradeability/Proxy.sol
 */
abstract contract Proxy {

  /**
   * @dev Receive function.
   * Implemented entirely in `_fallback`.
   */
  receive () payable external {
    _fallback();
  }

  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal virtual view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// 
/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 *
 * Credit: https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/upgradeability/BaseUpgradeabilityProxy.sol
 */
contract BaseUpgradeabilityProxy is Proxy {
    /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
    event Upgraded(address indexed implementation);

    /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
    function _implementation() internal override view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            "Implementation not set"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
        emit Upgraded(newImplementation);
    }
}

// 
/**
 * @title AdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 * Credit: https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/upgradeability/BaseAdminUpgradeabilityProxy.sol
 */
contract AdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, address _admin) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    _setImplementation(_logic);
    _setAdmin(_admin);
  }

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function changeImplementation(address newImplementation) external ifAdmin {
    _setImplementation(newImplementation);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }
}

// 
/**
 * @notice Factory of Account contracts.
 */
contract AccountFactory {

    /**
     * @dev A new Account contract is created.
     */
    event AccountCreated(address indexed userAddress, address indexed accountAddress);

    address public governance;
    address public accountBase;
    mapping(address => address) public accounts;

    /**
     * @dev Constructor for Account Factory.
     * @param _accountBase Base account implementation.
     */
    constructor(address _accountBase) public {
        require(_accountBase != address(0x0), "account base not set");
        governance = msg.sender;
        accountBase = _accountBase;
    }

    /**
     * @dev Updates the base account implementation. Base account must be set.
     */
    function setAccountBase(address _accountBase) public {
        require(msg.sender == governance, "not governance");
        require(_accountBase != address(0x0), "account base not set");

        accountBase = _accountBase;
    }

    /**
     * @dev Updates the govenance address. Governance can be empty address which means
     * renouncing the governance.
     */
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "not governance");
        governance = _governance;
    }

    /**
     * @dev Creates a new Account contract for the caller.
     * Users can create multiple accounts by invoking this method multiple times. However,
     * only the latest one is actively tracked and used by the platform.
     * @param _initialAdmins The list of addresses that are granted the admin role.
     */
    function createAccount(address[] memory _initialAdmins) public returns (Account) {
        AdminUpgradeabilityProxy proxy = new AdminUpgradeabilityProxy(accountBase, msg.sender);
        Account account = Account(address(proxy));
        account.initialize(msg.sender, _initialAdmins);
        accounts[msg.sender] = address(account);

        emit AccountCreated(msg.sender, address(account));

        return account;
    }
}

// 
/**
 * @notice Interface for ERC20 token which supports minting new tokens.
 */
interface IERC20Mintable is IERC20 {
    
    function mint(address _user, uint256 _amount) external;

}

// 
/**
 * @notice Interface for Strategies.
 */
interface IStrategy {

    /**
     * @dev Returns the token address that the strategy expects.
     */
    function want() external view returns (address);

    /**
     * @dev Returns the total amount of tokens deposited in this strategy.
     */
    function balanceOf() external view returns (uint256);

    /**
     * @dev Deposits the token to start earning.
     */
    function deposit() external;

    /**
     * @dev Withdraws partial funds from the strategy.
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Withdraws all funds from the strategy.
     */
    function withdrawAll() external returns (uint256);
    
    /**
     * @dev Claims yield and convert it back to want token.
     */
    function harvest() external;
}

// 
/**
 * @notice Interface for controller.
 */
interface IController {
    
    function rewardToken() external returns (address);
}

// 
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

// 
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

// 
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// 
/**
 * @notice YEarn's style vault which earns yield for a specific token.
 */
contract Vault is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;
    address public governance;
    address public strategy;

    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 shareAmount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount, uint256 shareAmount);

    constructor(string memory _name, string memory _symbol, address _token) public ERC20(_name, _symbol) {
        token = IERC20(_token);
        governance = msg.sender;
    }

    /**
     * @dev Returns the total balance in both vault and strategy.
     */
    function balance() public view returns (uint256) {
        return strategy == address(0x0) ? token.balanceOf(address(this)) :
            token.balanceOf(address(this)).add(IStrategy(strategy).balanceOf());
    }

    /**
     * @dev Updates the govenance address.
     */
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "not governance");
        governance = _governance;
    }

    /**
     * @dev Updates the active strategy of the vault.
     */
    function setStrategy(address _strategy) public {
        require(msg.sender == governance, "not governance");
        // This also ensures that _strategy must be a valid strategy contract.
        require(address(token) == IStrategy(_strategy).want(), "different token");

        // If the vault has an existing strategy, withdraw all funds from it.
        if (strategy != address(0x0)) {
            IStrategy(strategy).withdrawAll();
        }

        strategy = _strategy;
        // Starts earning once a new strategy is set.
        earn();
    }

    /**
     * @dev Starts earning and deposits all current balance into strategy.
     */
    function earn() public {
        require(strategy != address(0x0), "no strategy");
        uint256 _bal = token.balanceOf(address(this));
        token.safeTransfer(strategy, _bal);
        IStrategy(strategy).deposit();
    }

    /**
     * @dev Deposits all balance to the vault.
     */
    function depositAll() public virtual {
        deposit(token.balanceOf(msg.sender));
    }

    /**
     * @dev Deposit some balance to the vault.
     */
    function deposit(uint256 _amount) public virtual {
        require(_amount > 0, "zero amount");
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);

        emit Deposited(msg.sender, address(token), _amount, shares);
    }

    /**
     * @dev Withdraws all balance out of the vault.
     */
    function withdrawAll() public virtual {
        withdraw(balanceOf(msg.sender));
    }

    /**
     * @dev Withdraws some balance out of the vault.
     */
    function withdraw(uint256 _shares) public virtual {
        require(_shares > 0, "zero amount");
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            // Ideally this should not happen. Put here for extra safety.
            require(strategy != address(0x0), "no strategy");
            IStrategy(strategy).withdraw(_withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        token.safeTransfer(msg.sender, r);
        emit Withdrawn(msg.sender, address(token), r, _shares);
    }

    /**
     * @dev Used to salvage any token deposited into the vault by mistake.
     * @param _tokenAddress Token address to salvage.
     * @param _amount Amount of token to salvage.
     */
    function salvage(address _tokenAddress, uint256 _amount) public {
        require(msg.sender == governance, "not governance");
        require(_tokenAddress != address(token), "cannot salvage");
        require(_amount > 0, "zero amount");
        IERC20(_tokenAddress).safeTransfer(governance, _amount);
    }

    /**
     * @dev Returns the number of vault token per share is worth.
     */
    function getPricePerFullShare() public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return balance().mul(1e18).div(totalSupply());
    }
}

// 
/**
 * @notice A vault with rewards.
 */
contract RewardedVault is Vault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public controller;
    uint256 public constant DURATION = 7 days;      // Rewards are vested for a fixed duration of 7 days.
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public claims;

    event RewardAdded(address indexed rewardToken, uint256 rewardAmount);
    event RewardPaid(address indexed rewardToken, address indexed user, uint256 rewardAmount);

    constructor(string memory _name, string memory _symbol, address _controller, address _vaultToken) public Vault(_name, _symbol, _vaultToken) {
        require(_controller != address(0x0), "controller not set");

        controller = _controller;
    }

    /**
     * @dev Updates the controller address. Controller is responsible for reward distribution.
     */
    function setController(address _controller) public {
        require(msg.sender == governance, "not governance");
        require(_controller != address(0x0), "controller not set");

        controller = _controller;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address _account) public view returns (uint256) {
        return
            balanceOf(_account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_account]))
                .div(1e18)
                .add(rewards[_account]);
    }

    function deposit(uint256 _amount) public virtual override updateReward(msg.sender) {
        super.deposit(_amount);
    }

    function depositAll() public virtual override updateReward(msg.sender) {
        super.depositAll();
    }

    function withdraw(uint256 _shares) public virtual override updateReward(msg.sender) {
        super.withdraw(_shares);
    }

    function withdrawAll() public virtual override updateReward(msg.sender) {
        super.withdrawAll();
    }

    /**
     * @dev Withdraws all balance and all rewards from the vault.
     */
    function exit() external {
        withdrawAll();
        claimReward();
    }

    /**
     * @dev Claims all rewards from the vault.
     */
    function claimReward() public updateReward(msg.sender) returns (uint256) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            claims[msg.sender] = claims[msg.sender].add(reward);
            rewards[msg.sender] = 0;
            address rewardToken = IController(controller).rewardToken();
            IERC20(rewardToken).safeTransfer(msg.sender, reward);
            emit RewardPaid(rewardToken, msg.sender, reward);
        }

        return reward;
    }

    /**
     * @dev Notifies the vault that new reward is added. All rewards will be distributed linearly in 7 days.
     * @param _reward Amount of reward token to add.
     */
    function notifyRewardAmount(uint256 _reward) public updateReward(address(0)) {
        require(msg.sender == controller, "not controller");

        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = _reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);

        emit RewardAdded(IController(controller).rewardToken(), _reward);
    }
}

// 
/**
 * @notice Controller for vaults.
 */
contract Controller is IController {
    using SafeMath for uint256;

    address public override rewardToken;
    address public governance;
    address public reserve;
    uint256 public numVaults;
    mapping(uint256 => address) public vaults;

    constructor(address _rewardToken) public {
        require(_rewardToken != address(0x0), "reward token not set");
        
        governance = msg.sender;
        reserve = msg.sender;
        rewardToken = _rewardToken;
    }

    /**
     * @dev Updates the govenance address.
     */
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "not governance");
        governance = _governance;
    }

    /**
     * @dev Updates the rewards token.
     */
    function setRewardToken(address _rewardToken) public {
        require(msg.sender == governance, "not governance");
        require(_rewardToken != address(0x0), "reward token not set");

        rewardToken = _rewardToken;
    }

    /**
     * @dev Updates the reserve address.
     */
    function setReserve(address _reserve) public {
        require(msg.sender == governance, "not governance");
        require(_reserve != address(0x0), "reserve not set");

        reserve = _reserve;
    }

    /**
     * @dev Add a new vault to the controller.
     */
    function addVault(address _vault) public {
        require(msg.sender == governance, "not governance");
        require(_vault != address(0x0), "vault not set");

        vaults[numVaults++] = _vault;
    }

    /**
     * @dev Add new rewards to a rewarded vault.
     * @param _vaultId ID of the vault to have reward.
     * @param _rewardAmount Amount of the reward token to add.
     */
    function addRewards(uint256 _vaultId, uint256 _rewardAmount) public {
        require(msg.sender == governance, "not governance");
        require(vaults[_vaultId] != address(0x0), "vault not exist");
        require(_rewardAmount > 0, "zero amount");

        address vault = vaults[_vaultId];
        IERC20Mintable(rewardToken).mint(vault, _rewardAmount);
        // Mint 40% of tokens to governance.
        IERC20Mintable(rewardToken).mint(reserve, _rewardAmount.mul(2).div(5));
        RewardedVault(vault).notifyRewardAmount(_rewardAmount);
    }

    /**
     * @dev Helpher function to earn in the vault.
     * @param _vaultId ID of the vault to earn.
     */
    function earn(uint256 _vaultId) public {
        require(vaults[_vaultId] != address(0x0), "vault not exist");
        RewardedVault(vaults[_vaultId]).earn();
    }

    /**
     * @dev Helper function to earn in all vaults.
     */
    function earnAll() public {
        for (uint256 i = 0; i < numVaults; i++) {
            RewardedVault(vaults[i]).earn();
        }
    }

    /**
     * @dev Helper function to harvest in the vault.
     * @param _vaultId ID of the vault to harvest.
     */
    function harvest(uint256 _vaultId) public {
        require(vaults[_vaultId] != address(0x0), "vault not exist");
        address strategy = RewardedVault(vaults[_vaultId]).strategy();
        if (strategy != address(0x0)) {
            IStrategy(strategy).harvest();
        }
    }

    /**
     * @dev Helper function to harvest in all vaults.
     */
    function harvestAll() public {
        for (uint256 i = 0; i < numVaults; i++) {
            address strategy = RewardedVault(vaults[i]).strategy();
            if (strategy != address(0x0)) {
                IStrategy(strategy).harvest();
            }
        }
    }
}

// 
/**
 * @dev Application to help stake and get rewards.
 */
contract StakingApplication {
    using SafeMath for uint256;

    event Staked(address indexed staker, uint256 indexed vaultId, address indexed token, uint256 amount);
    event Unstaked(address indexed staker, uint256 indexed vaultId, address indexed token, uint256 amount);
    event Claimed(address indexed staker, uint256 indexed vaultId, address indexed token, uint256 amount);

    address public governance;
    address public accountFactory;
    Controller public controller;

    constructor(address _accountFactory, address _controller) public {
        require(_accountFactory != address(0x0), "account factory not set");
        require(_controller != address(0x0), "controller not set");
        
        governance = msg.sender;
        accountFactory = _accountFactory;
        controller = Controller(_controller);
    }

    /**
     * @dev Updates the govenance address.
     */
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "not governance");
        governance = _governance;
    }

    /**
     * @dev Updates the account factory.
     */
    function setAccountFactory(address _accountFactory) public {
        require(msg.sender == governance, "not governance");
        require(_accountFactory != address(0x0), "account factory not set");

        accountFactory = _accountFactory;
    }

    /**
     * @dev Updates the controller address.
     */
    function setController(address _controller) public {
        require(msg.sender == governance, "not governance");
        require(_controller != address(0x0), "controller not set");

        controller = Controller(_controller);
    }

    /**
     * @dev Retrieve the active account of the user.
     */
    function _getAccount() internal view returns (Account) {
        address _account = AccountFactory(accountFactory).accounts(msg.sender);
        require(_account != address(0x0), "no account");
        Account account = Account(payable(_account));
        require(account.isOperator(address(this)), "not operator");

        return account;
    }

    /**
     * @dev Stake token into rewarded vault.
     * @param _vaultId ID of the vault to stake.
     * @param _amount Amount of token to stake.
     */
    function stake(uint256 _vaultId, uint256 _amount) public {
        address _vault = controller.vaults(_vaultId);
        require(_vault != address(0x0), "no vault");
        require(_amount > 0, "zero amount");

        Account account = _getAccount();
        RewardedVault vault = RewardedVault(_vault);
        IERC20 token = vault.token();
        account.approveToken(address(token), address(vault), _amount);

        bytes memory methodData = abi.encodeWithSignature("deposit(uint256)", _amount);
        account.invoke(address(vault), 0, methodData);

        emit Staked(msg.sender, _vaultId, address(token), _amount);
    }

    /**
     * @dev Unstake token out of RewardedVault.
     * @param _vaultId ID of the vault to unstake.
     * @param _amount Amount of token to unstake.
     */
    function unstake(uint256 _vaultId, uint256 _amount) public {
        address _vault = controller.vaults(_vaultId);
        require(_vault != address(0x0), "no vault");
        require(_amount > 0, "zero amount");

        Account account = _getAccount();
        RewardedVault vault = RewardedVault(_vault);
        IERC20 token = vault.token();

        // Important: Need to convert token amount to vault share!
        uint256 totalBalance = vault.balance();
        uint256 totalSupply = vault.totalSupply();
        uint256 shares = _amount.mul(totalSupply).div(totalBalance);
        bytes memory methodData = abi.encodeWithSignature("withdraw(uint256)", shares);
        account.invoke(address(vault), 0, methodData);

        emit Unstaked(msg.sender, _vaultId, address(token), _amount);
    }

    /**
     * @dev Unstake all token out of RewardedVault.
     * @param _vaultId ID of the vault to unstake.
     */
    function unstakeAll(uint256 _vaultId) public {
        address _vault = controller.vaults(_vaultId);
        require(_vault != address(0x0), "no vault");

        Account account = _getAccount();
        RewardedVault vault = RewardedVault(_vault);
        IERC20 token = vault.token();

        uint256 totalBalance = vault.balance();
        uint256 totalSupply = vault.totalSupply();
        uint256 shares = vault.balanceOf(address(account));
        uint256 amount = shares.mul(totalBalance).div(totalSupply);
        bytes memory methodData = abi.encodeWithSignature("withdraw(uint256)", shares);
        account.invoke(address(vault), 0, methodData);

        emit Unstaked(msg.sender, _vaultId, address(token), amount);
    }

    /**
     * @dev Claims rewards from RewardedVault.
     * @param _vaultId ID of the vault to unstake.
     */
    function claimRewards(uint256 _vaultId) public {
        address _vault = controller.vaults(_vaultId);
        require(_vault != address(0x0), "no vault");

        Account account = _getAccount();
        RewardedVault vault = RewardedVault(_vault);
        IERC20 rewardToken = IERC20(controller.rewardToken());
        bytes memory methodData = abi.encodeWithSignature("claimReward()");
        bytes memory methodResult = account.invoke(address(vault), 0, methodData);
        uint256 claimAmount = abi.decode(methodResult, (uint256));

        emit Claimed(msg.sender, _vaultId, address(rewardToken), claimAmount);
    }

    /**
     * @dev Retrieves the amount of token staked in RewardedVault.
     * @param _vaultId ID of the vault to unstake.
     */
    function getStakeBalance(uint256 _vaultId) public view returns (uint256) {
        address _vault = controller.vaults(_vaultId);
        require(_vault != address(0x0), "no vault");
        address account = AccountFactory(accountFactory).accounts(msg.sender);
        require(account != address(0x0), "no account");

        RewardedVault vault = RewardedVault(_vault);
        uint256 totalBalance = vault.balance();
        uint256 totalSupply = vault.totalSupply();
        uint256 share = vault.balanceOf(account);

        return totalBalance.mul(share).div(totalSupply);
    }

    /**
     * @dev Returns the total balance of the vault.
     */
    function getVaultBalance(uint256 _vaultId) public view returns (uint256) {
        address _vault = controller.vaults(_vaultId);
        require(_vault != address(0x0), "no vault");

        RewardedVault vault = RewardedVault(_vault);
        return vault.balance();
    }

    /**
     * @dev Return the amount of unclaim rewards.
     * @param _vaultId ID of the vault to unstake.
     */
    function getUnclaimedReward(uint256 _vaultId) public view returns (uint256) {
        address _vault = controller.vaults(_vaultId);
        require(_vault != address(0x0), "no vault");
        address account = AccountFactory(accountFactory).accounts(msg.sender);
        require(account != address(0x0), "no account");

        return RewardedVault(_vault).earned(account);
    }

    /**
     * @dev Return the amount of claim rewards.
     * @param _vaultId ID of the vault to unstake.
     */
    function getClaimedReward(uint256 _vaultId) public view returns (uint256) {
        address _vault = controller.vaults(_vaultId);
        require(_vault != address(0x0), "no vault");
        address account = AccountFactory(accountFactory).accounts(msg.sender);
        require(account != address(0x0), "no account");
        
        return RewardedVault(_vault).claims(account);
    }
}