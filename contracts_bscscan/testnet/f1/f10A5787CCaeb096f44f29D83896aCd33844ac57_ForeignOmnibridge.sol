/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.7.0;

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

// File: contracts/upgradeability/EternalStorage.sol

pragma solidity 0.7.5;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

// File: contracts/upgradeable_contracts/Initializable.sol

pragma solidity 0.7.5;

contract Initializable is EternalStorage {
    bytes32 internal constant INITIALIZED = 0x0a6f646cd611241d8073675e00d1a1ff700fbf1b53fcf473de56d1e6e4b714ba; // keccak256(abi.encodePacked("isInitialized"))

    function setInitialize() internal {
        boolStorage[INITIALIZED] = true;
    }

    function isInitialized() public view returns (bool) {
        return boolStorage[INITIALIZED];
    }
}

// File: contracts/interfaces/IUpgradeabilityOwnerStorage.sol

pragma solidity 0.7.5;

interface IUpgradeabilityOwnerStorage {
    function upgradeabilityOwner() external view returns (address);
}

// File: contracts/upgradeable_contracts/Upgradeable.sol

pragma solidity 0.7.5;

contract Upgradeable {
    /**
     * @dev Throws if called by any account other than the upgradeability owner.
     */
    modifier onlyIfUpgradeabilityOwner() {
        _onlyIfUpgradeabilityOwner();
        _;
    }

    /**
     * @dev Internal function for reducing onlyIfUpgradeabilityOwner modifier bytecode overhead.
     */
    function _onlyIfUpgradeabilityOwner() internal view {
        require(msg.sender == IUpgradeabilityOwnerStorage(address(this)).upgradeabilityOwner());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.7.0;




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

// File: contracts/upgradeable_contracts/Sacrifice.sol

pragma solidity 0.7.5;

contract Sacrifice {
    constructor(address payable _recipient) payable {
        selfdestruct(_recipient);
    }
}

// File: contracts/libraries/AddressHelper.sol

pragma solidity 0.7.5;

/**
 * @title AddressHelper
 * @dev Helper methods for Address type.
 */
library AddressHelper {
    /**
     * @dev Try to send native tokens to the address. If it fails, it will force the transfer by creating a selfdestruct contract
     * @param _receiver address that will receive the native tokens
     * @param _value the amount of native tokens to send
     */
    function safeSendValue(address payable _receiver, uint256 _value) internal {
        if (!(_receiver).send(_value)) {
            new Sacrifice{ value: _value }(_receiver);
        }
    }
}

// File: contracts/upgradeable_contracts/Claimable.sol

pragma solidity 0.7.5;

/**
 * @title Claimable
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 */
contract Claimable {
    using SafeERC20 for IERC20;

    /**
     * Throws if a given address is equal to address(0)
     */
    modifier validAddress(address _to) {
        require(_to != address(0));
        _;
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to) internal validAddress(_to) {
        if (_token == address(0)) {
            claimNativeCoins(_to);
        } else {
            claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function claimNativeCoins(address _to) internal {
        uint256 value = address(this).balance;
        AddressHelper.safeSendValue(payable(_to), value);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc20Tokens(address _token, address _to) internal {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }
}

// File: contracts/upgradeable_contracts/components/bridged/BridgedTokensRegistry.sol

pragma solidity 0.7.5;

/**
 * @title BridgedTokensRegistry
 * @dev Functionality for keeping track of registered bridged token pairs.
 */
contract BridgedTokensRegistry is EternalStorage {
    event NewTokenRegistered(address indexed nativeToken, address indexed bridgedToken);

    /**
     * @dev Retrieves address of the bridged token contract associated with a specific native token contract on the other side.
     * @param _nativeToken address of the native token contract on the other side.
     * @return address of the deployed bridged token contract.
     */
    function bridgedTokenAddress(address _nativeToken) public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("homeTokenAddress", _nativeToken))];
    }

    /**
     * @dev Retrieves address of the native token contract associated with a specific bridged token contract.
     * @param _bridgedToken address of the created bridged token contract on this side.
     * @return address of the native token contract on the other side of the bridge.
     */
    function nativeTokenAddress(address _bridgedToken) public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("foreignTokenAddress", _bridgedToken))];
    }

    /**
     * @dev Internal function for updating a pair of addresses for the bridged token.
     * @param _nativeToken address of the native token contract on the other side.
     * @param _bridgedToken address of the created bridged token contract on this side.
     */
    function _setTokenAddressPair(address _nativeToken, address _bridgedToken) internal {
        addressStorage[keccak256(abi.encodePacked("homeTokenAddress", _nativeToken))] = _bridgedToken;
        addressStorage[keccak256(abi.encodePacked("foreignTokenAddress", _bridgedToken))] = _nativeToken;

        emit NewTokenRegistered(_nativeToken, _bridgedToken);
    }
}

// File: contracts/upgradeable_contracts/components/native/NativeTokensRegistry.sol

pragma solidity 0.7.5;

/**
 * @title NativeTokensRegistry
 * @dev Functionality for keeping track of registered native tokens.
 */
contract NativeTokensRegistry is EternalStorage {
    /**
     * @dev Checks if for a given native token, the deployment of its bridged alternative was already acknowledged.
     * @param _token address of native token contract.
     * @return true, if bridged token was already deployed.
     */
    function isBridgedTokenDeployAcknowledged(address _token) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("ackDeploy", _token))];
    }

    /**
     * @dev Acknowledges the deployment of bridged token contract on the other side.
     * @param _token address of native token contract.
     */
    function _ackBridgedTokenDeploy(address _token) internal {
        if (!boolStorage[keccak256(abi.encodePacked("ackDeploy", _token))]) {
            boolStorage[keccak256(abi.encodePacked("ackDeploy", _token))] = true;
        }
    }
}

// File: contracts/upgradeable_contracts/components/native/MediatorBalanceStorage.sol

pragma solidity 0.7.5;

/**
 * @title MediatorBalanceStorage
 * @dev Functionality for storing expected mediator balance for native tokens.
 */
contract MediatorBalanceStorage is EternalStorage {
    /**
     * @dev Tells the expected token balance of the contract.
     * @param _token address of token contract.
     * @return the current tracked token balance of the contract.
     */
    function mediatorBalance(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token))];
    }

    /**
     * @dev Updates expected token balance of the contract.
     * @param _token address of token contract.
     * @param _balance the new token balance of the contract.
     */
    function _setMediatorBalance(address _token, uint256 _balance) internal {
        uintStorage[keccak256(abi.encodePacked("mediatorBalance", _token))] = _balance;
    }
}

// File: contracts/interfaces/IERC677.sol

pragma solidity 0.7.5;

interface IERC677 is IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// File: contracts/libraries/Bytes.sol

pragma solidity 0.7.5;

/**
 * @title Bytes
 * @dev Helper methods to transform bytes to other solidity types.
 */
library Bytes {
    /**
     * @dev Truncate bytes array if its size is more than 20 bytes.
     * NOTE: This function does not perform any checks on the received parameter.
     * Make sure that the _bytes argument has a correct length, not less than 20 bytes.
     * A case when _bytes has length less than 20 will lead to the undefined behaviour,
     * since assembly will read data from memory that is not related to the _bytes argument.
     * @param _bytes to be converted to address type
     * @return addr address included in the firsts 20 bytes of the bytes array in parameter.
     */
    function bytesToAddress(bytes memory _bytes) internal pure returns (address addr) {
        assembly {
            addr := mload(add(_bytes, 20))
        }
    }
}

// File: contracts/upgradeable_contracts/ReentrancyGuard.sol

pragma solidity 0.7.5;

contract ReentrancyGuard {
    function lock() internal view returns (bool res) {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            res := sload(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92) // keccak256(abi.encodePacked("lock"))
        }
    }

    function setLock(bool _lock) internal {
        assembly {
            // Even though this is not the same as boolStorage[keccak256(abi.encodePacked("lock"))],
            // since solidity mapping introduces another level of addressing, such slot change is safe
            // for temporary variables which are cleared at the end of the call execution.
            sstore(0x6168652c307c1e813ca11cfb3a601f1cf3b22452021a5052d8b05f1f1f8a3e92, _lock) // keccak256(abi.encodePacked("lock"))
        }
    }
}

// File: contracts/upgradeable_contracts/Ownable.sol

pragma solidity 0.7.5;

/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    bytes4 internal constant UPGRADEABILITY_OWNER = 0x6fde8202; // upgradeabilityOwner()

    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Internal function for reducing onlyOwner modifier bytecode overhead.
     */
    function _onlyOwner() internal view {
        require(msg.sender == owner());
    }

    /**
     * @dev Throws if called through proxy by any account other than contract itself or an upgradeability owner.
     */
    modifier onlyRelevantSender() {
        (bool isProxy, bytes memory returnData) =
            address(this).staticcall(abi.encodeWithSelector(UPGRADEABILITY_OWNER));
        require(
            !isProxy || // covers usage without calling through storage proxy
                (returnData.length == 32 && msg.sender == abi.decode(returnData, (address))) || // covers usage through regular proxy calls
                msg.sender == address(this) // covers calls through upgradeAndCall proxy method
        );
        _;
    }

    bytes32 internal constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0; // keccak256(abi.encodePacked("owner"))

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return addressStorage[OWNER];
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner the address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _setOwner(newOwner);
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[OWNER] = newOwner;
    }
}

