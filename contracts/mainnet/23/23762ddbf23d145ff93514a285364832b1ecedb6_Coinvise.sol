/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]



// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]



pragma solidity >=0.6.0 <0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/math/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity >=0.6.0 <0.8.0;



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


// File contracts/lib/EIP712MetaTransactionUpgradeable/EIP712BaseUpgradeable.sol

// MIT
pragma solidity ^0.7.4;

contract EIP712BaseUpgradeable is Initializable {
  struct EIP712Domain {
    string name;
    string version;
    uint256 salt;
    address verifyingContract;
  }

  bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(
      bytes(
        "EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"
      )
    );

  bytes32 internal domainSeperator;

  function _initialize(string memory name, string memory version)
    public
    virtual
    initializer
  {
    domainSeperator = keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        getChainID(),
        address(this)
      )
    );
  }

  function getChainID() internal pure returns (uint256 id) {
    assembly {
      id := chainid()
    }
  }

  function getDomainSeperator() private view returns (bytes32) {
    return domainSeperator;
  }

  /**
   * Accept message hash and returns hash message in EIP712 compatible form
   * So that it can be used to recover signer from signature signed using EIP712 formatted data
   * https://eips.ethereum.org/EIPS/eip-712
   * "\\x19" makes the encoding deterministic
   * "\\x01" is the version byte to make it compatible to EIP-191
   */
  function toTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
      );
  }
}


// File contracts/lib/EIP712MetaTransactionUpgradeable/EIP712MetaTransactionUpgradeable.sol

// MIT
pragma solidity ^0.7.4;



contract EIP712MetaTransactionUpgradeable is
  Initializable,
  EIP712BaseUpgradeable
{
  using SafeMath for uint256;
  bytes32 private constant META_TRANSACTION_TYPEHASH =
    keccak256(
      bytes(
        "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
      )
    );

  event MetaTransactionExecuted(
    address userAddress,
    address payable relayerAddress,
    bytes functionSignature
  );
  mapping(address => uint256) private nonces;

  /*
   * Meta transaction structure.
   * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
   * He should call the desired function directly in that case.
   */
  struct MetaTransaction {
    uint256 nonce;
    address from;
    bytes functionSignature;
  }

  function _initialize(string memory _name, string memory _version)
    public
    override
    initializer
  {
    EIP712BaseUpgradeable._initialize(_name, _version);
  }

  function convertBytesToBytes4(bytes memory inBytes)
    internal
    pure
    returns (bytes4 outBytes4)
  {
    if (inBytes.length == 0) {
      return 0x0;
    }

    assembly {
      outBytes4 := mload(add(inBytes, 32))
    }
  }

  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public payable virtual returns (bytes memory) {
    bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
    require(
      destinationFunctionSig != msg.sig,
      "functionSignature can not be of executeMetaTransaction method"
    );
    MetaTransaction memory metaTx =
      MetaTransaction({
        nonce: nonces[userAddress],
        from: userAddress,
        functionSignature: functionSignature
      });
    require(
      verify(userAddress, metaTx, sigR, sigS, sigV),
      "Signer and signature do not match"
    );
    nonces[userAddress] = nonces[userAddress].add(1);
    // Append userAddress at the end to extract it from calling context
    (bool success, bytes memory returnData) =
      address(this).call(abi.encodePacked(functionSignature, userAddress));

    require(success, "Function call not successful");
    emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);
    return returnData;
  }

  function hashMetaTransaction(MetaTransaction memory metaTx)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          META_TRANSACTION_TYPEHASH,
          metaTx.nonce,
          metaTx.from,
          keccak256(metaTx.functionSignature)
        )
      );
  }

  function getNonce(address user) external view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  function verify(
    address user,
    MetaTransaction memory metaTx,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) internal view returns (bool) {
    address signer =
      ecrecover(
        toTypedMessageHash(hashMetaTransaction(metaTx)),
        sigV,
        sigR,
        sigS
      );
    require(signer != address(0), "Invalid signature");
    return signer == user;
  }

  function msgSender() internal view returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }
}


// File contracts/Coinvise.sol

// Unlicensed
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;






// import "hardhat/console.sol";

interface IERC20Extended is IERC20 {
  function decimals() external view returns (uint8);
}

