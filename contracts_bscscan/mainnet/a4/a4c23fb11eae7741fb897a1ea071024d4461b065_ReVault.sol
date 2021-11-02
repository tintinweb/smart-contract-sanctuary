/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol



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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


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

// File: @pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol


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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
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

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol


interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: @pancakeswap/pancake-swap-lib/contracts/utils/Address.sol


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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol





/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// File: contracts/reva/interfaces/IRevaChef.sol

interface IRevaChef {
    function notifyDeposited(address user, address token, uint amount) external;
    function notifyWithdrawn(address user, address token, uint amount) external;
    function claim(address token) external;
    function claimFor(address token, address to) external;
}

// File: contracts/reva/interfaces/IRevaUserProxy.sol

interface IRevaUserProxy {
    function callVault(
        address _vaultAddress,
        address _depositTokenAddress,
        address _vaultNativeTokenAddress,
        bytes calldata _payload
    ) external;
    function callDepositVault(
        address _vaultAddress,
        address _depositTokenAddress,
        address _vaultNativeTokenAddress,
        uint amount,
        bytes calldata _payload
    ) external payable;
}

// File: contracts/reva/interfaces/IRevaUserProxyFactory.sol


interface IRevaUserProxyFactory {
    function createUserProxy() external returns (address);
}

// File: contracts/library/TransferHelper.sol

contract TransferHelper {
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferBNB: BNB transfer failed');
    }
}

// File: contracts/library/ReentrancyGuard.sol


// taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
// removed constructor for upgradeability warnings

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

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// File: contracts/library/interfaces/IWBNB.sol