// File: contracts/interfaces/IAMB.sol

pragma solidity 0.7.5;

interface IAMB {
    event UserRequestForAffirmation(bytes32 indexed messageId, bytes encodedData);
    event UserRequestForSignature(bytes32 indexed messageId, bytes encodedData);
    event AffirmationCompleted(
        address indexed sender,
        address indexed executor,
        bytes32 indexed messageId,
        bool status
    );
    event RelayedMessage(address indexed sender, address indexed executor, bytes32 indexed messageId, bool status);

    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId) external view returns (address);

    function failedMessageSender(bytes32 _messageId) external view returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

// File: contracts/upgradeable_contracts/BasicAMBMediator.sol

pragma solidity 0.7.5;

/**
 * @title BasicAMBMediator
 * @dev Basic storage and methods needed by mediators to interact with AMB bridge.
 */
abstract contract BasicAMBMediator is Ownable {
    bytes32 internal constant BRIDGE_CONTRACT = 0x811bbb11e8899da471f0e69a3ed55090fc90215227fc5fb1cb0d6e962ea7b74f; // keccak256(abi.encodePacked("bridgeContract"))
    bytes32 internal constant MEDIATOR_CONTRACT = 0x98aa806e31e94a687a31c65769cb99670064dd7f5a87526da075c5fb4eab9880; // keccak256(abi.encodePacked("mediatorContract"))

    /**
     * @dev Throws if caller on the other side is not an associated mediator.
     */
    modifier onlyMediator {
        _onlyMediator();
        _;
    }

    /**
     * @dev Internal function for reducing onlyMediator modifier bytecode overhead.
     */
    function _onlyMediator() internal view {
        IAMB bridge = bridgeContract();
        require(msg.sender == address(bridge));
        require(bridge.messageSender() == mediatorContractOnOtherSide());
    }

    /**
     * @dev Sets the AMB bridge contract address. Only the owner can call this method.
     * @param _bridgeContract the address of the bridge contract.
     */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        _setBridgeContract(_bridgeContract);
    }

    /**
     * @dev Sets the mediator contract address from the other network. Only the owner can call this method.
     * @param _mediatorContract the address of the mediator contract.
     */
    function setMediatorContractOnOtherSide(address _mediatorContract) external onlyOwner {
        _setMediatorContractOnOtherSide(_mediatorContract);
    }

    /**
     * @dev Get the AMB interface for the bridge contract address
     * @return AMB interface for the bridge contract address
     */
    function bridgeContract() public view returns (IAMB) {
        return IAMB(addressStorage[BRIDGE_CONTRACT]);
    }

    /**
     * @dev Tells the mediator contract address from the other network.
     * @return the address of the mediator contract.
     */
    function mediatorContractOnOtherSide() public view virtual returns (address) {
        return addressStorage[MEDIATOR_CONTRACT];
    }

    /**
     * @dev Stores a valid AMB bridge contract address.
     * @param _bridgeContract the address of the bridge contract.
     */
    function _setBridgeContract(address _bridgeContract) internal {
        require(Address.isContract(_bridgeContract));
        addressStorage[BRIDGE_CONTRACT] = _bridgeContract;
    }

    /**
     * @dev Stores the mediator contract address from the other network.
     * @param _mediatorContract the address of the mediator contract.
     */
    function _setMediatorContractOnOtherSide(address _mediatorContract) internal {
        addressStorage[MEDIATOR_CONTRACT] = _mediatorContract;
    }

    /**
     * @dev Tells the id of the message originated on the other network.
     * @return the id of the message originated on the other network.
     */
    function messageId() internal view returns (bytes32) {
        return bridgeContract().messageId();
    }

    /**
     * @dev Tells the maximum gas limit that a message can use on its execution by the AMB bridge on the other network.
     * @return the maximum gas limit value.
     */
    function maxGasPerTx() internal view returns (uint256) {
        return bridgeContract().maxGasPerTx();
    }

    function _passMessage(bytes memory _data, bool _useOracleLane) internal virtual returns (bytes32);
}

// File: contracts/upgradeable_contracts/components/common/TokensRelayer.sol

pragma solidity 0.7.5;

/**
 * @title TokensRelayer
 * @dev Functionality for bridging multiple tokens to the other side of the bridge.
 */
abstract contract TokensRelayer is BasicAMBMediator, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC677;

    /**
     * @dev ERC677 transfer callback function.
     * @param _from address of tokens sender.
     * @param _value amount of transferred tokens.
     * @param _data additional transfer data, can be used for passing alternative receiver address.
     */
    function onTokenTransfer(
        address _from,
        uint256 _value,
        bytes memory _data
    ) external returns (bool) {
        if (!lock()) {
            bytes memory data = new bytes(0);
            address receiver = _from;
            if (_data.length >= 20) {
                receiver = Bytes.bytesToAddress(_data);
                if (_data.length > 20) {
                    assembly {
                        let size := sub(mload(_data), 20)
                        data := add(_data, 20)
                        mstore(data, size)
                    }
                }
            }
            bridgeSpecificActionsOnTokenTransfer(msg.sender, _from, receiver, _value, data);
        }
        return true;
    }

    /**
     * @dev Initiate the bridge operation for some amount of tokens from msg.sender.
     * The user should first call Approve method of the ERC677 token.
     * @param token bridged token contract address.
     * @param _receiver address that will receive the native tokens on the other network.
     * @param _value amount of tokens to be transferred to the other network.
     */
    function relayTokens(
        IERC677 token,
        address _receiver,
        uint256 _value
    ) external {
        _relayTokens(token, _receiver, _value, new bytes(0));
    }

    /**
     * @dev Initiate the bridge operation for some amount of tokens from msg.sender to msg.sender on the other side.
     * The user should first call Approve method of the ERC677 token.
     * @param token bridged token contract address.
     * @param _value amount of tokens to be transferred to the other network.
     */
    function relayTokens(IERC677 token, uint256 _value) external {
        _relayTokens(token, msg.sender, _value, new bytes(0));
    }

    /**
     * @dev Initiate the bridge operation for some amount of tokens from msg.sender.
     * The user should first call Approve method of the ERC677 token.
     * @param token bridged token contract address.
     * @param _receiver address that will receive the native tokens on the other network.
     * @param _value amount of tokens to be transferred to the other network.
     * @param _data additional transfer data to be used on the other side.
     */
    function relayTokensAndCall(
        IERC677 token,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) external {
        _relayTokens(token, _receiver, _value, _data);
    }

    /**
     * @dev Validates that the token amount is inside the limits, calls transferFrom to transfer the tokens to the contract
     * and invokes the method to burn/lock the tokens and unlock/mint the tokens on the other network.
     * The user should first call Approve method of the ERC677 token.
     * @param token bridge token contract address.
     * @param _receiver address that will receive the native tokens on the other network.
     * @param _value amount of tokens to be transferred to the other network.
     * @param _data additional transfer data to be used on the other side.
     */
    function _relayTokens(
        IERC677 token,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal {
        // This lock is to prevent calling passMessage twice if a ERC677 token is used.
        // When transferFrom is called, after the transfer, the ERC677 token will call onTokenTransfer from this contract
        // which will call passMessage.
        require(!lock());

        uint256 balanceBefore = token.balanceOf(address(this));
        setLock(true);
        token.safeTransferFrom(msg.sender, address(this), _value);
        setLock(false);
        uint256 balanceDiff = token.balanceOf(address(this)).sub(balanceBefore);
        require(balanceDiff <= _value);
        bridgeSpecificActionsOnTokenTransfer(address(token), msg.sender, _receiver, balanceDiff, _data);
    }

    function bridgeSpecificActionsOnTokenTransfer(
        address _token,
        address _from,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal virtual;
}

// File: contracts/upgradeable_contracts/VersionableBridge.sol

pragma solidity 0.7.5;

interface VersionableBridge {
    function getBridgeInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        );

    function getBridgeMode() external pure returns (bytes4);
}

// File: contracts/upgradeable_contracts/components/common/OmnibridgeInfo.sol

pragma solidity 0.7.5;

/**
 * @title OmnibridgeInfo
 * @dev Functionality for versioning Omnibridge mediator.
 */
contract OmnibridgeInfo is VersionableBridge {
    event TokensBridgingInitiated(
        address indexed token,
        address indexed sender,
        uint256 value,
        bytes32 indexed messageId
    );
    event TokensBridged(address indexed token, address indexed recipient, uint256 value, bytes32 indexed messageId);

    /**
     * @dev Tells the bridge interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getBridgeInterfacesVersion()
        external
        pure
        override
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (3, 3, 0);
    }

    /**
     * @dev Tells the bridge mode that this contract supports.
     * @return _data 4 bytes representing the bridge mode
     */
    function getBridgeMode() external pure override returns (bytes4 _data) {
        return 0xb1516c26; // bytes4(keccak256(abi.encodePacked("multi-erc-to-erc-amb")))
    }
}

// File: contracts/upgradeable_contracts/components/common/TokensBridgeLimits.sol

pragma solidity 0.7.5;

/**
 * @title TokensBridgeLimits
 * @dev Functionality for keeping track of bridging limits for multiple tokens.
 */
