/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File: contracts/TaskBlacklist.sol


pragma solidity ^0.8.0;


contract TaskBlacklist is Ownable {
    /// @notice The blacklist of the tasks.
    mapping(bytes32 => bool) private _blacklistedTasks;

    event TaskBlacklistAdded(bytes32 taskId);
    event TaskBlacklistRemoved(bytes32 taskId);

    modifier onlyValidTask(bytes32 _taskId) {
        require(isValidTask(_taskId), "Invalid task");
        _;
    }

    /// @notice Ban the task from being able to be executed.
    /// @param _taskId The task to be banned.
    function banTask(bytes32 _taskId) external onlyOwner {
        _blacklistedTasks[_taskId] = true;

        emit TaskBlacklistAdded(_taskId);
    }

    /// @notice Unban the task.
    /// @param _taskId The task to be unbanned.
    function unbanTask(bytes32 _taskId) external onlyOwner {
        require(!isValidTask(_taskId), "Not banned");
        _blacklistedTasks[_taskId] = false;

        emit TaskBlacklistRemoved(_taskId);
    }

    /// @notice Return if the task is valid.
    /// @param _taskId The task to be queried.
    function isValidTask(bytes32 _taskId) public view returns (bool) {
        return (!_blacklistedTasks[_taskId]);
    }
}

// File: contracts/ResolverWhitelist.sol


pragma solidity ^0.8.0;


contract ResolverWhitelist is Ownable {
    /// @notice The whitelist of valid resolvers.
    mapping(address => bool) private _whitelistedResolvers;

    event ResolverWhitelistAdded(address resolverAddress);
    event ResolverWhitelistRemoved(address resolverAddress);

    modifier onlyValidResolver(address _resolverAddress) {
        require(isValidResolver(_resolverAddress), "Invalid resolver");
        _;
    }

    /// @notice Register the resolver to the whitelist. Can only be called
    /// by owner.
    /// @param _resolverAddress The resolver to be registered.
    function registerResolver(address _resolverAddress) external onlyOwner {
        _whitelistedResolvers[_resolverAddress] = true;

        emit ResolverWhitelistAdded(_resolverAddress);
    }

    /// @notice Unregister the resolver from the whitelist. Can only be called
    /// by owner.
    /// @param _resolverAddress The resolver to be unregistered.
    function unregisterResolver(address _resolverAddress)
        external
        onlyOwner
        onlyValidResolver(_resolverAddress)
    {
        _whitelistedResolvers[_resolverAddress] = false;

        emit ResolverWhitelistRemoved(_resolverAddress);
    }

    /// @notice Return if the resolver is valid.
    /// @param _resolverAddress The address to be queried.
    function isValidResolver(address _resolverAddress)
        public
        view
        returns (bool)
    {
        return _whitelistedResolvers[_resolverAddress];
    }
}

// File: contracts/Resolver.sol


pragma solidity ^0.8.0;

abstract contract Resolver {
    address public immutable action;
    address public immutable furuGelato;

    modifier onlyFuruGelato() {
        require(msg.sender == furuGelato, "not FuruGelato");
        _;
    }

    constructor(address _action, address _furuGelato) {
        action = _action;
        furuGelato = _furuGelato;
    }

    function checker(address taskCreator, bytes calldata resolverData)
        external
        view
        virtual
        returns (bool canExec, bytes memory executionData);

    function onCreateTask(address taskCreator, bytes calldata executionData)
        external
        virtual
        onlyFuruGelato
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }

    function onCancelTask(address taskCreator, bytes calldata executionData)
        external
        virtual
        onlyFuruGelato
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }

    function onExec(address taskCreator, bytes calldata executionData)
        external
        virtual
        onlyFuruGelato
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }
}

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol



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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/Gelatofied.sol


pragma solidity ^0.8.0;

abstract contract Gelatofied {
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address payable public immutable gelato;

    constructor(address payable _gelato) {
        gelato = _gelato;
    }

    modifier gelatofy(uint256 _amount, address _paymentToken) {
        require(msg.sender == gelato, "Gelatofied: Only gelato");
        _;
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "Gelatofied: Gelato fee failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
    }
}

// File: contracts/DSProxyTask.sol


pragma solidity ^0.8.0;

contract DSProxyTask {
    /// @notice Return the id of the task.
    /// @param _dsProxy The creator of the task.
    /// @param _resolverAddress The resolver of the task.
    /// @param _executionData The execution data of the task.
    /// @return The task id.
    function getTaskId(
        address _dsProxy,
        address _resolverAddress,
        bytes memory _executionData
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(_dsProxy, _resolverAddress, _executionData));
    }
}

