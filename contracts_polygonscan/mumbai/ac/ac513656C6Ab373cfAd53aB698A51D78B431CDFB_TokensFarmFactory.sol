/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol


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


// File @openzeppelin/contracts/math/SafeMath.sol


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


// File @openzeppelin/contracts/utils/Address.sol


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


// File @openzeppelin/contracts/token/ERC20/SafeERC20.sol


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


// File @openzeppelin/contracts/proxy/Initializable.sol


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
        return !Address.isContract(address(this));
    }
}


// File @openzeppelin/contracts/proxy/Clones.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}


// File contracts/governance/IMaintainersRegistry.sol

pragma solidity 0.6.12;

interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/governance/ICongressMembersRegistry.sol

pragma solidity 0.6.12;

/**
 * ICongressMembersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 13.9.21.
 * Github: madjarevicn
 */

interface ICongressMembersRegistry {
    function isMember(address _address) external view returns (bool);
    function getMinimalQuorum() external view returns (uint256);
}


// File contracts/system/TokensFarmUpgradable.sol

pragma solidity 0.6.12;


//to be fixed
contract TokensFarmUpgradable {

    // Address of tokens congress
    address public tokensFarmCongress;
    // Instance of maintainers registry object
    IMaintainersRegistry public maintainersRegistry;

    // Only maintainer modifier
    modifier onlyMaintainer {
        require(
            maintainersRegistry.isMaintainer(msg.sender),
            "TokensFarmUpgradable: Restricted only to Maintainer"
        );
        _;
    }

    // Only tokens farm congress modifier
    modifier onlyTokensFarmCongress {
        require(
            msg.sender == tokensFarmCongress,
            "TokensFarmUpgradable: Restricted only to TokensFarmCongress"
        );
        _;
    }

    /**
     * @notice function to set congress and maintainers registry address
     *
     * @param _tokensFarmCongress - address of tokens farm congress
     * @param _maintainersRegistry - address of maintainers registry
     */
    function setCongressAndMaintainersRegistry(
        address _tokensFarmCongress,
        address _maintainersRegistry
    )
        internal
    {
        require(
            _tokensFarmCongress != address(0x0),
            "tokensFarmCongress can not be 0x0 address"
        );
        require(
            _maintainersRegistry != address(0x0),
            "_maintainersRegistry can not be 0x0 address"
        );

        tokensFarmCongress = _tokensFarmCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

    /**
     * @notice function to set new maintainers registry address
     *
     * @param _maintainersRegistry - address of new maintainers registry
     */
    function setMaintainersRegistry(
        address _maintainersRegistry
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _maintainersRegistry != address(0x0),
            "_maintainersRegistry can not be 0x0 address"
        );

        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

    /**
    * @notice function to set new congress registry address
    *
    * @param _tokensFarmCongress - address of new tokens farm congress
    */
    function setTokensFarmCongress(
        address _tokensFarmCongress
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _tokensFarmCongress != address(0x0),
            "_maintainersRegistry can not be 0x0 address"
        );

        tokensFarmCongress = _tokensFarmCongress;
    }
}


// File contracts/interfaces/ITokensFarm.sol

pragma solidity 0.6.12;

interface ITokensFarm {
    function fund(uint256 _amount) external;
    function setMinTimeToStake(uint256 _minTimeToStake) external;
    function setIsEarlyWithdrawAllowed(bool _isEarlyWithdrawAllowed) external;
    function setStakeFeePercent(uint256 _stakeFeePercent) external;
    function setRewardFeePercent(uint256 _rewardFeePercent) external;
    function setFlatFeeAmount(uint256 _flatFeeAmount) external;
    function setIsFlatFeeAllowed(bool _isFlatFeeAllowed) external;
    function withdrawCollectedFeesERC() external;
    function withdrawCollectedFeesETH() external;
    function withdrawTokensIfStuck(address _erc20, uint256 _amount, address _beneficiary) external;
    function initialize(
        address _erc20, uint256 _rewardPerSecond, uint256 _startTime, uint256 _minTimeToStake,
        bool _isEarlyWithdrawAllowed, uint256 _penalty, address _tokenStaked, uint256 _stakeFeePercent,
        uint256 _rewardFeePercent, uint256 _flatFeeAmount, address payable _feeCollector, bool _isFlatFeeAllowed,
        address _farmImplementation
    ) external;
    function setFeeCollector(address payable _feeCollector) external;
}