contract TokensBridgeLimits is EternalStorage, Ownable {
    using SafeMath for uint256;

    // token == 0x00..00 represents default limits (assuming decimals == 18) for all newly created tokens
    event DailyLimitChanged(address indexed token, uint256 newLimit);
    event ExecutionDailyLimitChanged(address indexed token, uint256 newLimit);

    /**
     * @dev Checks if specified token was already bridged at least once.
     * @param _token address of the token contract.
     * @return true, if token address is address(0) or token was already bridged.
     */
    function isTokenRegistered(address _token) public view returns (bool) {
        return minPerTx(_token) > 0;
    }

    /**
     * @dev Retrieves the total spent amount for particular token during specific day.
     * @param _token address of the token contract.
     * @param _day day number for which spent amount if requested.
     * @return amount of tokens sent through the bridge to the other side.
     */
    function totalSpentPerDay(address _token, uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _token, _day))];
    }

    /**
     * @dev Retrieves the total executed amount for particular token during specific day.
     * @param _token address of the token contract.
     * @param _day day number for which spent amount if requested.
     * @return amount of tokens received from the bridge from the other side.
     */
    function totalExecutedPerDay(address _token, uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _token, _day))];
    }

    /**
     * @dev Retrieves current daily limit for a particular token contract.
     * @param _token address of the token contract.
     * @return daily limit on tokens that can be sent through the bridge per day.
     */
    function dailyLimit(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))];
    }

    /**
     * @dev Retrieves current execution daily limit for a particular token contract.
     * @param _token address of the token contract.
     * @return daily limit on tokens that can be received from the bridge on the other side per day.
     */
    function executionDailyLimit(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))];
    }

    /**
     * @dev Retrieves current maximum amount of tokens per one transfer for a particular token contract.
     * @param _token address of the token contract.
     * @return maximum amount on tokens that can be sent through the bridge in one transfer.
     */
    function maxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))];
    }

    /**
     * @dev Retrieves current maximum execution amount of tokens per one transfer for a particular token contract.
     * @param _token address of the token contract.
     * @return maximum amount on tokens that can received from the bridge on the other side in one transaction.
     */
    function executionMaxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))];
    }

    /**
     * @dev Retrieves current minimum amount of tokens per one transfer for a particular token contract.
     * @param _token address of the token contract.
     * @return minimum amount on tokens that can be sent through the bridge in one transfer.
     */
    function minPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("minPerTx", _token))];
    }

    /**
     * @dev Checks that bridged amount of tokens conforms to the configured limits.
     * @param _token address of the token contract.
     * @param _amount amount of bridge tokens.
     * @return true, if specified amount can be bridged.
     */
    function withinLimit(address _token, uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalSpentPerDay(_token, getCurrentDay()).add(_amount);
        return
            dailyLimit(address(0)) > 0 &&
            dailyLimit(_token) >= nextLimit &&
            _amount <= maxPerTx(_token) &&
            _amount >= minPerTx(_token);
    }

    /**
     * @dev Checks that bridged amount of tokens conforms to the configured execution limits.
     * @param _token address of the token contract.
     * @param _amount amount of bridge tokens.
     * @return true, if specified amount can be processed and executed.
     */
    function withinExecutionLimit(address _token, uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalExecutedPerDay(_token, getCurrentDay()).add(_amount);
        return
            executionDailyLimit(address(0)) > 0 &&
            executionDailyLimit(_token) >= nextLimit &&
            _amount <= executionMaxPerTx(_token);
    }

    /**
     * @dev Returns current day number.
     * @return day number.
     */
    function getCurrentDay() public view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp / 1 days;
    }

    /**
     * @dev Updates daily limit for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the efault limit.
     * @param _dailyLimit daily allowed amount of bridged tokens, should be greater than maxPerTx.
     * 0 value is also allowed, will stop the bridge operations in outgoing direction.
     */
    function setDailyLimit(address _token, uint256 _dailyLimit) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_dailyLimit > maxPerTx(_token) || _dailyLimit == 0);
        uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))] = _dailyLimit;
        emit DailyLimitChanged(_token, _dailyLimit);
    }

    /**
     * @dev Updates execution daily limit for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _dailyLimit daily allowed amount of executed tokens, should be greater than executionMaxPerTx.
     * 0 value is also allowed, will stop the bridge operations in incoming direction.
     */
    function setExecutionDailyLimit(address _token, uint256 _dailyLimit) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_dailyLimit > executionMaxPerTx(_token) || _dailyLimit == 0);
        uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))] = _dailyLimit;
        emit ExecutionDailyLimitChanged(_token, _dailyLimit);
    }

    /**
     * @dev Updates execution maximum per transaction for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _maxPerTx maximum amount of executed tokens per one transaction, should be less than executionDailyLimit.
     * 0 value is also allowed, will stop the bridge operations in incoming direction.
     */
    function setExecutionMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_maxPerTx == 0 || (_maxPerTx > 0 && _maxPerTx < executionDailyLimit(_token)));
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _maxPerTx;
    }

    /**
     * @dev Updates maximum per transaction for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _maxPerTx maximum amount of tokens per one transaction, should be less than dailyLimit, greater than minPerTx.
     * 0 value is also allowed, will stop the bridge operations in outgoing direction.
     */
    function setMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_maxPerTx == 0 || (_maxPerTx > minPerTx(_token) && _maxPerTx < dailyLimit(_token)));
        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _maxPerTx;
    }

    /**
     * @dev Updates minimum per transaction for the particular token. Only owner can call this method.
     * @param _token address of the token contract, or address(0) for configuring the default limit.
     * @param _minPerTx minimum amount of tokens per one transaction, should be less than maxPerTx and dailyLimit.
     */
    function setMinPerTx(address _token, uint256 _minPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_minPerTx > 0 && _minPerTx < dailyLimit(_token) && _minPerTx < maxPerTx(_token));
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _minPerTx;
    }

    /**
     * @dev Retrieves maximum available bridge amount per one transaction taking into account maxPerTx() and dailyLimit() parameters.
     * @param _token address of the token contract, or address(0) for the default limit.
     * @return minimum of maxPerTx parameter and remaining daily quota.
     */
    function maxAvailablePerTx(address _token) public view returns (uint256) {
        uint256 _maxPerTx = maxPerTx(_token);
        uint256 _dailyLimit = dailyLimit(_token);
        uint256 _spent = totalSpentPerDay(_token, getCurrentDay());
        uint256 _remainingOutOfDaily = _dailyLimit > _spent ? _dailyLimit - _spent : 0;
        return _maxPerTx < _remainingOutOfDaily ? _maxPerTx : _remainingOutOfDaily;
    }

    /**
     * @dev Internal function for adding spent amount for some token.
     * @param _token address of the token contract.
     * @param _day day number, when tokens are processed.
     * @param _value amount of bridge tokens.
     */
    function addTotalSpentPerDay(
        address _token,
        uint256 _day,
        uint256 _value
    ) internal {
        uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _token, _day))] = totalSpentPerDay(_token, _day).add(
            _value
        );
    }

    /**
     * @dev Internal function for adding executed amount for some token.
     * @param _token address of the token contract.
     * @param _day day number, when tokens are processed.
     * @param _value amount of bridge tokens.
     */
    function addTotalExecutedPerDay(
        address _token,
        uint256 _day,
        uint256 _value
    ) internal {
        uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _token, _day))] = totalExecutedPerDay(
            _token,
            _day
        )
            .add(_value);
    }

    /**
     * @dev Internal function for initializing limits for some token.
     * @param _token address of the token contract.
     * @param _limits [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ].
     */
    function _setLimits(address _token, uint256[3] memory _limits) internal {
        require(
            _limits[2] > 0 && // minPerTx > 0
                _limits[1] > _limits[2] && // maxPerTx > minPerTx
                _limits[0] > _limits[1] // dailyLimit > maxPerTx
        );

        uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))] = _limits[0];
        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _limits[1];
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _limits[2];

        emit DailyLimitChanged(_token, _limits[0]);
    }

    /**
     * @dev Internal function for initializing execution limits for some token.
     * @param _token address of the token contract.
     * @param _limits [ 0 = executionDailyLimit, 1 = executionMaxPerTx ].
     */
    function _setExecutionLimits(address _token, uint256[2] memory _limits) internal {
        require(_limits[1] < _limits[0]); // foreignMaxPerTx < foreignDailyLimit

        uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))] = _limits[0];
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _limits[1];

        emit ExecutionDailyLimitChanged(_token, _limits[0]);
    }

    /**
     * @dev Internal function for initializing limits for some token relative to its decimals parameter.
     * @param _token address of the token contract.
     * @param _decimals token decimals parameter.
     */
    function _initializeTokenBridgeLimits(address _token, uint256 _decimals) internal {
        uint256 factor;
        if (_decimals < 18) {
            factor = 10**(18 - _decimals);

            uint256 _minPerTx = minPerTx(address(0)).div(factor);
            uint256 _maxPerTx = maxPerTx(address(0)).div(factor);
            uint256 _dailyLimit = dailyLimit(address(0)).div(factor);
            uint256 _executionMaxPerTx = executionMaxPerTx(address(0)).div(factor);
            uint256 _executionDailyLimit = executionDailyLimit(address(0)).div(factor);

            // such situation can happen when calculated limits relative to the token decimals are too low
            // e.g. minPerTx(address(0)) == 10 ** 14, _decimals == 3. _minPerTx happens to be 0, which is not allowed.
            // in this case, limits are raised to the default values
            if (_minPerTx == 0) {
                // Numbers 1, 100, 10000 are chosen in a semi-random way,
                // so that any token with small decimals can still be bridged in some amounts.
                // It is possible to override limits for the particular token later if needed.
                _minPerTx = 1;
                if (_maxPerTx <= _minPerTx) {
                    _maxPerTx = 100;
                    _executionMaxPerTx = 100;
                    if (_dailyLimit <= _maxPerTx || _executionDailyLimit <= _executionMaxPerTx) {
                        _dailyLimit = 10000;
                        _executionDailyLimit = 10000;
                    }
                }
            }
            _setLimits(_token, [_dailyLimit, _maxPerTx, _minPerTx]);
            _setExecutionLimits(_token, [_executionDailyLimit, _executionMaxPerTx]);
        } else {
            factor = 10**(_decimals - 18);
            _setLimits(
                _token,
                [dailyLimit(address(0)).mul(factor), maxPerTx(address(0)).mul(factor), minPerTx(address(0)).mul(factor)]
            );
            _setExecutionLimits(
                _token,
                [executionDailyLimit(address(0)).mul(factor), executionMaxPerTx(address(0)).mul(factor)]
            );
        }
    }
}