// File: contracts/DSProxyBlacklist.sol


pragma solidity ^0.8.0;


contract DSProxyBlacklist is Ownable {
    /// @notice The blacklist of the dsProxys.
    mapping(address => bool) private _blacklistedDSProxies;

    event DSProxyBlacklistAdded(address dsProxy);
    event DSProxyBlacklistRemoved(address dsProxy);

    modifier onlyValidDSProxy(address _dsProxy) {
        require(isValidDSProxy(_dsProxy), "Invalid dsProxy");
        _;
    }

    /// @notice Ban the dsProxy from being able to be executed.
    /// @param _dsProxy The dsProxy to be banned.
    function banDSProxy(address _dsProxy) external onlyOwner {
        _blacklistedDSProxies[_dsProxy] = true;

        emit DSProxyBlacklistAdded(_dsProxy);
    }

    /// @notice Unban the dsProxy.
    /// @param _dsProxy The dsProxy to be unbanned.
    function unbanDSProxy(address _dsProxy) external onlyOwner {
        require(!isValidDSProxy(_dsProxy), "Not banned");
        _blacklistedDSProxies[_dsProxy] = false;

        emit DSProxyBlacklistRemoved(_dsProxy);
    }

    /// @notice Return if the dsProxy is valid.
    /// @param _dsProxy The dsProxy to be queried.
    function isValidDSProxy(address _dsProxy) public view returns (bool) {
        return (!_blacklistedDSProxies[_dsProxy]);
    }
}

// File: contracts/interfaces/IFuruGelato.sol


pragma solidity ^0.8.0;

interface IFuruGelato {
    event TaskCreated(
        address indexed taskCreator,
        bytes32 taskId,
        address indexed resolverAddress,
        bytes executionData
    );
    event TaskCancelled(
        address indexed taskCreator,
        bytes32 taskId,
        address indexed resolverAddress,
        bytes executionData
    );
    event ExecSuccess(
        uint256 indexed txFee,
        address indexed feeToken,
        address indexed taskExecutor,
        bytes32 taskId
    );

    event LogFundsDeposited(address indexed sender, uint256 amount);
    event LogFundsWithdrawn(
        address indexed sender,
        uint256 amount,
        address receiver
    );

    function createTask(address _resolverAddress, bytes calldata _resolverData)
        external;

    function cancelTask(address _resolverAddress, bytes calldata _resolverData)
        external;

    function exec(
        uint256 _fee,
        address _proxy,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external;

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory);

    function withdrawFunds(uint256 _amount, address payable _receiver) external;
}

interface IDSProxyBlacklist {
    function banDSProxy(address _dsProxy) external;

    function unbanDSProxy(address _dsProxy) external;

    function isValidDSProxy(address _dsProxy) external view returns (bool);
}

interface IResolverWhitelist {
    function registerResolver(address _resolverAddress) external;

    function unregisterResolver(address _resolverAddress) external;

    function isValidResolver(address _resolverAddress)
        external
        view
        returns (bool);
}

interface ITaskBlacklist {
    function banTask(bytes32 _taskId) external;

    function unbanTask(bytes32 _taskId) external;

    function isValidTask(bytes32 _taskId) external view returns (bool);
}

// File: contracts/interfaces/IDSProxy.sol


pragma solidity ^0.8.0;

interface IDSProxy {
    function owner() external view returns (address);

    function execute(address _target, bytes memory _data)
        external
        payable
        returns (bytes memory response);

    function setAuthority(address _authority) external;

    event LogSetAuthority(address indexed authority);
}

interface IProxyRegistry {
    function build() external returns (address proxy);