// vault that controls a single token
interface IWBNB {
    function withdraw(uint wad) external;
    function deposit() external payable;
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

// File: contracts/library/interfaces/IZap.sol


abstract contract IZap {
    function getBUSDValue(address _token, uint _amount) external view virtual returns (uint);
    function zapInTokenTo(address _from, uint amount, address _to, address receiver) public virtual;
    function zapInToken(address _from, uint amount, address _to) external virtual;
    function zapInTo(address _to, address _receiver) external virtual payable;
    function zapIn(address _to) external virtual payable;
    function zapInTokenToBNB(address _from, uint amount) external virtual;
}

// File: contracts/reva/ReVault.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;












contract ReVault is OwnableUpgradeable, ReentrancyGuard, TransferHelper {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct VaultInfo {
        address vaultAddress; // address of vault
        address depositTokenAddress; // address of deposit token
        address nativeTokenAddress; // address of vaults native reward token
    }

    IBEP20 private reva;
    IRevaChef public revaChef;
    IRevaUserProxyFactory public revaUserProxyFactory;
    IZap public zap;
    address public revaFeeReceiver;
    address public zapAndDeposit;

    uint public profitToReva;
    uint public profitToRevaStakers;

    VaultInfo[] public vaults;

    mapping(uint => mapping(address => uint)) public userVaultPrincipal;
    mapping(address => address) public userProxyContractAddress;
    mapping(address => bool) public haveApprovedTokenToZap;
    mapping(bytes32 => bool) public vaultExists;

    // approved payloads mapping
    mapping(uint => mapping(bytes4 => bool)) public approvedDepositPayloads;
    mapping(uint => mapping(bytes4 => bool)) public approvedWithdrawPayloads;
    mapping(uint => mapping(bytes4 => bool)) public approvedHarvestPayloads;

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint public constant PROFIT_DISTRIBUTION_PRECISION = 1000000;
    uint public constant MAX_PROFIT_TO_REVA = 500000;
    uint public constant MAX_PROFIT_TO_REVA_STAKERS = 200000;

    address public admin;

    event SetProfitToReva(uint profitToReva);
    event SetProfitToRevaStakers(uint profitToRevaStakers);
    event SetZapAndDeposit(address zapAndDepositAddress);
    event SetAdmin(address admin);

    function initialize(
        address _revaChefAddress,
        address _revaTokenAddress,
        address _revaUserProxyFactoryAddress,
        address _revaFeeReceiver,
        address _zap,
        uint _profitToReva,
        uint _profitToRevaStakers
    ) external initializer {
        __Ownable_init();
        require(_profitToReva <= MAX_PROFIT_TO_REVA, "MAX_PROFIT_TO_REVA");
        require(_profitToRevaStakers <= MAX_PROFIT_TO_REVA_STAKERS, "MAX_PROFIT_TO_REVA_STAKERS");
        revaChef = IRevaChef(_revaChefAddress);
        reva = IBEP20(_revaTokenAddress);
        revaUserProxyFactory = IRevaUserProxyFactory(_revaUserProxyFactoryAddress);
        revaFeeReceiver = _revaFeeReceiver;
        zap = IZap(_zap);
        profitToReva = _profitToReva;
        profitToRevaStakers = _profitToRevaStakers;
    }

    modifier nonDuplicateVault(address _vaultAddress, address _depositTokenAddress, address _nativeTokenAddress) {
        require(!vaultExists[keccak256(abi.encodePacked(_vaultAddress, _depositTokenAddress, _nativeTokenAddress))], "duplicate");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(msg.sender == admin || msg.sender == owner(), "PERMS");
        _;
    }

    /* ========== View Functions ========== */

    function vaultLength() external view returns (uint256) {
        return vaults.length;
    }
    
    function getUserVaultPrincipal(uint _vid, address _user) external view returns (uint) {
        return userVaultPrincipal[_vid][_user];
    }

    // rebalance
    function rebalanceDepositAll(uint _fromVid, uint _toVid, bytes calldata _withdrawPayload, bytes calldata _depositAllPayload) external nonReentrant {
        require(_isApprovedWithdrawMethod(_fromVid, _withdrawPayload), "unapproved withdraw method");
        require(_isApprovedDepositMethod(_toVid, _depositAllPayload), "unapproved deposit method");
        require(_fromVid != _toVid, "identical vault indices");

        VaultInfo memory fromVault = vaults[_fromVid];
        VaultInfo memory toVault = vaults[_toVid];
        require(toVault.depositTokenAddress == fromVault.depositTokenAddress, "rebalance different tokens");

        uint fromVaultUserPrincipal = userVaultPrincipal[_fromVid][msg.sender];
        address userProxyAddress = userProxyContractAddress[msg.sender];
        uint fromVaultTokenAmount = _withdrawFromUnderlyingVault(msg.sender, fromVault, _fromVid, _withdrawPayload);

        if (fromVault.depositTokenAddress == WBNB) {
            IRevaUserProxy(userProxyAddress).callDepositVault{ value: fromVaultTokenAmount }(toVault.vaultAddress, toVault.depositTokenAddress, toVault.nativeTokenAddress, fromVaultTokenAmount, _depositAllPayload);
        } else {
            IBEP20(fromVault.depositTokenAddress).safeTransfer(userProxyAddress, fromVaultTokenAmount);
            IRevaUserProxy(userProxyAddress).callDepositVault(toVault.vaultAddress, toVault.depositTokenAddress, toVault.nativeTokenAddress, fromVaultTokenAmount, _depositAllPayload);
        }

        _handleDepositHarvest(toVault.nativeTokenAddress, msg.sender);

        if (fromVaultTokenAmount > fromVaultUserPrincipal) {
            revaChef.notifyDeposited(msg.sender, toVault.depositTokenAddress, fromVaultTokenAmount.sub(fromVaultUserPrincipal));
        }
        userVaultPrincipal[_toVid][msg.sender] = userVaultPrincipal[_toVid][msg.sender].add(fromVaultTokenAmount);
    }

    // some vaults like autofarm don't have a depositAll() method, so in cases like this
    // we need to call deposit(amount), but the amount returned from withdrawAll is dynamic,
    // and so the deposit(amount) payload must be created here.
    function rebalanceDepositAllDynamicAmount(uint _fromVid, uint _toVid, bytes calldata _withdrawPayload, bytes calldata _depositLeftPayload, bytes calldata _depositRightPayload) external nonReentrant {
        require(_isApprovedWithdrawMethod(_fromVid, _withdrawPayload), "unapproved withdraw method");
        require(_isApprovedDepositMethod(_toVid, _depositLeftPayload), "unapproved deposit method");
        require(_fromVid != _toVid, "identical vault indices");

        VaultInfo memory fromVault = vaults[_fromVid];
        VaultInfo memory toVault = vaults[_toVid];
        require(toVault.depositTokenAddress == fromVault.depositTokenAddress, "rebalance different tokens");

        uint fromVaultUserPrincipal = userVaultPrincipal[_fromVid][msg.sender];
        address userProxyAddress = userProxyContractAddress[msg.sender];
        uint fromVaultTokenAmount = _withdrawFromUnderlyingVault(msg.sender, fromVault, _fromVid, _withdrawPayload);
        IBEP20(fromVault.depositTokenAddress).safeTransfer(userProxyAddress, fromVaultTokenAmount);

        {
            bytes memory payload = abi.encodePacked(_depositLeftPayload, fromVaultTokenAmount, _depositRightPayload);
            IRevaUserProxy(userProxyAddress).callDepositVault(toVault.vaultAddress, toVault.depositTokenAddress, toVault.nativeTokenAddress, fromVaultTokenAmount, payload);
        }

        _handleDepositHarvest(toVault.nativeTokenAddress, msg.sender);

        if (fromVaultTokenAmount > fromVaultUserPrincipal) {
            revaChef.notifyDeposited(msg.sender, toVault.depositTokenAddress, fromVaultTokenAmount.sub(fromVaultUserPrincipal));
        }
        userVaultPrincipal[_toVid][msg.sender] = userVaultPrincipal[_toVid][msg.sender].add(fromVaultTokenAmount);
    }

    // some vaults such as bunny-wbnb accept BNB deposits rather than WBNB
    // this means we have to convert the withdrawn WBNB into BNB and then send it
    function rebalanceDepositAllAsWBNB(uint _fromVid, uint _toVid, bytes calldata _withdrawPayload, bytes calldata _depositAllPayload) external nonReentrant {
        require(_isApprovedWithdrawMethod(_fromVid, _withdrawPayload), "unapproved withdraw method");
        require(_isApprovedDepositMethod(_toVid, _depositAllPayload), "unapproved deposit method");
        require(_fromVid != _toVid, "identical vault indices");

        VaultInfo memory fromVault = vaults[_fromVid];
        VaultInfo memory toVault = vaults[_toVid];

        require(toVault.depositTokenAddress == fromVault.depositTokenAddress, "rebalance different tokens");
        require(fromVault.depositTokenAddress == WBNB, "not a WBNB vault");

        address userProxyAddress = userProxyContractAddress[msg.sender];

        uint fromVaultTokenAmount = _withdrawFromUnderlyingVault(msg.sender, fromVault, _fromVid, _withdrawPayload);
        IWBNB(WBNB).deposit{ value: fromVaultTokenAmount }();
        IBEP20(WBNB).safeTransfer(userProxyAddress, fromVaultTokenAmount);
        IRevaUserProxy(userProxyAddress).callDepositVault(toVault.vaultAddress, toVault.depositTokenAddress, toVault.nativeTokenAddress, fromVaultTokenAmount, _depositAllPayload);

        _handleDepositHarvest(toVault.nativeTokenAddress, msg.sender);

        userVaultPrincipal[_toVid][msg.sender] = userVaultPrincipal[_toVid][msg.sender].add(fromVaultTokenAmount);
    }

    function withdrawFromVaultAndClaim(uint _vid, bytes calldata _withdrawPayload) external nonReentrant {
        _withdrawFromVault(_vid, _withdrawPayload);
        revaChef.claimFor(vaults[_vid].depositTokenAddress, msg.sender);
    }

    function withdrawFromVault(uint _vid, bytes calldata _withdrawPayload) external nonReentrant returns (uint returnedTokenAmount, uint returnedRevaAmount) {
        return _withdrawFromVault(_vid, _withdrawPayload);
    }

    function depositToVaultFor(uint _amount, uint _vid, bytes calldata _depositPayload, address _user) external nonReentrant payable {
        require(tx.origin == _user, "user must initiate tx");
        require(msg.sender == zapAndDeposit, "Only zapAndDeposit may deposit for user");
        _depositToVault(_amount, _vid, _depositPayload, _user, msg.sender);
    }

    function depositToVault(uint _amount, uint _vid, bytes calldata _depositPayload) external nonReentrant payable {
        _depositToVault(_amount, _vid, _depositPayload, msg.sender, msg.sender);
    }

    function harvestVault(uint _vid, bytes calldata _payloadHarvest) external nonReentrant returns (uint returnedTokenAmount, uint returnedRevaAmount) {
        require(_isApprovedHarvestMethod(_vid, _payloadHarvest), "unapproved harvest method");
        address userProxyAddress = userProxyContractAddress[msg.sender];
        VaultInfo memory vault = vaults[_vid];
        uint prevRevaBalance = reva.balanceOf(msg.sender);

        IRevaUserProxy(userProxyAddress).callVault(vault.vaultAddress, vault.depositTokenAddress, vault.nativeTokenAddress, _payloadHarvest);

        uint nativeTokenProfit = IBEP20(vault.nativeTokenAddress).balanceOf(address(this));
        if (nativeTokenProfit > 0) {
            _convertToReva(vault.nativeTokenAddress, nativeTokenProfit, msg.sender);
        }

        uint depositTokenProfit;
        if (vault.depositTokenAddress == WBNB) {
            depositTokenProfit = address(this).balance;
        } else {
            depositTokenProfit = IBEP20(vault.depositTokenAddress).balanceOf(address(this));
        }
        uint leftoverDepositTokenProfit = 0;
        if (depositTokenProfit > 0) {
            uint profitDistributed = _distributeProfit(depositTokenProfit, vault.depositTokenAddress);
            leftoverDepositTokenProfit = depositTokenProfit.sub(profitDistributed);

            // If withdrawing WBNB, send back BNB
            if (vault.depositTokenAddress == WBNB) {
                safeTransferBNB(msg.sender, address(this).balance);
            } else {
                IBEP20(vault.depositTokenAddress).safeTransfer(msg.sender, leftoverDepositTokenProfit);
            }
        }

        revaChef.claimFor(vault.depositTokenAddress, msg.sender);
        uint postRevaBalance = reva.balanceOf(msg.sender);
        return (leftoverDepositTokenProfit, postRevaBalance.sub(prevRevaBalance));
    }

	receive() external payable {}

    /* ========== Private Functions ========== */

    function _withdrawFromVault(uint _vid, bytes calldata _withdrawPayload) private returns (uint, uint) {
        require(_isApprovedWithdrawMethod(_vid, _withdrawPayload), "unapproved withdraw method");
        VaultInfo memory vault = vaults[_vid];

        uint prevRevaBalance = reva.balanceOf(msg.sender);
        uint userPrincipal = userVaultPrincipal[_vid][msg.sender];
        address userProxyAddress = userProxyContractAddress[msg.sender];
        require(userProxyAddress != address(0), "user proxy doesn't exist");

        IRevaUserProxy(userProxyAddress).callVault(vault.vaultAddress, vault.depositTokenAddress, vault.nativeTokenAddress, _withdrawPayload);

        uint vaultNativeTokenAmount = IBEP20(vault.nativeTokenAddress).balanceOf(address(this));
        if (vaultNativeTokenAmount > 0) {
            _convertToReva(vault.nativeTokenAddress, vaultNativeTokenAmount, msg.sender);
        }

        uint vaultDepositTokenAmount;
        if (vault.depositTokenAddress == WBNB) {
            vaultDepositTokenAmount = address(this).balance;
        }
        else {
            vaultDepositTokenAmount = IBEP20(vault.depositTokenAddress).balanceOf(address(this));
        }
        
        if (vaultDepositTokenAmount > userPrincipal) {
            uint profitDistributed = _distributeProfit(vaultDepositTokenAmount.sub(userPrincipal), vault.depositTokenAddress);
            vaultDepositTokenAmount = vaultDepositTokenAmount.sub(profitDistributed);

            // If withdrawing WBNB, send back BNB
            if (vault.depositTokenAddress == WBNB) {
                safeTransferBNB(msg.sender, address(this).balance);
            } else {
                IBEP20(vault.depositTokenAddress).safeTransfer(msg.sender, vaultDepositTokenAmount);
            }

            userVaultPrincipal[_vid][msg.sender] = 0;
            revaChef.notifyWithdrawn(msg.sender, vault.depositTokenAddress, userPrincipal);
        } else {
            // If withdrawing WBNB, send back BNB
            if (vault.depositTokenAddress == WBNB) {
                safeTransferBNB(msg.sender, address(this).balance);
            } else {
                IBEP20(vault.depositTokenAddress).safeTransfer(msg.sender, vaultDepositTokenAmount);
            }

            userVaultPrincipal[_vid][msg.sender] = userPrincipal.sub(vaultDepositTokenAmount);
            revaChef.notifyWithdrawn(msg.sender, vault.depositTokenAddress, vaultDepositTokenAmount);
        }

        uint postRevaBalance = reva.balanceOf(msg.sender);
        return (vaultDepositTokenAmount, postRevaBalance.sub(prevRevaBalance));
    }

    function _depositToVault(uint _amount, uint _vid, bytes calldata _depositPayload, address _user, address _from) private {
        require(_isApprovedDepositMethod(_vid, _depositPayload), "unapproved deposit method");
        VaultInfo memory vault = vaults[_vid];

        address userProxyAddress = userProxyContractAddress[_user];
        if (userProxyAddress == address(0)) {
            userProxyAddress = revaUserProxyFactory.createUserProxy();
            userProxyContractAddress[_user] = userProxyAddress;
        }

        if (msg.value > 0) {
            require(msg.value == _amount, "msg.value doesn't match amount");
            IRevaUserProxy(userProxyAddress).callDepositVault{ value: msg.value }(vault.vaultAddress, vault.depositTokenAddress, vault.nativeTokenAddress, msg.value, _depositPayload);
        } else {
            IBEP20(vault.depositTokenAddress).safeTransferFrom(_from, userProxyAddress, _amount);
            IRevaUserProxy(userProxyAddress).callDepositVault(vault.vaultAddress, vault.depositTokenAddress, vault.nativeTokenAddress, _amount, _depositPayload);
        }

        _handleDepositHarvest(vault.nativeTokenAddress, _user);

        revaChef.notifyDeposited(_user, vault.depositTokenAddress, _amount);
        userVaultPrincipal[_vid][_user] = userVaultPrincipal[_vid][_user].add(_amount);
    }


    function _withdrawFromUnderlyingVault(address _user, VaultInfo memory vault, uint _vid, bytes calldata _payload) private returns (uint) {
        address userProxyAddress = userProxyContractAddress[_user];
        uint userPrincipal = userVaultPrincipal[_vid][_user];

        IRevaUserProxy(userProxyAddress).callVault(vault.vaultAddress, vault.depositTokenAddress, vault.nativeTokenAddress, _payload);

        uint depositTokenAmount;
        if (vault.depositTokenAddress == WBNB) {
            depositTokenAmount = address(this).balance;
        } else {
            depositTokenAmount = IBEP20(vault.depositTokenAddress).balanceOf(address(this));
        }
        uint vaultNativeTokenAmount = IBEP20(vault.nativeTokenAddress).balanceOf(address(this));

        if (vaultNativeTokenAmount > 0) {
            _convertToReva(vault.nativeTokenAddress, vaultNativeTokenAmount, _user);
        }

        if (depositTokenAmount > userPrincipal) {
            uint depositTokenProfit = depositTokenAmount.sub(userPrincipal);
            uint profitDistributed = _distributeProfit(depositTokenProfit, vault.depositTokenAddress);
            uint leftoverDepositToken = depositTokenAmount.sub(profitDistributed);

            userVaultPrincipal[_vid][_user] = 0;
            return leftoverDepositToken;
        } else {
            userVaultPrincipal[_vid][_user] = userPrincipal.sub(depositTokenAmount);
            return depositTokenAmount;
        }
    }

    function _handleDepositHarvest(address vaultNativeTokenAddress, address user) private {
        uint vaultNativeTokenAmount = IBEP20(vaultNativeTokenAddress).balanceOf(address(this));
        if (vaultNativeTokenAmount > 0) {
            _convertToReva(vaultNativeTokenAddress, vaultNativeTokenAmount, user);
        }
    }

    function _convertToReva(address fromToken, uint amount, address to) private {
        if (fromToken == WBNB) {
            zap.zapInTo{ value: amount }(address(reva), to);
            return;
        }
        if (!haveApprovedTokenToZap[fromToken]) {
            IBEP20(fromToken).approve(address(zap), uint(~0));
            haveApprovedTokenToZap[fromToken] = true;
        }
        zap.zapInTokenTo(fromToken, amount, address(reva), to);
    }

    function _isApprovedDepositMethod(uint vid, bytes memory payload) internal view returns (bool) {
        bytes4 sig;
        assembly {
            sig := mload(add(payload, 32))
        }
        return approvedDepositPayloads[vid][sig];
    }

    function _isApprovedWithdrawMethod(uint vid, bytes memory payload) internal view returns (bool) {
        bytes4 sig;
        assembly {
            sig := mload(add(payload, 32))
        }
        return approvedWithdrawPayloads[vid][sig];
    }

    function _isApprovedHarvestMethod(uint vid, bytes memory payload) internal view returns (bool) {
        bytes4 sig;
        assembly {
            sig := mload(add(payload, 32))
        }
        return approvedHarvestPayloads[vid][sig];
    }

    function _distributeProfit(uint profitTokens, address depositTokenAddress)
            private returns (uint profitDistributed) {
        uint profitToRevaTokens = profitTokens.mul(profitToReva).div(PROFIT_DISTRIBUTION_PRECISION);
        uint profitToRevaStakersTokens = profitTokens.mul(profitToRevaStakers).div(PROFIT_DISTRIBUTION_PRECISION);
        
        _convertToReva(depositTokenAddress, profitToRevaTokens, msg.sender);
        _convertToReva(depositTokenAddress, profitToRevaStakersTokens, revaFeeReceiver);

        return profitToRevaTokens.add(profitToRevaStakersTokens);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // salvage purpose only for when stupid people send tokens here
    function withdrawToken(address tokenToWithdraw, uint amount) external onlyOwner {
        IBEP20(tokenToWithdraw).safeTransfer(msg.sender, amount);
    }

    function addVault(
        address _vaultAddress,
        address _depositTokenAddress,
        address _nativeTokenAddress
    ) external nonDuplicateVault(_vaultAddress, _depositTokenAddress, _nativeTokenAddress) onlyAdminOrOwner {
        require(_vaultAddress != address(0), 'zero address');
        vaults.push(VaultInfo(_vaultAddress, _depositTokenAddress, _nativeTokenAddress));
        vaultExists[keccak256(abi.encodePacked(_vaultAddress, _depositTokenAddress, _nativeTokenAddress))] = true;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
        emit SetAdmin(admin);
    }

    function setDepositMethod(uint _vid, bytes4 _methodSig, bool _approved) external onlyAdminOrOwner {
        approvedDepositPayloads[_vid][_methodSig] = _approved;
    }

    function setWithdrawMethod(uint _vid, bytes4 _methodSig, bool _approved) external onlyAdminOrOwner {
        approvedWithdrawPayloads[_vid][_methodSig] = _approved;
    }

    function setHarvestMethod(uint _vid, bytes4 _methodSig, bool _approved) external onlyAdminOrOwner {
        approvedHarvestPayloads[_vid][_methodSig] = _approved;
    }

    function setProfitToReva(uint _profitToReva) external onlyOwner {
        require(_profitToReva <= MAX_PROFIT_TO_REVA, "MAX_PROFIT_TO_REVA");
        profitToReva = _profitToReva;
        emit SetProfitToReva(_profitToReva);
    }

    function setProfitToRevaStakers(uint _profitToRevaStakers) external onlyOwner {
        require(_profitToRevaStakers <= MAX_PROFIT_TO_REVA_STAKERS, "MAX_PROFIT_TO_REVA_STAKERS");
        profitToRevaStakers = _profitToRevaStakers;
        emit SetProfitToRevaStakers(_profitToRevaStakers);
    }

    function setZapAndDeposit(address _zapAndDeposit) external onlyOwner {
        zapAndDeposit = _zapAndDeposit;
        emit SetZapAndDeposit(_zapAndDeposit);
    }
}