// File: contracts/upgradeable_contracts/components/common/BridgeOperationsStorage.sol

pragma solidity 0.7.5;

/**
 * @title BridgeOperationsStorage
 * @dev Functionality for storing processed bridged operations.
 */
abstract contract BridgeOperationsStorage is EternalStorage {
    /**
     * @dev Stores the bridged token of a message sent to the AMB bridge.
     * @param _messageId of the message sent to the bridge.
     * @param _token bridged token address.
     */
    function setMessageToken(bytes32 _messageId, address _token) internal {
        addressStorage[keccak256(abi.encodePacked("messageToken", _messageId))] = _token;
    }

    /**
     * @dev Tells the bridged token address of a message sent to the AMB bridge.
     * @return address of a token contract.
     */
    function messageToken(bytes32 _messageId) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("messageToken", _messageId))];
    }

    /**
     * @dev Stores the value of a message sent to the AMB bridge.
     * @param _messageId of the message sent to the bridge.
     * @param _value amount of tokens bridged.
     */
    function setMessageValue(bytes32 _messageId, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("messageValue", _messageId))] = _value;
    }

    /**
     * @dev Tells the amount of tokens of a message sent to the AMB bridge.
     * @return value representing amount of tokens.
     */
    function messageValue(bytes32 _messageId) internal view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("messageValue", _messageId))];
    }

    /**
     * @dev Stores the receiver of a message sent to the AMB bridge.
     * @param _messageId of the message sent to the bridge.
     * @param _recipient receiver of the tokens bridged.
     */
    function setMessageRecipient(bytes32 _messageId, address _recipient) internal {
        addressStorage[keccak256(abi.encodePacked("messageRecipient", _messageId))] = _recipient;
    }

    /**
     * @dev Tells the receiver of a message sent to the AMB bridge.
     * @return address of the receiver.
     */
    function messageRecipient(bytes32 _messageId) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("messageRecipient", _messageId))];
    }
}

// File: contracts/upgradeable_contracts/components/common/FailedMessagesProcessor.sol

pragma solidity 0.7.5;

/**
 * @title FailedMessagesProcessor
 * @dev Functionality for fixing failed bridging operations.
 */
abstract contract FailedMessagesProcessor is BasicAMBMediator, BridgeOperationsStorage {
    event FailedMessageFixed(bytes32 indexed messageId, address token, address recipient, uint256 value);

    /**
     * @dev Method to be called when a bridged message execution failed. It will generate a new message requesting to
     * fix/roll back the transferred assets on the other network.
     * @param _messageId id of the message which execution failed.
     */
    function requestFailedMessageFix(bytes32 _messageId) external {
        IAMB bridge = bridgeContract();
        require(!bridge.messageCallStatus(_messageId));
        require(bridge.failedMessageReceiver(_messageId) == address(this));
        require(bridge.failedMessageSender(_messageId) == mediatorContractOnOtherSide());

        bytes4 methodSelector = this.fixFailedMessage.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _messageId);
        _passMessage(data, true);
    }

    /**
     * @dev Handles the request to fix transferred assets which bridged message execution failed on the other network.
     * It uses the information stored by passMessage method when the assets were initially transferred
     * @param _messageId id of the message which execution failed on the other network.
     */
    function fixFailedMessage(bytes32 _messageId) public onlyMediator {
        require(!messageFixed(_messageId));

        address token = messageToken(_messageId);
        address recipient = messageRecipient(_messageId);
        uint256 value = messageValue(_messageId);
        setMessageFixed(_messageId);
        executeActionOnFixedTokens(token, recipient, value);
        emit FailedMessageFixed(_messageId, token, recipient, value);
    }

    /**
     * @dev Tells if a message sent to the AMB bridge has been fixed.
     * @return bool indicating the status of the message.
     */
    function messageFixed(bytes32 _messageId) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))];
    }

    /**
     * @dev Sets that the message sent to the AMB bridge has been fixed.
     * @param _messageId of the message sent to the bridge.
     */
    function setMessageFixed(bytes32 _messageId) internal {
        boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))] = true;
    }

    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) internal virtual;
}

// File: contracts/upgradeability/Proxy.sol

pragma solidity 0.7.5;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        // solhint-disable-previous-line no-complex-fallback
        address _impl = implementation();
        require(_impl != address(0));
        assembly {
            /*
                0x40 is the "free memory slot", meaning a pointer to next slot of empty memory. mload(0x40)
                loads the data in the free memory slot, so `ptr` is a pointer to the next slot of empty
                memory. It's needed because we're going to write the return data of delegatecall to the
                free memory slot.
            */
            let ptr := mload(0x40)
            /*
                `calldatacopy` is copy calldatasize bytes from calldata
                First argument is the destination to which data is copied(ptr)
                Second argument specifies the start position of the copied data.
                    Since calldata is sort of its own unique location in memory,
                    0 doesn't refer to 0 in memory or 0 in storage - it just refers to the zeroth byte of calldata.
                    That's always going to be the zeroth byte of the function selector.
                Third argument, calldatasize, specifies how much data will be copied.
                    calldata is naturally calldatasize bytes long (same thing as msg.data.length)
            */
            calldatacopy(ptr, 0, calldatasize())
            /*
                delegatecall params explained:
                gas: the amount of gas to provide for the call. `gas` is an Opcode that gives
                    us the amount of gas still available to execution

                _impl: address of the contract to delegate to

                ptr: to pass copied data

                calldatasize: loads the size of `bytes memory data`, same as msg.data.length

                0, 0: These are for the `out` and `outsize` params. Because the output could be dynamic,
                        these are set to 0, 0 so the output data will not be written to memory. The output
                        data will be read using `returndatasize` and `returdatacopy` instead.

                result: This will be 0 if the call fails and 1 if it succeeds
            */
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            /*

            */
            /*
                ptr current points to the value stored at 0x40,
                because we assigned it like ptr := mload(0x40).
                Because we use 0x40 as a free memory pointer,
                we want to make sure that the next time we want to allocate memory,
                we aren't overwriting anything important.
                So, by adding ptr and returndatasize,
                we get a memory location beyond the end of the data we will be copying to ptr.
                We place this in at 0x40, and any reads from 0x40 will now read from free memory
            */
            mstore(0x40, add(ptr, returndatasize()))
            /*
                `returndatacopy` is an Opcode that copies the last return data to a slot. `ptr` is the
                    slot it will copy to, 0 means copy from the beginning of the return data, and size is
                    the amount of data to copy.
                `returndatasize` is an Opcode that gives us the size of the last return data. In this case, that is the size of the data returned from delegatecall
            */
            returndatacopy(ptr, 0, returndatasize())

            /*
                if `result` is 0, revert.
                if `result` is 1, return `size` amount of data from `ptr`. This is the data that was
                copied to `ptr` from the delegatecall return data
            */
            switch result
                case 0 {
                    revert(ptr, returndatasize())
                }
                default {
                    return(ptr, returndatasize())
                }
        }
    }
}

// File: contracts/upgradeable_contracts/modules/factory/TokenProxy.sol

pragma solidity 0.7.5;

interface IPermittableTokenVersion {
    function version() external pure returns (string memory);
}

/**
 * @title TokenProxy
 * @dev Helps to reduces the size of the deployed bytecode for automatically created tokens, by using a proxy contract.
 */
contract TokenProxy is Proxy {
    // storage layout is copied from PermittableToken.sol
    string internal name;
    string internal symbol;
    uint8 internal decimals;
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply;
    mapping(address => mapping(address => uint256)) internal allowed;
    address internal owner;
    bool internal mintingFinished;
    address internal bridgeContractAddr;
    // string public constant version = "1";
    bytes32 internal DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    mapping(address => uint256) internal nonces;
    mapping(address => mapping(address => uint256)) internal expirations;

    /**
     * @dev Creates a non-upgradeable token proxy for PermitableToken.sol, initializes its eternalStorage.
     * @param _tokenImage address of the token image used for mirroring all functions.
     * @param _name token name.
     * @param _symbol token symbol.
     * @param _decimals token decimals.
     * @param _chainId chain id for current network.
     * @param _owner address of the owner for this contract.
     */
    constructor(
        address _tokenImage,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _chainId,
        address _owner
    ) {
        string memory version = IPermittableTokenVersion(_tokenImage).version();

        assembly {
            // EIP 1967
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _tokenImage)
        }
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = _owner; // _owner == HomeOmnibridge/ForeignOmnibridge mediator
        bridgeContractAddr = _owner;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Retrieves the implementation contract address, mirrored token image.
     * @return impl token image address.
     */
    function implementation() public view override returns (address impl) {
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
    }

    /**
     * @dev Tells the current version of the token proxy interfaces.
     */
    function getTokenProxyInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }
}