// File contracts/TokensFarmFactory.sol

pragma solidity 0.6.12;






contract TokensFarmFactory is TokensFarmUpgradable, Initializable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Clones for *;

    // Array of Tokens Farm that are deployed
    address[] public deployedTokensFarms;

    // FeeCollector + CongressAddress
    address payable public feeCollector;

    // Address of deployed tokens farm contract
    address public farmImplementation;

    // Events
    event DeployedFarm(address indexed farmAddress);
    event TokensFarmImplementationSet(address indexed farmImplementation);
    event FeeCollectorSet(address indexed feeCollector);

    /**
     * @notice function sets initial state of contract
     *
     * @param _farmImplementation- address of deployed farm
     * @param _tokensFarmCongress - address of farm congress
     * @param _maintainersRegistry - address of maintainers registry
     * @param _feeCollector - address of feeCollector
     */
    function initialize(
        address _farmImplementation,
        address _tokensFarmCongress,
        address _maintainersRegistry,
        address payable _feeCollector
    )
        external
        initializer
    {
        require(
            _farmImplementation != address(0),
            "farmImplementation can not be 0x0 address"
        );
        require(
            _feeCollector != address(0),
            "_feeCollector can not be 0x0 address"
        );

        // set congress and maintainers registry address
        setCongressAndMaintainersRegistry(
            _tokensFarmCongress,
            _maintainersRegistry
        );

        // address of fee collector
        feeCollector = _feeCollector;
        // address of tokens farm contract
        farmImplementation = _farmImplementation;
    }

    /**
     * @notice function funds the farm
     *
     * @param _farmAddress - function will operate on
     * farm with this address
     * @param _rewardToken - address of reward token
     * @param _amount - funding the farm with this amount of tokens
     */
    function _fundInternal(
        address _farmAddress,
        address _rewardToken,
        uint256 _amount
    )
        internal
    {
        require(
            _farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );

        // instance of erc20 contract
        IERC20 rewardToken = IERC20(_rewardToken);
        // approval of transaction
        rewardToken.approve(_farmAddress, _amount);

        ITokensFarm tokensFarm = ITokensFarm(_farmAddress);
        tokensFarm.fund(_amount);
    }

    /**
     * @notice function to check does factory has enough funds
     *
     * @param _rewardToken - address of reward token
     * @param _totalBudget - funding the farm
     * with this amount of tokens
     */
    function _sufficientFunds(
        address _rewardToken,
        uint256 _totalBudget
    )
        internal
        view
        returns(bool)
    {
        // instance of erc20 contract
        IERC20 rewardToken = IERC20(_rewardToken);
        return rewardToken.balanceOf(address(this)) >= _totalBudget;
    }

    /**
     * @notice function deploys and funds farms
     *
     * @dev store their addresses in array
     * @dev deploys tokens farm proxy contract
     * @dev initializing of contract
     *
     * @param _rewardToken - address of reward token
     * @param _rewardPerSecond - number of reward per second
     * @param _minTimeToStake - how much time needs to past before staking
     * @param _isEarlyWithdrawAllowed - is early withdraw allowed or not
     * @param _penalty - ENUM(what type of penalty)
     * @param _tokenStaked - address of token which is staked
     * @param _stakeFeePercent - fee percent for staking
     * @param _rewardFeePercent - fee percent for reward distribution
     * @param _flatFeeAmount - flat fee amount
     * @param _isFlatFeeAllowed - is flat fee  allowed or not
     */
    function deployAndFundTokensFarm(
        address _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _minTimeToStake,
        bool _isEarlyWithdrawAllowed,
        uint256 _penalty,
        address _tokenStaked,
        uint256 _stakeFeePercent,
        uint256 _rewardFeePercent,
        uint256 _flatFeeAmount,
        bool _isFlatFeeAllowed,
        uint256 _totalBudget
    )
        external
        onlyMaintainer
    {
        require(
            _sufficientFunds(_rewardToken, _totalBudget),
            "There is not enough tokens left in factory to fund"
        );

        // Creates clone of TokensFarm smart contract
        address clone = Clones.clone(farmImplementation);

        // Deploy tokens farm;
        ITokensFarm(clone).initialize(
            _rewardToken,
            _rewardPerSecond,
            block.timestamp + 10,
            _minTimeToStake,
            _isEarlyWithdrawAllowed,
            _penalty,
            _tokenStaked,
            _stakeFeePercent,
            _rewardFeePercent,
            _flatFeeAmount,
            feeCollector,
            _isFlatFeeAllowed,
            farmImplementation
        );

        // Add deployed farm to array of deployed farms
        deployedTokensFarms.push(clone);
        // Funding the farm
        _fundInternal(clone, _rewardToken, _totalBudget);
        // Emits event with farms address
        emit DeployedFarm(clone);
    }

    /**
     * @notice function funds again the farm if necessary
     *
     * @param farmAddress - function will operate
     * on farm with this address
     * param rewardToken - address of reward token
     * @param amount - funding the farm with this amount of tokens
     */
    function fundTheSpecificFarm(
        address farmAddress,
        address rewardToken,
        uint256 amount
    )
        external
        onlyMaintainer
    {
        _fundInternal(farmAddress, rewardToken, amount);
    }

    /**
     * @notice function withdraws collected fees in ERC value
     *
     * @param farmAddress - function will operate on
     * farm with this address
     */
    function withdrawCollectedFeesERCOnSpecificFarm(
        address farmAddress
    )
        external
        onlyTokensFarmCongress
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );


        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.withdrawCollectedFeesERC();
    }

    /**
     * @notice function withdraws collected fees in ETH value
     *
     * @param farmAddress - function will operate on
     * farm with this address
     */
    function withdrawCollectedFeesETHOnSpecificFarm(
        address farmAddress
    )
        external
        onlyTokensFarmCongress
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );

        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.withdrawCollectedFeesETH();
    }

    /**
     * @notice function withdraws stuck tokens on farm
     *
     * @param farmAddress - function will operate on
     * farm with this address
     * @param _erc20 - address of token that is stuck
     * @param _amount - how many was deposited
     * @param _beneficiary - address of user
     * that deposited by mistake
     */
    function withdrawTokensIfStuckOnSpecificFarm(
        address farmAddress,
        address _erc20,
        uint256 _amount,
        address _beneficiary
    )
        external
        onlyTokensFarmCongress
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );

        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.withdrawTokensIfStuck(_erc20, _amount, _beneficiary);
    }

    /**
     * @notice function is setting address of deployed
     * tokens farm contract
     *
     * @param  _farmImplementation - address of new tokens farm contract
     */
    function setTokensFarmImplementation(
        address _farmImplementation
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _farmImplementation != address(0),
            "farmImplementation can not be 0x0 address"
        );

        farmImplementation = _farmImplementation;
        emit TokensFarmImplementationSet(farmImplementation);
    }

    /**
     * @notice function is setting new address of fee collector
     *
     * @param  _feeCollector - address of new fee collector
     */
    function setFeeCollector(
        address payable _feeCollector
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _feeCollector != address(0),
            "Fee Collector can not be 0x0 address"
        );

        feeCollector = _feeCollector;
        emit FeeCollectorSet(feeCollector);
    }

    /**
     * @notice function is setting new address of fee collector
     * on active farm
     *
     * @param  farmAddress - address of farm
     */
    function setCurrentFeeCollectorOnSpecificFarm(
        address farmAddress
    )
        external
        onlyTokensFarmCongress
    {
        require(
            farmAddress != address(0x0),
            "Farm address can not be 0x0 address"
        );

        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.setFeeCollector(feeCollector);
    }

    /**
     * @notice function is setting variable minTimeToStake in tokens farm
     *
     * @param farmAddress - function will operate on farm with this address
     * @param _minTimeToStake - value of variable that needs to be set
     */
    function setMinTimeToStakeOnSpecificFarm(
        address farmAddress,
        uint256 _minTimeToStake
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );
        require(_minTimeToStake >= 0, "Minimal time can't be under 0");


        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.setMinTimeToStake(_minTimeToStake);
    }

    /**
     * @notice function is setting state if isEarlyWithdrawAllowed in tokens farm
     *
     * @param farmAddress - function will operate on farm with this address
     * @param _isEarlyWithdrawAllowed - state of variable that needs to be set
     */
    function setIsEarlyWithdrawAllowedOnSpecificFarm(
        address farmAddress,
        bool _isEarlyWithdrawAllowed
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );

        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.setIsEarlyWithdrawAllowed(_isEarlyWithdrawAllowed);
    }

    /**
     * @notice function is setting variable stakeFeePercent in tokens farm
     *
     * @param farmAddress - function will operate on farm with this address
     * @param _stakeFeePercent - value of variable that needs to be set
     */
    function setStakeFeePercentOnSpecificFarm(
        address farmAddress,
        uint256 _stakeFeePercent
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );
        require(
            _stakeFeePercent > 0 && _stakeFeePercent < 100,
            "Stake fee percent must be between 0 and 100"
        );

        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.setStakeFeePercent(_stakeFeePercent);
    }

    /**
     * @notice function is setting variable rewardFeePercent in tokens farm
     *
     * @param farmAddress - function will operate on farm with this address
     * @param _rewardFeePercent - value of variable that needs to be set
     */
    function setRewardFeePercentOnSpecificFarm(
        address farmAddress,
        uint256 _rewardFeePercent
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );
        require(
            _rewardFeePercent > 0 && _rewardFeePercent < 100,
            "Reward fee percent must be between 0 and 100"
        );

        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.setRewardFeePercent(_rewardFeePercent);
    }

    /**
     * @notice function is setting variable flatFeeAmount in tokens farm
     *
     * @param farmAddress - function will operate on farm with this address
     * @param _flatFeeAmount - value of variable that needs to be set
     */
    function setFlatFeeAmountOnSpecificFarm(
        address farmAddress,
        uint256 _flatFeeAmount
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );
        require(_flatFeeAmount >= 0, "Flat fee can't be under 0");

        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.setFlatFeeAmount(_flatFeeAmount);
    }

    /**
     * @notice function is setting variable isFlatFeeAllowed in tokens farm
     *
     * @param farmAddress - function will operate on farm with this address
     * @param _isFlatFeeAllowed - state of variable that needs to be set
     */
    function setIsFlatFeeAllowedOnSpecificFarm(
        address farmAddress,
        bool _isFlatFeeAllowed
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );

        ITokensFarm tokensFarm = ITokensFarm(farmAddress);
        tokensFarm.setIsFlatFeeAllowed(_isFlatFeeAllowed);
    }

    /**
     * @notice function returns address of last deployed farm
     *
     * @dev can be used on BE as additional checksum next to event emitted in tx
     *
     * @return address of last deployed farm
     */
    function getLastDeployedFarm()
        external
        view
        returns (address)
    {
        if (deployedTokensFarms.length == 0) {
            // Means no farms deployed yet.
            return address(0);
        }

        // Deployed last deployed farm.
        return deployedTokensFarms[deployedTokensFarms.length - 1];
    }

    /**
     * @notice function returns array,
     * of deployed farms(from start to end)
     *
     * @param start - beginning index of array
     * @param end - ending index of array
     *
     * @return array made of address of deployed tokens farm
     */
    function getDeployedTokensFarm(
        uint256 start,
        uint256 end
    )
        external
        view
        returns (address[] memory)
    {
        require(start < end, "Start should be less than end");
        require(
            start >= 0 && end <= deployedTokensFarms.length,
            "One of the index is out of range"
        );

        address[] memory tokensFarms = new address[](end - start);
        uint256 counter;

        for (uint256 i = start; i < end; i++) {
            tokensFarms[counter] = deployedTokensFarms[i];
            counter++;
        }

        return tokensFarms;
    }
}