contract Coinvise is
  Initializable,
  OwnableUpgradeable,
  EIP712MetaTransactionUpgradeable
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20Extended;
  using SafeERC20 for IERC20;

  event CampaignCreated(uint256 indexed campaignId);
  event UserRewarded(
    address indexed managerAddress,
    uint256 indexed campaignId,
    address indexed userAddress,
    address tokenAddress,
    uint256 amount
  );
  event Multisent(
    address indexed tokenAddress,
    uint256 recipientsAmount,
    uint256 amount
  );
  event Withdrawn(address indexed recipient, uint256 amount);

  event Deposited(
    uint256 depositId,
    address indexed depositor,
    address token,
    uint256 amount,
    uint256 price
  );
  event Bought(
    address user,
    uint256 depositId,
    address owner,
    address token,
    uint256 amount,
    uint256 price
  );
  event WithdrawnDepositOwnerBalance(address user, uint256 amount);

  struct Campaign {
    uint256 campaignId;
    address manager;
    address tokenAddress;
    uint256 initialBalance;
    uint256 remainingBalance;
    uint256 linksAmount;
    uint256 amountPerLink;
    uint256 linksRewardedCount;
  }

  struct Deposit {
    uint256 depositId;
    address owner;
    address token;
    uint256 initialBalance;
    uint256 remainingBalance;
    uint256 price;
  }

  /**
   * @dev Following are the state variables for this contract
   *      Due to resrictions of the proxy pattern, do not change the type or order
   *      of the state variables.
   *      https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
   */

  uint256 totalDepositOwnersBalanceInWei;

  // Next campaign ID by manager
  mapping(address => uint256) internal nextCampaignId;

  // All campaigns (userAddress => campaignId => Campaign)
  mapping(address => mapping(uint256 => Campaign)) internal campaigns;

  // All campaign IDs of a user (userAddress => campaignIds[])
  mapping(address => uint256[]) internal campaignIds;

  // Rewarded addresses by a campaign (campaignId => userAddress[])
  mapping(address => mapping(uint256 => mapping(address => bool)))
    internal addressRewarded;

  // Rewarded links by a campaign (campaignId => slug[])
  mapping(uint256 => mapping(string => bool)) internal linksRewarded;

  // Next deposit ID by owner
  mapping(address => uint256) internal nextDepositId;

  // Deposits by user (userAddress => (depositId => deposit)
  mapping(address => mapping(uint256 => Deposit)) internal deposits;

  // All deposits IDs of a user (userAddress => depositIds[])
  mapping(address => uint256[]) internal depositIds;

  // Balances by owner
  mapping(address => uint256) internal depositOwnersBalancesInWei;

  // This is an address whose private key lives in the coinvise backend
  // Used for signature verification
  address private trustedAddress;

  // Premiums Charged on Various Services
  uint256 public airdropPerLinkWeiCharged;
  uint256 public multisendPerLinkWeiCharged;
  uint256 public depositPercentageCharged;
  uint256 public depositPercentageChargedDecimals;

  // Add any new state variables here
  // End of state variables

  /**
   * @dev We cannot have constructors in upgradeable contracts,
   *      therefore we define an initialize function which we call
   *      manually once the contract is deployed.
   *      the initializer modififer ensures that this can only be called once.
   *      in practice, the openzeppelin library automatically calls the intitazie
   *      function once deployed.
   */
  function initialize(
    address _trustedAddress,
    uint256 _airdropPerLinkWeiCharged,
    uint256 _multisendPerLinkWeiCharged,
    uint256 _depositPercentageCharged,
    uint256 _depositPercentageChargedDecimals
  ) public initializer {
    require(_trustedAddress != address(0), "ERR__INVALID_TRUSTEDADDRESS_0x0");

    // Call intialize of Base Contracts
    require(_trustedAddress != address(0), "ERR__0x0_TRUSTEDADDRESS");

    OwnableUpgradeable.__Ownable_init();
    EIP712MetaTransactionUpgradeable._initialize("Coinvise", "1");
    trustedAddress = _trustedAddress;

    // Set premiums
    require(_depositPercentageCharged < 30, "ERR_DEPOSIT_FEE_TOO_HIGH");
    airdropPerLinkWeiCharged = _airdropPerLinkWeiCharged;
    multisendPerLinkWeiCharged = _multisendPerLinkWeiCharged;
    depositPercentageCharged = _depositPercentageCharged;
    depositPercentageChargedDecimals = _depositPercentageChargedDecimals;
  }

  function setAirdropPremiums(uint256 _airdropPerLinkWeiCharged)
    external
    onlyOwner
  {
    airdropPerLinkWeiCharged = _airdropPerLinkWeiCharged;
  }

  function setMultisendPremiums(uint256 _mulisendPerLinkWeiCharged)
    external
    onlyOwner
  {
    multisendPerLinkWeiCharged = _mulisendPerLinkWeiCharged;
  }

  function setDepositPremiums(
    uint256 _depositPercentageCharged,
    uint256 _depositPercentageChargedDecimals
  ) external onlyOwner {
    require(_depositPercentageCharged < 30, "ERR_DEPOSIT_FEE_TOO_HIGH");
    depositPercentageCharged = _depositPercentageCharged;
    depositPercentageChargedDecimals = _depositPercentageChargedDecimals;
  }

  function setTrustedAddress(address _trustedAddress) external onlyOwner {
    require(_trustedAddress != address(0), "ERR__0x0_TRUSTEDADDRESS");
    trustedAddress = _trustedAddress;
  }

  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    uint256 balance = totalBalance.sub(totalDepositOwnersBalanceInWei);
    msg.sender.transfer(balance);
    emit Withdrawn(msg.sender, balance);
  }

  // Generate Links
  function _createCampaign(
    address _tokenAddress,
    uint256 _linksAmount,
    uint256 _amountPerLink
  ) internal returns (uint256 _campaignId) {
    require(_linksAmount > 0, "ERR__LINKS_AMOUNT_MUST_BE_GREATHER_THAN_ZERO");
    require(
      _amountPerLink > 0,
      "ERR__AMOUNT_PER_LINK_MUST_BE_GREATHER_THAN_ZERO"
    );

    uint256 _initialBalance = _linksAmount.mul(_amountPerLink);
    address _sender = msgSender();

    IERC20(_tokenAddress).safeTransferFrom(
      _sender,
      address(this),
      _initialBalance
    );

    _campaignId = getCampaignId();

    Campaign memory _campaign =
      Campaign({
        campaignId: _campaignId,
        manager: _sender,
        tokenAddress: _tokenAddress,
        initialBalance: _initialBalance,
        remainingBalance: _initialBalance,
        linksAmount: _linksAmount,
        amountPerLink: _amountPerLink,
        linksRewardedCount: 0
      });

    campaigns[_sender][_campaignId] = _campaign;
    campaignIds[_sender].push(_campaignId);

    emit CampaignCreated(_campaignId);

    return _campaignId;
  }

  // Generate Links
  // function createCampaignMeta(
  //   address _tokenAddress,
  //   uint256 _linksAmount,
  //   uint256 _amountPerLink
  // ) external returns (uint256) {
  //   return _createCampaign(_tokenAddress, _linksAmount, _amountPerLink);
  // }

  function createCampaign(
    address _tokenAddress,
    uint256 _linksAmount,
    uint256 _amountPerLink
  ) external payable returns (uint256 _campaignId) {
    uint256 priceInWei = airdropPerLinkWeiCharged * _linksAmount;
    require(msg.value == priceInWei, "ERR__CAMPAIGN_PRICE_MUST_BE_PAID");

    return _createCampaign(_tokenAddress, _linksAmount, _amountPerLink);
  }

  function getCampaign(address _campaignManager, uint256 _campaignId)
    external
    view
    returns (
      uint256,
      address,
      address,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    require(
      campaigns[_campaignManager][_campaignId].campaignId == _campaignId,
      "ERR__CAMPAIGN_DOES_NOT_EXIST"
    );

    Campaign memory _campaign = campaigns[_campaignManager][_campaignId];

    return (
      _campaign.campaignId,
      _campaign.manager,
      _campaign.tokenAddress,
      _campaign.initialBalance,
      _campaign.remainingBalance,
      _campaign.linksAmount,
      _campaign.amountPerLink,
      _campaign.linksRewardedCount
    );
  }

  function getCampaignIdsFromManager(address _campaignManager)
    external
    view
    returns (uint256[] memory)
  {
    return campaignIds[_campaignManager];
  }

  function claim(
    address _campaignManager,
    uint256 _campaignId,
    bytes32 r,
    bytes32 s,
    uint8 v
  ) external {
    require(
      campaigns[_campaignManager][_campaignId].campaignId == _campaignId,
      "ERR__CAMPAIGN_DOES_NOT_EXIST"
    );

    address _claimer = msgSender();
    Campaign memory _campaign = campaigns[_campaignManager][_campaignId];

    require(
      addressRewarded[_campaignManager][_campaignId][_claimer] != true,
      "ERR__ADDRESS_ALREADY_REWARDED"
    );
    // require(linksRewarded[_campaignId][_slug] != true, "ERR__LINK_ALREADY_REWARDED");

    // Check if signature is correct
    bytes32 messageHash =
      keccak256(
        abi.encodePacked(
          "\x19Ethereum Signed Message:\n32",
          keccak256(abi.encode(_campaignManager, _campaignId, _claimer))
        )
      );
    address signer = ecrecover(messageHash, v, r, s);
    require(signer != address(0), "ERR__0x0_SIGNER");
    require(signer == trustedAddress, "ERR__INVALID_SIGNER");

    require(
      _campaign.linksRewardedCount < _campaign.linksAmount,
      "ERR__ALL_LINKS_USED"
    );
    require(
      _campaign.remainingBalance >= _campaign.amountPerLink,
      "ERR_NOT_ENOUGH_BALANCE_FOR_REWARDING"
    );

    address _token = _campaign.tokenAddress;

    IERC20(_token).safeTransfer(_claimer, _campaign.amountPerLink);

    // Mark as rewarded
    addressRewarded[_campaignManager][_campaignId][_claimer] = true;
    campaigns[_campaignManager][_campaignId].linksRewardedCount = _campaign
      .linksRewardedCount
      .add(1);
    campaigns[_campaignManager][_campaignId].remainingBalance = _campaign
      .remainingBalance
      .sub(_campaign.amountPerLink);

    // Emit event
    emit UserRewarded(
      _campaignManager,
      _campaignId,
      _claimer,
      _token,
      _campaign.amountPerLink
    );
  }

  function _multisend(
    address _token,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) internal {
    uint256 recipientsLength = _recipients.length;
    uint256 amountsLength = _amounts.length;

    require(amountsLength == recipientsLength, "ERR__INVALID_ARGS");

    address _user = msgSender();
    uint256 _totalAmount = 0;

    uint8 i = 0;
    for (i; i < recipientsLength; i++) {
      IERC20(_token).safeTransferFrom(_user, _recipients[i], _amounts[i]);
      _totalAmount = _totalAmount.add(_amounts[i]);
    }

    // Emit event
    emit Multisent(_token, recipientsLength, _totalAmount);
  }

  function multisend(
    address _token,
    address[] memory _recipients,
    uint256[] memory _amounts
  ) external payable {
    uint256 recipientsLength = _recipients.length;

    require(
      msg.value == multisendPerLinkWeiCharged * recipientsLength,
      "ERR__MULTISEND_PRICE_MUST_BE_PAID"
    );

    _multisend(_token, _recipients, _amounts);
  }

  // function multisendMeta(
  //   address _token,
  //   address[] memory _recipients,
  //   uint256[] memory _amounts
  // ) external {
  //   _multisend(_token, _recipients, _amounts);
  // }

  function getCampaignId() internal returns (uint256 _campaignId) {
    address _campaignManager = msg.sender;
    _campaignId = nextCampaignId[_campaignManager];

    if (_campaignId <= 0) {
      _campaignId = 1;
    }

    nextCampaignId[_campaignManager] = _campaignId.add(1);

    return _campaignId;
  }

  function getCampaignRewardedCount(address _manager, uint256 _campaignId)
    external
    view
    returns (uint256)
  {
    return campaigns[_manager][_campaignId].linksRewardedCount;
  }

  function _depositToken(
    address _token,
    uint256 _amount,
    uint256 _price
  ) internal returns (uint256 _depositId) {
    require(_amount > 0, "ERR__AMOUNT_MUST_BE_GREATHER_THAN_ZERO");
    require(_price > 0, "ERR__PRICE_MUST_BE_GREATHER_THAN_ZERO");

    IERC20Extended tokenContract = IERC20Extended(_token);

    address _owner = msg.sender;
    tokenContract.safeTransferFrom(_owner, address(this), _amount);

    _depositId = getDepositId();
    Deposit memory _deposit =
      Deposit({
        depositId: _depositId,
        owner: _owner,
        token: _token,
        initialBalance: _amount,
        remainingBalance: _amount,
        price: _price
      });

    deposits[_owner][_depositId] = _deposit;
    depositIds[_owner].push(_depositId);

    emit Deposited(_depositId, _owner, _token, _amount, _price);
  }

  function depositToken(
    address _token,
    uint256 _amount,
    uint256 _price
  ) external payable returns (uint256 _depositId) {
    IERC20Extended tokenContract = IERC20Extended(_token);
    uint256 decimalsZeros = 10**tokenContract.decimals();
    
    // Fee = 2% of the total. (tokenAmount * values.tokenPrice * 0.02) / depositPercentageChargedDecimals
    // (depositPercentageChargedDecimals is used for when depositPercentageCharged < 0.01)

    // OLD
    // uint256 priceInWei = _price
    //   .mul(_amount)
    //   .div(decimalsZeros)
    //   .mul(depositPercentageCharged)
    //   .div(100)
    //   .div(10**depositPercentageChargedDecimals);

    // Same formula but only dividing once, avoiding truncation as much as possible
    uint256 bigTotal = _price.mul(_amount).mul(depositPercentageCharged);
    uint256 zeroes = decimalsZeros.mul(100).mul(10**depositPercentageChargedDecimals);
    uint256 priceInWei = bigTotal.div(zeroes);
    require(priceInWei > 0, "ERR__A_PRICE_MUST_BE_PAID");
    require(msg.value == priceInWei, "ERR__PRICE_MUST_BE_PAID");

    return _depositToken(_token, _amount, _price);
  }

  function getDepositIdsFromOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    return depositIds[_owner];
  }

  function getDeposit(address _owner, uint256 _depositId)
    external
    view
    returns (
      uint256,
      address,
      address,
      uint256,
      uint256,
      uint256
    )
  {
    require(
      deposits[_owner][_depositId].depositId == _depositId,
      "ERR__DEPOSIT_DOES_NOT_EXIST"
    );

    Deposit memory _deposit = deposits[_owner][_depositId];

    return (
      _deposit.depositId,
      _deposit.owner,
      _deposit.token,
      _deposit.initialBalance,
      _deposit.remainingBalance,
      _deposit.price
    );
  }

  function buyToken(
    uint256 _depositId,
    address payable _owner,
    uint256 _amount
  ) external payable {
    require(
      deposits[_owner][_depositId].depositId == _depositId,
      "ERR__DEPOSIT_DOES_NOT_EXIST"
    );
    Deposit memory _deposit = deposits[_owner][_depositId];
    require(_amount > 0, "ERR__AMOUNT_MUST_BE_GREATHER_THAN_ZERO");
    require(
      _deposit.remainingBalance >= _amount,
      "ERR_NOT_ENOUGH_BALANCE_TO_BUY"
    );

    IERC20Extended tokenContract = IERC20Extended(_deposit.token);
    uint256 decimalsZeros = 10**tokenContract.decimals();
    uint256 totalPrice = _deposit.price.mul(_amount).div(decimalsZeros);
    require(totalPrice > 0, "ERR__A_PRICE_MUST_BE_PAID");
    require(msg.value == totalPrice, "ERR__TOTAL_PRICE_MUST_BE_PAID");

    deposits[_owner][_depositId].remainingBalance = _deposit
      .remainingBalance
      .sub(_amount);
    IERC20(_deposit.token).safeTransfer(msg.sender, _amount);

    depositOwnersBalancesInWei[_owner] = depositOwnersBalancesInWei[_owner].add(
      msg.value
    );
    totalDepositOwnersBalanceInWei = totalDepositOwnersBalanceInWei.add(
      msg.value
    );

    emit Bought(
      msg.sender,
      _depositId,
      _owner,
      _deposit.token,
      _amount,
      _deposit.price
    );
  }

  function withdrawDeposit(
    uint256 _depositId
  ) external {
    address _owner = msg.sender;
    require(deposits[_owner][_depositId].depositId == _depositId, "ERR__DEPOSIT_DOES_NOT_EXIST");
    Deposit memory _deposit = deposits[_owner][_depositId];
    require(_deposit.remainingBalance > 0, "ERR_NO_BALANCE_TO_WITHDRAW");

    deposits[_owner][_depositId].remainingBalance = 0;
    delete deposits[_owner][_depositId];
    IERC20(_deposit.token).safeTransfer(_owner, _deposit.remainingBalance);
  }

  function withdrawDepositOwnerBalance() external {
    address payable owner = msg.sender;
    require(
      depositOwnersBalancesInWei[owner] > 0,
      "ERR_NO_BALANCE_TO_WITHDRAW"
    );
    uint256 toWithdraw = depositOwnersBalancesInWei[owner];
    depositOwnersBalancesInWei[owner] = 0;
    totalDepositOwnersBalanceInWei = totalDepositOwnersBalanceInWei.sub(
      toWithdraw
    );
    require(
      totalDepositOwnersBalanceInWei >= 0,
      "ERR_NO_GENERAL_BALANCE_TO_WITHDRAW"
    );

    owner.transfer(toWithdraw);

    emit WithdrawnDepositOwnerBalance(owner, toWithdraw);
  }

  function getDepositOwnerBalance() external view returns (uint256) {
    return depositOwnersBalancesInWei[msg.sender];
  }

  function getCoinviseBalance() external view returns (uint256) {
    uint256 totalBalance = address(this).balance;
    return totalBalance.sub(totalDepositOwnersBalanceInWei);
  }

  function getDepositId() internal returns (uint256 _depositId) {
    _depositId = nextDepositId[msg.sender];

    if (_depositId <= 0) {
      _depositId = 1;
    }

    nextDepositId[msg.sender] = _depositId.add(1);

    return _depositId;
  }
}