// File: contracts/upgradeable_contracts/modules/OwnableModule.sol

pragma solidity 0.7.5;

/**
 * @title OwnableModule
 * @dev Common functionality for multi-token extension non-upgradeable module.
 */
contract OwnableModule {
    address public owner;

    /**
     * @dev Initializes this contract.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Throws if sender is not the owner of this contract.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Changes the owner of this contract.
     * @param _newOwner address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}

// File: contracts/upgradeable_contracts/modules/factory/TokenFactory.sol

pragma solidity 0.7.5;

/**
 * @title TokenFactory
 * @dev Factory contract for deployment of new TokenProxy contracts.
 */
contract TokenFactory is OwnableModule {
    address public tokenImage;

    /**
     * @dev Initializes this contract
     * @param _owner of this factory contract.
     * @param _tokenImage address of the token image contract that should be used for creation of new tokens.
     */
    constructor(address _owner, address _tokenImage) OwnableModule(_owner) {
        tokenImage = _tokenImage;
    }

    /**
     * @dev Tells the module interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getModuleInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }

    /**
     * @dev Updates the address of the used token image contract.
     * Only owner can call this method.
     * @param _tokenImage address of the new token image used for further deployments.
     */
    function setTokenImage(address _tokenImage) external onlyOwner {
        require(Address.isContract(_tokenImage));
        tokenImage = _tokenImage;
    }

    /**
     * @dev Deploys a new TokenProxy contract, using saved token image contract as a template.
     * @param _name deployed token name.
     * @param _symbol deployed token symbol.
     * @param _decimals deployed token decimals.
     * @param _chainId chain id of the current environment.
     * @return address of a newly created contract.
     */
    function deploy(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256 _chainId
    ) external returns (address) {
        return address(new TokenProxy(tokenImage, _name, _symbol, _decimals, _chainId, msg.sender));
    }
}

// File: contracts/upgradeable_contracts/modules/factory/TokenFactoryConnector.sol

pragma solidity 0.7.5;

/**
 * @title TokenFactoryConnector
 * @dev Connectivity functionality for working with TokenFactory contract.
 */
contract TokenFactoryConnector is Ownable {
    bytes32 internal constant TOKEN_FACTORY_CONTRACT =
        0x269c5905f777ee6391c7a361d17039a7d62f52ba9fffeb98c5ade342705731a3; // keccak256(abi.encodePacked("tokenFactoryContract"))

    /**
     * @dev Updates an address of the used TokenFactory contract used for creating new tokens.
     * @param _tokenFactory address of TokenFactory contract.
     */
    function setTokenFactory(address _tokenFactory) external onlyOwner {
        _setTokenFactory(_tokenFactory);
    }

    /**
     * @dev Retrieves an address of the token factory contract.
     * @return address of the TokenFactory contract.
     */
    function tokenFactory() public view returns (TokenFactory) {
        return TokenFactory(addressStorage[TOKEN_FACTORY_CONTRACT]);
    }

    /**
     * @dev Internal function for updating an address of the token factory contract.
     * @param _tokenFactory address of the deployed TokenFactory contract.
     */
    function _setTokenFactory(address _tokenFactory) internal {
        require(Address.isContract(_tokenFactory));
        addressStorage[TOKEN_FACTORY_CONTRACT] = _tokenFactory;
    }
}

// File: contracts/interfaces/IBurnableMintableERC677Token.sol

pragma solidity 0.7.5;

interface IBurnableMintableERC677Token is IERC677 {
    function mint(address _to, uint256 _amount) external returns (bool);

    function burn(uint256 _value) external;

    function claimTokens(address _token, address _to) external;
}

// File: contracts/interfaces/IERC20Metadata.sol

pragma solidity 0.7.5;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: contracts/interfaces/IERC20Receiver.sol

pragma solidity 0.7.5;

interface IERC20Receiver {
    function onTokenBridged(
        address token,
        uint256 value,
        bytes calldata data
    ) external;
}

// File: contracts/libraries/TokenReader.sol

pragma solidity 0.7.5;

// solhint-disable
interface ITokenDetails {
    function name() external view;
    function NAME() external view;
    function symbol() external view;
    function SYMBOL() external view;
    function decimals() external view;
    function DECIMALS() external view;
}
// solhint-enable

/**
 * @title TokenReader
 * @dev Helper methods for reading name/symbol/decimals parameters from ERC20 token contracts.
 */
library TokenReader {
    /**
     * @dev Reads the name property of the provided token.
     * Either name() or NAME() method is used.
     * Both, string and bytes32 types are supported.
     * @param _token address of the token contract.
     * @return token name as a string or an empty string if none of the methods succeeded.
     */
    function readName(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.name.selector));
        if (!status) {
            (status, data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.NAME.selector));
            if (!status) {
                return "";
            }
        }
        return _convertToString(data);
    }

    /**
     * @dev Reads the symbol property of the provided token.
     * Either symbol() or SYMBOL() method is used.
     * Both, string and bytes32 types are supported.
     * @param _token address of the token contract.
     * @return token symbol as a string or an empty string if none of the methods succeeded.
     */
    function readSymbol(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.symbol.selector));
        if (!status) {
            (status, data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.SYMBOL.selector));
            if (!status) {
                return "";
            }
        }
        return _convertToString(data);
    }

    /**
     * @dev Reads the decimals property of the provided token.
     * Either decimals() or DECIMALS() method is used.
     * @param _token address of the token contract.
     * @return token decimals or 0 if none of the methods succeeded.
     */
    function readDecimals(address _token) internal view returns (uint8) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.decimals.selector));
        if (!status) {
            (status, data) = _token.staticcall(abi.encodeWithSelector(ITokenDetails.DECIMALS.selector));
            if (!status) {
                return 0;
            }
        }
        return abi.decode(data, (uint8));
    }

    /**
     * @dev Internal function for converting returned value of name()/symbol() from bytes32/string to string.
     * @param returnData data returned by the token contract.
     * @return string with value obtained from returnData.
     */
    function _convertToString(bytes memory returnData) private pure returns (string memory) {
        if (returnData.length > 32) {
            return abi.decode(returnData, (string));
        } else if (returnData.length == 32) {
            bytes32 data = abi.decode(returnData, (bytes32));
            string memory res = new string(32);
            assembly {
                let len := 0
                mstore(add(res, 32), data) // save value in result string

                // solhint-disable
                for { } gt(data, 0) { len := add(len, 1) } { // until string is empty
                    data := shl(8, data) // shift left by one symbol
                }
                // solhint-enable
                mstore(res, len) // save result string length
            }
            return res;
        } else {
            return "";
        }
    }
}

// File: contracts/libraries/SafeMint.sol

pragma solidity 0.7.5;

/**
 * @title SafeMint
 * @dev Wrapper around the mint() function in all mintable tokens that verifies the return value.
 */
library SafeMint {
    /**
     * @dev Wrapper around IBurnableMintableERC677Token.mint() that verifies that output value is true.
     * @param _token token contract.
     * @param _to address of the tokens receiver.
     * @param _value amount of tokens to mint.
     */
    function safeMint(
        IBurnableMintableERC677Token _token,
        address _to,
        uint256 _value
    ) internal {
        require(_token.mint(_to, _value));
    }
}

// File: contracts/upgradeable_contracts/BasicOmnibridge.sol

pragma solidity 0.7.5;

/**
 * @title BasicOmnibridge
 * @dev Common functionality for multi-token mediator intended to work on top of AMB bridge.
 */