    function proxies(address _userAddress)
        external
        view
        returns (address proxy);
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol



pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts/FuruGelato.sol


pragma solidity 0.8.6;







/// @title The task manager
contract FuruGelato is
    IFuruGelato,
    Ownable,
    Gelatofied,
    DSProxyTask,
    ResolverWhitelist,
    DSProxyBlacklist,
    TaskBlacklist
{
    using EnumerableSet for EnumerableSet.Bytes32Set;

    string public constant VERSION = "0.0.1";
    /// @notice The creator of the task
    mapping(bytes32 => address) public taskCreator;
    /// @notice The total task list created by user
    mapping(address => EnumerableSet.Bytes32Set) internal _createdTasks;

    constructor(address payable _gelato) Gelatofied(_gelato) {}

    receive() external payable {
        emit LogFundsDeposited(msg.sender, msg.value);
    }

    // Task related
    /// @notice Create the task through the given resolver. The resolver should
    /// be validated through a whitelist.
    /// @param _resolverAddress The resolver to generate the task execution
    /// data.
    /// @param _resolverData The data to be provided to the resolver for data
    /// generation.
    function createTask(address _resolverAddress, bytes calldata _resolverData)
        external
        override
        onlyValidResolver(_resolverAddress)
        onlyValidDSProxy(msg.sender)
    {
        // The _resolverData is passed to the resolver to generate the
        // execution data for the task.
        (, bytes memory executionData) =
            Resolver(_resolverAddress).checker(msg.sender, _resolverData);
        bytes32 taskId = getTaskId(msg.sender, _resolverAddress, executionData);
        require(
            taskCreator[taskId] == address(0),
            "FuruGelato: createTask: Sender already started task"
        );
        _createdTasks[msg.sender].add(taskId);
        taskCreator[taskId] = msg.sender;

        // Call resolver's `onCreateTask()`
        require(
            Resolver(_resolverAddress).onCreateTask(msg.sender, executionData),
            "FuruGelato: createTask: onCreateTask() failed"
        );

        emit TaskCreated(msg.sender, taskId, _resolverAddress, executionData);
    }

    /// @notice Cancel the task that was created through the given resolver.
    /// @param _resolverAddress The resolver that created the task.
    /// @param _executionData The task data to be canceled.
    function cancelTask(address _resolverAddress, bytes calldata _executionData)
        external
        override
    {
        bytes32 taskId =
            getTaskId(msg.sender, _resolverAddress, _executionData);

        require(
            taskCreator[taskId] == msg.sender,
            "FuruGelato: cancelTask: Sender did not start task yet"
        );

        _createdTasks[msg.sender].remove(taskId);
        delete taskCreator[taskId];

        require(
            Resolver(_resolverAddress).onCancelTask(msg.sender, _executionData),
            "FuruGelato: cancelTask: onCancelTask() failed"
        );

        emit TaskCancelled(
            msg.sender,
            taskId,
            _resolverAddress,
            _executionData
        );
    }

    /// @notice Execute the task created by `_proxy`through the given resolver.
    /// The resolver should be validated through a whitelist.
    /// @param _fee The fee to be paid to `gelato`
    /// @param _resolverAddress The resolver that created the task.
    /// @param _executionData The execution payload.
    function exec(
        uint256 _fee,
        address _proxy,
        address _resolverAddress,
        bytes calldata _executionData
    )
        external
        override
        gelatofy(_fee, ETH)
        onlyValidResolver(_resolverAddress)
        onlyValidDSProxy(_proxy)
    {
        bytes32 taskId = getTaskId(_proxy, _resolverAddress, _executionData);
        require(isValidTask(taskId), "FuruGelato: exec: invalid task");
        // Fetch the action to be used in dsproxy's `execute()`.
        address action = Resolver(_resolverAddress).action();

        require(
            _proxy == taskCreator[taskId],
            "FuruGelato: exec: No task found"
        );

        try IDSProxy(_proxy).execute(action, _executionData) {} catch {
            revert("FuruGelato: exec: execute failed");
        }

        require(
            Resolver(_resolverAddress).onExec(_proxy, _executionData),
            "FuruGelato: exec: onExec() failed"
        );

        emit ExecSuccess(_fee, ETH, _proxy, taskId);
    }

    /// @notice Return the tasks created by the user.
    /// @param _taskCreator The user to be queried.
    /// @return The task list.
    function getTaskIdsByUser(address _taskCreator)
        external
        view
        override
        returns (bytes32[] memory)
    {
        uint256 length = _createdTasks[_taskCreator].length();
        bytes32[] memory taskIds = new bytes32[](length);

        for (uint256 i; i < length; i++) {
            taskIds[i] = _createdTasks[_taskCreator].at(i);
        }

        return taskIds;
    }

    // Funds related
    /// @notice Withdraw the deposited funds that is used for paying fee.
    /// @param _amount The amount to be withdrawn.
    /// @param _receiver The address to be withdrawn to.
    function withdrawFunds(uint256 _amount, address payable _receiver)
        external
        override
        onlyOwner
    {
        (bool success, ) = _receiver.call{value: _amount}("");
        require(success, "FuruGelato: withdrawFunds: Withdraw funds failed");

        emit LogFundsWithdrawn(msg.sender, _amount, _receiver);
    }
}