abstract contract BasicOmnibridge is
    Initializable,
    Upgradeable,
    Claimable,
    OmnibridgeInfo,
    TokensRelayer,
    FailedMessagesProcessor,
    BridgedTokensRegistry,
    NativeTokensRegistry,
    MediatorBalanceStorage,
    TokenFactoryConnector,
    TokensBridgeLimits
{
    using SafeERC20 for IERC677;
    using SafeMint for IBurnableMintableERC677Token;
    using SafeMath for uint256;

    // Workaround for storing variable up-to-32 bytes suffix
    uint256 private immutable SUFFIX_SIZE;
    bytes32 private immutable SUFFIX;

    // Since contract is intended to be deployed under EternalStorageProxy, only constant and immutable variables can be set here
    constructor(string memory _suffix) {
        require(bytes(_suffix).length <= 32);
        bytes32 suffix;
        assembly {
            suffix := mload(add(_suffix, 32))
        }
        SUFFIX = suffix;
        SUFFIX_SIZE = bytes(_suffix).length;
    }

    /**
     * @dev Handles the bridged tokens for the first time, includes deployment of new TokenProxy contract.
     * Checks that the value is inside the execution limits and invokes the Mint or Unlock accordingly.
     * @param _token address of the native ERC20/ERC677 token on the other side.
     * @param _name name of the native token, name suffix will be appended, if empty, symbol will be used instead.
     * @param _symbol symbol of the bridged token, if empty, name will be used instead.
     * @param _decimals decimals of the bridge foreign token.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function deployAndHandleBridgedTokens(
        address _token,
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        address _recipient,
        uint256 _value
    ) external onlyMediator {
        address bridgedToken = _getBridgedTokenOrDeploy(_token, _name, _symbol, _decimals);

        _handleTokens(bridgedToken, false, _recipient, _value);
    }

    /**
     * @dev Handles the bridged tokens for the first time, includes deployment of new TokenProxy contract.
     * Executes a callback on the receiver.
     * Checks that the value is inside the execution limits and invokes the Mint accordingly.
     * @param _token address of the native ERC20/ERC677 token on the other side.
     * @param _name name of the native token, name suffix will be appended, if empty, symbol will be used instead.
     * @param _symbol symbol of the bridged token, if empty, name will be used instead.
     * @param _decimals decimals of the bridge foreign token.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     * @param _data additional data passed from the other chain.
     */
    function deployAndHandleBridgedTokensAndCall(
        address _token,
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        address _recipient,
        uint256 _value,
        bytes calldata _data
    ) external onlyMediator {
        address bridgedToken = _getBridgedTokenOrDeploy(_token, _name, _symbol, _decimals);

        _handleTokens(bridgedToken, false, _recipient, _value);

        _receiverCallback(_recipient, bridgedToken, _value, _data);
    }

    /**
     * @dev Handles the bridged tokens for the already registered token pair.
     * Checks that the value is inside the execution limits and invokes the Mint accordingly.
     * @param _token address of the native ERC20/ERC677 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function handleBridgedTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) external onlyMediator {
        address token = bridgedTokenAddress(_token);

        require(isTokenRegistered(token));

        _handleTokens(token, false, _recipient, _value);
    }

    /**
     * @dev Handles the bridged tokens for the already registered token pair.
     * Checks that the value is inside the execution limits and invokes the Unlock accordingly.
     * Executes a callback on the receiver.
     * @param _token address of the native ERC20/ERC677 token on the other side.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     * @param _data additional transfer data passed from the other side.
     */
    function handleBridgedTokensAndCall(
        address _token,
        address _recipient,
        uint256 _value,
        bytes memory _data
    ) external onlyMediator {
        address token = bridgedTokenAddress(_token);

        require(isTokenRegistered(token));

        _handleTokens(token, false, _recipient, _value);

        _receiverCallback(_recipient, token, _value, _data);
    }

    /**
     * @dev Handles the bridged tokens that are native to this chain.
     * Checks that the value is inside the execution limits and invokes the Unlock accordingly.
     * @param _token native ERC20 token.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function handleNativeTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) external onlyMediator {
        _ackBridgedTokenDeploy(_token);

        _handleTokens(_token, true, _recipient, _value);
    }

    /**
     * @dev Handles the bridged tokens that are native to this chain.
     * Checks that the value is inside the execution limits and invokes the Unlock accordingly.
     * Executes a callback on the receiver.
     * @param _token native ERC20 token.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     * @param _data additional transfer data passed from the other side.
     */
    function handleNativeTokensAndCall(
        address _token,
        address _recipient,
        uint256 _value,
        bytes memory _data
    ) external onlyMediator {
        _ackBridgedTokenDeploy(_token);

        _handleTokens(_token, true, _recipient, _value);

        _receiverCallback(_recipient, _token, _value, _data);
    }

    /**
     * @dev Checks if a given token is a bridged token that is native to this side of the bridge.
     * @param _token address of token contract.
     * @return message id of the send message.
     */
    function isRegisteredAsNativeToken(address _token) public view returns (bool) {
        return isTokenRegistered(_token) && nativeTokenAddress(_token) == address(0);
    }

    /**
     * @dev Unlock back the amount of tokens that were bridged to the other network but failed.
     * @param _token address that bridged token contract.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function executeActionOnFixedTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) internal override {
        _releaseTokens(nativeTokenAddress(_token) == address(0), _token, _recipient, _value, _value);
    }

    /**
     * @dev Allows to pre-set the bridged token contract for not-yet bridged token.
     * Only the owner can call this method.
     * @param _nativeToken address of the token contract on the other side that was not yet bridged.
     * @param _bridgedToken address of the bridged token contract.
     */
    function setCustomTokenAddressPair(address _nativeToken, address _bridgedToken) external onlyOwner {
        require(!isTokenRegistered(_bridgedToken));
        require(nativeTokenAddress(_bridgedToken) == address(0));
        require(bridgedTokenAddress(_nativeToken) == address(0));
        // Unfortunately, there is no simple way to verify that the _nativeToken address
        // does not belong to the bridged token on the other side,
        // since information about bridged tokens addresses is not transferred back.
        // Therefore, owner account calling this function SHOULD manually verify on the other side of the bridge that
        // nativeTokenAddress(_nativeToken) == address(0) && isTokenRegistered(_nativeToken) == false.

        IBurnableMintableERC677Token(_bridgedToken).safeMint(address(this), 1);
        IBurnableMintableERC677Token(_bridgedToken).burn(1);

        _setTokenAddressPair(_nativeToken, _bridgedToken);
    }

    /**
     * @dev Allows to send to the other network the amount of locked tokens that can be forced into the contract
     * without the invocation of the required methods. (e. g. regular transfer without a call to onTokenTransfer)
     * @param _token address of the token contract.
     * Before calling this method, it must be carefully investigated how imbalance happened
     * in order to avoid an attempt to steal the funds from a token with double addresses
     * (e.g. TUSD is accessible at both 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E and 0x0000000000085d4780B73119b644AE5ecd22b376)
     * @param _receiver the address that will receive the tokens on the other network.
     */
    function fixMediatorBalance(address _token, address _receiver)
        external
        onlyIfUpgradeabilityOwner
        validAddress(_receiver)
    {
        require(isRegisteredAsNativeToken(_token));

        uint256 diff = _unaccountedBalance(_token);
        require(diff > 0);
        uint256 available = maxAvailablePerTx(_token);
        require(available > 0);
        if (diff > available) {
            diff = available;
        }
        addTotalSpentPerDay(_token, getCurrentDay(), diff);

        bytes memory data = _prepareMessage(address(0), _token, _receiver, diff, new bytes(0));
        bytes32 _messageId = _passMessage(data, true);
        _recordBridgeOperation(_messageId, _token, _receiver, diff);
    }

    /**
     * @dev Claims stuck tokens. Only unsupported tokens can be claimed.
     * When dealing with already supported tokens, fixMediatorBalance can be used instead.
     * @param _token address of claimed token, address(0) for native
     * @param _to address of tokens receiver
     */
    function claimTokens(address _token, address _to) external onlyIfUpgradeabilityOwner {
        // Only unregistered tokens and native coins are allowed to be claimed with the use of this function
        require(_token == address(0) || !isTokenRegistered(_token));
        claimValues(_token, _to);
    }

    /**
     * @dev Withdraws erc20 tokens or native coins from the bridged token contract.
     * Only the proxy owner is allowed to call this method.
     * @param _bridgedToken address of the bridged token contract.
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimTokensFromTokenContract(
        address _bridgedToken,
        address _token,
        address _to
    ) external onlyIfUpgradeabilityOwner {
        IBurnableMintableERC677Token(_bridgedToken).claimTokens(_token, _to);
    }

    /**
     * @dev Internal function for recording bridge operation for further usage.
     * Recorded information is used for fixing failed requests on the other side.
     * @param _messageId id of the sent message.
     * @param _token bridged token address.
     * @param _sender address of the tokens sender.
     * @param _value bridged value.
     */
    function _recordBridgeOperation(
        bytes32 _messageId,
        address _token,
        address _sender,
        uint256 _value
    ) internal {
        setMessageToken(_messageId, _token);
        setMessageRecipient(_messageId, _sender);
        setMessageValue(_messageId, _value);

        emit TokensBridgingInitiated(_token, _sender, _value, _messageId);
    }

    /**
     * @dev Constructs the message to be sent to the other side. Burns/locks bridged amount of tokens.
     * @param _nativeToken address of the native token contract.
     * @param _token bridged token address.
     * @param _receiver address of the tokens receiver on the other side.
     * @param _value bridged value.
     * @param _data additional transfer data passed from the other side.
     */
    function _prepareMessage(
        address _nativeToken,
        address _token,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal returns (bytes memory) {
        bool withData = _data.length > 0 || msg.sig == this.relayTokensAndCall.selector;

        // process token is native with respect to this side of the bridge
        if (_nativeToken == address(0)) {
            _setMediatorBalance(_token, mediatorBalance(_token).add(_value));

            // process token which bridged alternative was already ACKed to be deployed
            if (isBridgedTokenDeployAcknowledged(_token)) {
                return
                    withData
                        ? abi.encodeWithSelector(
                            this.handleBridgedTokensAndCall.selector,
                            _token,
                            _receiver,
                            _value,
                            _data
                        )
                        : abi.encodeWithSelector(this.handleBridgedTokens.selector, _token, _receiver, _value);
            }

            uint8 decimals = TokenReader.readDecimals(_token);
            string memory name = TokenReader.readName(_token);
            string memory symbol = TokenReader.readSymbol(_token);

            require(bytes(name).length > 0 || bytes(symbol).length > 0);

            return
                withData
                    ? abi.encodeWithSelector(
                        this.deployAndHandleBridgedTokensAndCall.selector,
                        _token,
                        name,
                        symbol,
                        decimals,
                        _receiver,
                        _value,
                        _data
                    )
                    : abi.encodeWithSelector(
                        this.deployAndHandleBridgedTokens.selector,
                        _token,
                        name,
                        symbol,
                        decimals,
                        _receiver,
                        _value
                    );
        }

        // process already known token that is bridged from other chain
        IBurnableMintableERC677Token(_token).burn(_value);
        return
            withData
                ? abi.encodeWithSelector(
                    this.handleNativeTokensAndCall.selector,
                    _nativeToken,
                    _receiver,
                    _value,
                    _data
                )
                : abi.encodeWithSelector(this.handleNativeTokens.selector, _nativeToken, _receiver, _value);
    }

    /**
     * @dev Internal function for getting minter proxy address.
     * @param _token address of the token to mint.
     * @return address of the minter contract that should be used for calling mint(address,uint256)
     */
    function _getMinterFor(address _token) internal pure virtual returns (IBurnableMintableERC677Token) {
        return IBurnableMintableERC677Token(_token);
    }

    /**
     * Internal function for unlocking some amount of tokens.
     * @param _isNative true, if token is native w.r.t. to this side of the bridge.
     * @param _token address of the token contract.
     * @param _recipient address of the tokens receiver.
     * @param _value amount of tokens to unlock.
     * @param _balanceChange amount of balance to subtract from the mediator balance.
     */
    function _releaseTokens(
        bool _isNative,
        address _token,
        address _recipient,
        uint256 _value,
        uint256 _balanceChange
    ) internal virtual {
        if (_isNative) {
            IERC677(_token).safeTransfer(_recipient, _value);
            _setMediatorBalance(_token, mediatorBalance(_token).sub(_balanceChange));
        } else {
            _getMinterFor(_token).safeMint(_recipient, _value);
        }
    }

    /**
     * Internal function for getting address of the bridged token. Deploys new token if necessary.
     * @param _token address of the token contract on the other side of the bridge.
     * @param _name name of the native token, name suffix will be appended, if empty, symbol will be used instead.
     * @param _symbol symbol of the bridged token, if empty, name will be used instead.
     * @param _decimals decimals of the bridge foreign token.
     */
    function _getBridgedTokenOrDeploy(
        address _token,
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    ) internal returns (address) {
        address bridgedToken = bridgedTokenAddress(_token);
        if (bridgedToken == address(0)) {
            string memory name = _name;
            string memory symbol = _symbol;
            require(bytes(name).length > 0 || bytes(symbol).length > 0);
            if (bytes(name).length == 0) {
                name = symbol;
            } else if (bytes(symbol).length == 0) {
                symbol = name;
            }
            name = _transformName(name);
            bridgedToken = tokenFactory().deploy(name, symbol, _decimals, bridgeContract().sourceChainId());
            _setTokenAddressPair(_token, bridgedToken);
            _initializeTokenBridgeLimits(bridgedToken, _decimals);
        } else if (!isTokenRegistered(bridgedToken)) {
            require(IERC20Metadata(bridgedToken).decimals() == _decimals);
            _initializeTokenBridgeLimits(bridgedToken, _decimals);
        }
        return bridgedToken;
    }

    /**
     * Notifies receiving contract about the completed bridging operation.
     * @param _recipient address of the tokens receiver.
     * @param _token address of the bridged token.
     * @param _value amount of tokens transferred.
     * @param _data additional data passed to the callback.
     */
    function _receiverCallback(
        address _recipient,
        address _token,
        uint256 _value,
        bytes memory _data
    ) internal {
        if (Address.isContract(_recipient)) {
            _recipient.call(abi.encodeWithSelector(IERC20Receiver.onTokenBridged.selector, _token, _value, _data));
        }
    }

    /**
     * @dev Internal function for transforming the bridged token name. Appends a side-specific suffix.
     * @param _name bridged token from the other side.
     * @return token name for this side of the bridge.
     */
    function _transformName(string memory _name) internal view returns (string memory) {
        string memory result = string(abi.encodePacked(_name, SUFFIX));
        uint256 size = SUFFIX_SIZE;
        assembly {
            mstore(result, add(mload(_name), size))
        }
        return result;
    }

    /**
     * @dev Internal function for counting excess balance which is not tracked within the bridge.
     * Represents the amount of forced tokens on this contract.
     * @param _token address of the token contract.
     * @return amount of excess tokens.
     */
    function _unaccountedBalance(address _token) internal view virtual returns (uint256) {
        return IERC677(_token).balanceOf(address(this)).sub(mediatorBalance(_token));
    }

    function _handleTokens(
        address _token,
        bool _isNative,
        address _recipient,
        uint256 _value
    ) internal virtual;
}

// File: contracts/upgradeable_contracts/components/common/GasLimitManager.sol

pragma solidity 0.7.5;

/**
 * @title GasLimitManager
 * @dev Functionality for determining the request gas limit for AMB execution.
 */
abstract contract GasLimitManager is BasicAMBMediator {
    bytes32 internal constant REQUEST_GAS_LIMIT = 0x2dfd6c9f781bb6bbb5369c114e949b69ebb440ef3d4dd6b2836225eb1dc3a2be; // keccak256(abi.encodePacked("requestGasLimit"))

    /**
     * @dev Sets the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
     * Only the owner can call this method.
     * @param _gasLimit the gas limit for the message execution.
     */
    function setRequestGasLimit(uint256 _gasLimit) external onlyOwner {
        _setRequestGasLimit(_gasLimit);
    }

    /**
     * @dev Tells the default gas limit to be used in the message execution by the AMB bridge on the other network.
     * @return the gas limit for the message execution.
     */
    function requestGasLimit() public view returns (uint256) {
        return uintStorage[REQUEST_GAS_LIMIT];
    }

    /**
     * @dev Stores the gas limit to be used in the message execution by the AMB bridge on the other network.
     * @param _gasLimit the gas limit for the message execution.
     */
    function _setRequestGasLimit(uint256 _gasLimit) internal {
        require(_gasLimit <= maxGasPerTx());
        uintStorage[REQUEST_GAS_LIMIT] = _gasLimit;
    }
}

// File: contracts/interfaces/IInterestReceiver.sol

pragma solidity 0.7.5;

interface IInterestReceiver {
    function onInterestReceived(address _token) external;
}

// File: contracts/interfaces/IInterestImplementation.sol

pragma solidity 0.7.5;

interface IInterestImplementation {
    event InterestEnabled(address indexed token, address xToken);
    event InterestDustUpdated(address indexed token, uint96 dust);
    event InterestReceiverUpdated(address indexed token, address receiver);
    event MinInterestPaidUpdated(address indexed token, uint256 amount);
    event PaidInterest(address indexed token, address to, uint256 value);
    event ForceDisable(address indexed token, uint256 tokensAmount, uint256 xTokensAmount, uint256 investedAmount);

    function isInterestSupported(address _token) external view returns (bool);

    function invest(address _token, uint256 _amount) external;

    function withdraw(address _token, uint256 _amount) external;

    function investedAmount(address _token) external view returns (uint256);
}

// File: contracts/upgradeable_contracts/components/common/InterestConnector.sol

pragma solidity 0.7.5;

/**
 * @title InterestConnector
 * @dev This contract gives an abstract way of receiving interest on locked tokens.
 */
contract InterestConnector is Ownable, MediatorBalanceStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Tells address of the interest earning implementation for the specific token contract.
     * If interest earning is disabled, will return 0x00..00.
     * Can be an address of the deployed CompoundInterestERC20 contract.
     * @param _token address of the locked token contract.
     * @return address of the implementation contract.
     */
    function interestImplementation(address _token) public view returns (IInterestImplementation) {
        return IInterestImplementation(addressStorage[keccak256(abi.encodePacked("interestImpl", _token))]);
    }

    /**
     * @dev Initializes interest receiving functionality for the particular locked token.
     * Only owner can call this method.
     * @param _token address of the token for interest earning.
     * @param _impl address of the interest earning implementation contract.
     * @param _minCashThreshold minimum amount of underlying tokens that are not invested.
     */
    function initializeInterest(
        address _token,
        address _impl,
        uint256 _minCashThreshold
    ) external onlyOwner {
        require(address(interestImplementation(_token)) == address(0));
        _setInterestImplementation(_token, _impl);
        _setMinCashThreshold(_token, _minCashThreshold);
    }

    /**
     * @dev Sets minimum amount of tokens that cannot be invested.
     * Only owner can call this method.
     * @param _token address of the token contract.
     * @param _minCashThreshold minimum amount of underlying tokens that are not invested.
     */
    function setMinCashThreshold(address _token, uint256 _minCashThreshold) external onlyOwner {
        _setMinCashThreshold(_token, _minCashThreshold);
    }

    /**
     * @dev Tells minimum amount of tokens that are not being invested.
     * @param _token address of the invested token contract.
     * @return amount of tokens.
     */
    function minCashThreshold(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("minCashThreshold", _token))];
    }

    /**
     * @dev Disables interest for locked funds.
     * Only owner can call this method.
     * Prior to calling this function, consider to call payInterest and claimCompAndPay.
     * @param _token of token to disable interest for.
     */
    function disableInterest(address _token) external onlyOwner {
        interestImplementation(_token).withdraw(_token, uint256(-1));
        _setInterestImplementation(_token, address(0));
    }

    /**
     * @dev Invests all excess tokens. Leaves only minCashThreshold in underlying tokens.
     * Requires interest for the given token to be enabled first.
     * @param _token address of the token contract considered.
     */
    function invest(address _token) external {
        IInterestImplementation impl = interestImplementation(_token);
        // less than _token.balanceOf(this), since it does not take into account mistakenly locked tokens that should be processed via fixMediatorBalance.
        uint256 balance = mediatorBalance(_token).sub(impl.investedAmount(_token));
        uint256 minCash = minCashThreshold(_token);

        require(balance > minCash);
        uint256 amount = balance - minCash;

        IERC20(_token).safeTransfer(address(impl), amount);
        impl.invest(_token, amount);
    }

    /**
     * @dev Internal function for setting interest earning implementation contract for some token.
     * Also acts as an interest enabled flag.
     * @param _token address of the token contract.
     * @param _impl address of the implementation contract.
     */
    function _setInterestImplementation(address _token, address _impl) internal {
        require(_impl == address(0) || IInterestImplementation(_impl).isInterestSupported(_token));
        addressStorage[keccak256(abi.encodePacked("interestImpl", _token))] = _impl;
    }

    /**
     * @dev Internal function for setting minimum amount of tokens that cannot be invested.
     * @param _token address of the token contract.
     * @param _minCashThreshold minimum amount of underlying tokens that are not invested.
     */
    function _setMinCashThreshold(address _token, uint256 _minCashThreshold) internal {
        uintStorage[keccak256(abi.encodePacked("minCashThreshold", _token))] = _minCashThreshold;
    }
}

// File: contracts/upgradeable_contracts/ForeignOmnibridge.sol

pragma solidity 0.7.5;

/**
 * @title ForeignOmnibridge
 * @dev Foreign side implementation for multi-token mediator intended to work on top of AMB bridge.
 * It is designed to be used as an implementation contract of EternalStorageProxy contract.
 */
contract ForeignOmnibridge is BasicOmnibridge, GasLimitManager, InterestConnector {
    using SafeERC20 for IERC677;
    using SafeMint for IBurnableMintableERC677Token;
    using SafeMath for uint256;

    constructor(string memory _suffix) BasicOmnibridge(_suffix) {}

    /**
     * @dev Stores the initial parameters of the mediator.
     * @param _bridgeContract the address of the AMB bridge contract.
     * @param _mediatorContract the address of the mediator contract on the other network.
     * @param _dailyLimitMaxPerTxMinPerTxArray array with limit values for the assets to be bridged to the other network.
     *   [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
     * @param _executionDailyLimitExecutionMaxPerTxArray array with limit values for the assets bridged from the other network.
     *   [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
     * @param _requestGasLimit the gas limit for the message execution.
     * @param _owner address of the owner of the mediator contract.
     * @param _tokenFactory address of the TokenFactory contract that will be used for the deployment of new tokens.
     */
    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        uint256[3] calldata _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = _dailyLimit, 1 = _maxPerTx, 2 = _minPerTx ]
        uint256[2] calldata _executionDailyLimitExecutionMaxPerTxArray, // [ 0 = _executionDailyLimit, 1 = _executionMaxPerTx ]
        uint256 _requestGasLimit,
        address _owner,
        address _tokenFactory
    ) external onlyRelevantSender returns (bool) {
        require(!isInitialized());

        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        _setLimits(address(0), _dailyLimitMaxPerTxMinPerTxArray);
        _setExecutionLimits(address(0), _executionDailyLimitExecutionMaxPerTxArray);
        _setRequestGasLimit(_requestGasLimit);
        _setOwner(_owner);
        _setTokenFactory(_tokenFactory);

        setInitialize();

        return isInitialized();
    }

    /**
     * One-time function to be used together with upgradeToAndCall method.
     * Sets the token factory contract.
     * @param _tokenFactory address of the deployed TokenFactory contract.
     */
    function upgradeToReverseMode(address _tokenFactory) external {
        require(msg.sender == address(this));

        _setTokenFactory(_tokenFactory);
    }

    /**
     * @dev Handles the bridged tokens.
     * Checks that the value is inside the execution limits and invokes the Mint or Unlock accordingly.
     * @param _token token contract address on this side of the bridge.
     * @param _isNative true, if given token is native to this chain and Unlock should be used.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function _handleTokens(
        address _token,
        bool _isNative,
        address _recipient,
        uint256 _value
    ) internal override {
        // prohibit withdrawal of tokens during other bridge operations (e.g. relayTokens)
        // such reentrant withdrawal can lead to an incorrect balanceDiff calculation
        require(!lock());

        require(withinExecutionLimit(_token, _value));
        addTotalExecutedPerDay(_token, getCurrentDay(), _value);

        _releaseTokens(_isNative, _token, _recipient, _value, _value);

        emit TokensBridged(_token, _recipient, _value, messageId());
    }

    /**
     * @dev Executes action on deposit of bridged tokens
     * @param _token address of the token contract
     * @param _from address of tokens sender
     * @param _receiver address of tokens receiver on the other side
     * @param _value requested amount of bridged tokens
     * @param _data additional transfer data to be used on the other side
     */
    function bridgeSpecificActionsOnTokenTransfer(
        address _token,
        address _from,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal virtual override {
        require(_receiver != address(0) && _receiver != mediatorContractOnOtherSide());

        // native unbridged token
        if (!isTokenRegistered(_token)) {
            uint8 decimals = TokenReader.readDecimals(_token);
            _initializeTokenBridgeLimits(_token, decimals);
        }

        require(withinLimit(_token, _value));
        addTotalSpentPerDay(_token, getCurrentDay(), _value);

        bytes memory data = _prepareMessage(nativeTokenAddress(_token), _token, _receiver, _value, _data);
        bytes32 _messageId = _passMessage(data, true);
        _recordBridgeOperation(_messageId, _token, _from, _value);
    }

    /**
     * Internal function for unlocking some amount of tokens.
     * @param _isNative true, if token is native w.r.t. to this side of the bridge.
     * @param _token address of the token contract.
     * @param _recipient address of the tokens receiver.
     * @param _value amount of tokens to unlock.
     * @param _balanceChange amount of balance to subtract from the mediator balance.
     */
    function _releaseTokens(
        bool _isNative,
        address _token,
        address _recipient,
        uint256 _value,
        uint256 _balanceChange
    ) internal override {
        if (_isNative) {
            // There are two edge cases related to withdrawals on the foreign side of the bridge.
            // 1) Minting of extra STAKE tokens, if supply on the Home side exceeds total bridge amount on the Foreign side.
            // 2) Withdrawal of the invested tokens back from the Compound-like protocol, if currently available funds are insufficient.
            // Most of the time, these cases do not intersect. However, in case STAKE tokens are also invested (e.g. via EasyStaking),
            // the situation can be the following:
            // - 20 STAKE are bridged through the OB. 15 STAKE of which are invested into EasyStaking, and 5 STAKE are locked directly on the bridge.
            // - 5 STAKE are mistakenly locked on the bridge via regular transfer, they are not accounted in mediatorBalance(STAKE)
            // - User requests withdrawal of 30 STAKE from the Home side.
            // Correct sequence of actions should be the following:
            // - Mint new STAKE tokens (value - mediatorBalance(STAKE) = 30 STAKE - 20 STAKE = 10 STAKE)
            // - Set local variable balance to 30 STAKE
            // - Withdraw all invested STAKE tokens (value - (balance - investedAmount(STAKE)) = 30 STAKE - (30 STAKE - 15 STAKE) = 15 STAKE)

            uint256 balance = mediatorBalance(_token);
            if (_token == address(0x0Ae055097C6d159879521C384F1D2123D1f195e6) && balance < _value) {
                IBurnableMintableERC677Token(_token).safeMint(address(this), _value - balance);
                balance = _value;
            }

            IInterestImplementation impl = interestImplementation(_token);
            // can be used instead of Address.isContract(address(impl)),
            // since _setInterestImplementation guarantees that impl is either a contract or zero address
            // and interest implementation does not contain any selfdestruct opcode
            if (address(impl) != address(0)) {
                uint256 availableBalance = balance.sub(impl.investedAmount(_token));
                if (_value > availableBalance) {
                    impl.withdraw(_token, (_value - availableBalance).add(minCashThreshold(_token)));
                }
            }

            _setMediatorBalance(_token, balance.sub(_balanceChange));
            IERC677(_token).safeTransfer(_recipient, _value);
        } else {
            _getMinterFor(_token).safeMint(_recipient, _value);
        }
    }

    /**
     * @dev Internal function for sending an AMB message to the mediator on the other side.
     * @param _data data to be sent to the other side of the bridge.
     * @param _useOracleLane always true, not used on this side of the bridge.
     * @return id of the sent message.
     */
    function _passMessage(bytes memory _data, bool _useOracleLane) internal override returns (bytes32) {
        (_useOracleLane);

        return bridgeContract().requireToPassMessage(mediatorContractOnOtherSide(), _data, requestGasLimit());
    }

    /**
     * @dev Internal function for counting excess balance which is not tracked within the bridge.
     * Represents the amount of forced tokens on this contract.
     * @param _token address of the token contract.
     * @return amount of excess tokens.
     */
    function _unaccountedBalance(address _token) internal view override returns (uint256) {
        IInterestImplementation impl = interestImplementation(_token);
        uint256 invested = Address.isContract(address(impl)) ? impl.investedAmount(_token) : 0;
        return IERC677(_token).balanceOf(address(this)).sub(mediatorBalance(_token).sub(invested));
    }
}