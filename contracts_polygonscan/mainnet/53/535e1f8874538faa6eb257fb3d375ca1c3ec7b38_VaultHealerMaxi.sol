/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol



pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// File: @openzeppelin/contracts/utils/math/Math.sol



pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: vaults-v1/contracts/libs/IVaultHealer.sol



pragma solidity >=0.6.12;

interface IVaultHealer {

    function poolInfo(uint _pid) external view returns (address want, address strat);
    
    function maximizerDeposit(uint _amount) external;
    
    function strategyMaxiCore() external view returns (address);
    function strategyMasterHealer() external view returns (address);
    function strategyMaxiMasterHealer() external view returns (address);
    
}
// File: @openzeppelin/contracts/proxy/Proxy.sol



pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
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
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// File: vaults-v1/contracts/VaultProxy.sol



pragma solidity ^0.8.4;




contract VaultProxy is Proxy {

    IVaultHealer internal __vaultHealer;
    StratType internal __stratType;
    
    constructor(StratType _stratType) {
        require(_stratType != StratType.BASIC, "YA BASIC");
        __stratType = _stratType;
        __vaultHealer = IVaultHealer(msg.sender);
    }
    
    function _implementation() internal view override returns (address) {
        if (__stratType == StratType.MASTER_HEALER) return __vaultHealer.strategyMasterHealer();
        if (__stratType == StratType.MAXIMIZER_CORE) return __vaultHealer.strategyMaxiCore();
        if (__stratType == StratType.MAXIMIZER) return __vaultHealer.strategyMaxiMasterHealer();
        revert("No implementation");
    }
}
// File: vaults-v1/contracts/libs/IStrategy.sol





pragma solidity >=0.6.12;



enum StratType { BASIC, MASTER_HEALER, MAXIMIZER_CORE, MAXIMIZER }



// For interacting with our own strategy

interface IStrategy {

    // Want address

    function wantAddress() external view returns (address);

    

    // Total want tokens managed by strategy

    function wantLockedTotal() external view returns (uint256);



    // Sum of all shares of users to wantLockedTotal

    function sharesTotal() external view returns (uint256);



    // Main want token compounding function

    function earn() external;



    // Transfer want tokens autoFarm -> strategy

    function deposit(address _userAddress, uint256 _wantAmt) external returns (uint256);



    // Transfer want tokens strategy -> vaultChef

    function withdraw(address _userAddress, uint256 _wantAmt) external returns (uint256);

    

    //Maximizer want token (eg crystl)

    function maxiAddress() external returns (address);

    

    function stratType() external returns (StratType);

    

    function initialize(uint _pid, uint _tolerance, address _govAddress, address _masterChef, address _uniRouter, address _wantAddress, address _earnedAddress, address _earnedToWmaticStep) external;



    function initialize(uint _pid, uint _tolerance, address _govAddress, address _masterChef, address _uniRouter, address _wantAddress, address _earnedToWmaticStep) external;

}
// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
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

// File: vaults-v1/contracts/Operators.sol





pragma solidity ^0.8.4;




contract Operators is Ownable {

    mapping(address => bool) public operators;



    event OperatorUpdated(address indexed operator, bool indexed status);



    modifier onlyOperator() {

        require(operators[msg.sender], "Operator: caller is not the operator");

        _;

    }



    // Update the status of the operator

    function updateOperator(address _operator, bool _status) external onlyOwner {

        operators[_operator] = _status;

        emit OperatorUpdated(_operator, _status);

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

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

    constructor() {
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

// File: vaults-v1/contracts/VaultHealer.sol





pragma solidity ^0.8.4;







contract VaultHealer is ReentrancyGuard, Operators {

    using SafeERC20 for IERC20;



    struct PoolInfo {

        IERC20 want;

        IStrategy strat;

        StratType stratType;

    }



    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => uint256)) private userShares;

    mapping(address => bool) public strats;



    // Compounding Variables

    // 0: compound by anyone; 1: EOA only; 2: restricted to operators

    uint public compoundMode = 1;

    bool public autocompoundOn = true;



    event AddPool(address indexed strat);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event SetCompoundMode(uint locked, bool automatic);

    event CompoundError(uint pid, bytes reason);



    function poolLength() external view returns (uint256) {

        return poolInfo.length;

    }



    /**

     * @dev Add a new want to the pool. Can only be called by the owner.

     */

    function addPool(address _strat) public onlyOwner nonReentrant {

        require(!strats[_strat], "Existing strategy");

        poolInfo.push(

            PoolInfo({

                want: IERC20(IStrategy(_strat).wantAddress()),

                strat: IStrategy(_strat),

                stratType: IStrategy(_strat).stratType()

            })

        );

        strats[_strat] = true;

        resetSingleAllowance(poolInfo.length - 1);

        emit AddPool(_strat);

    }



    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256) {

        PoolInfo storage pool = poolInfo[_pid];



        uint256 sharesTotal = pool.strat.sharesTotal();

        uint256 wantLockedTotal = poolInfo[_pid].strat.wantLockedTotal();

        if (sharesTotal == 0) {

            return 0;

        }

        return getUserShares(_pid, _user) * wantLockedTotal / sharesTotal;

    }



    function deposit(uint256 _pid, uint256 _wantAmt) external nonReentrant autoCompound {

        _deposit(_pid, _wantAmt, msg.sender);

    }



    // For unique contract calls

    function deposit(uint256 _pid, uint256 _wantAmt, address _to) external nonReentrant onlyOperator {

        _deposit(_pid, _wantAmt, _to);

    }

    

    //getter and setter are overriden to enable maximizers    

    function userInfo(uint256 _pid, address _user) external view returns (uint) {

        return getUserShares(_pid, _user);

    }

    function getUserShares(uint256 _pid, address _user) internal view virtual returns (uint shares) {

        return userShares[_pid][_user];

    }

    function addUserShares(uint256 _pid, address _user, uint sharesAdded) internal virtual returns (uint shares) {

        userShares[_pid][_user] += sharesAdded;

        return userShares[_pid][_user];

    }

    function removeUserShares(uint256 _pid, address _user, uint sharesRemoved) internal virtual returns (uint shares) {

        userShares[_pid][_user] -= sharesRemoved;

        return userShares[_pid][_user];

    }

    

    function _deposit(uint256 _pid, uint256 _wantAmt, address _to) internal virtual returns (uint sharesAdded) {

        PoolInfo storage pool = poolInfo[_pid];



        if (_wantAmt > 0) {

            pool.want.safeTransferFrom(msg.sender, address(this), _wantAmt);



            sharesAdded = poolInfo[_pid].strat.deposit(_to, _wantAmt);

            addUserShares(_pid, _to, sharesAdded);

        }

        emit Deposit(_to, _pid, _wantAmt);

    }



    function withdraw(uint256 _pid, uint256 _wantAmt) external nonReentrant autoCompound {

        _withdraw(_pid, _wantAmt, msg.sender);

    }



    // For unique contract calls

    function withdraw(uint256 _pid, uint256 _wantAmt, address _to) external nonReentrant onlyOperator {

        _withdraw(_pid, _wantAmt, _to);

    }

    

    function _withdraw(uint256 _pid, uint256 _wantAmt, address _to) internal virtual returns (uint sharesTotal, uint sharesRemoved) {

        PoolInfo storage pool = poolInfo[_pid];

        uint _userShares = getUserShares(_pid, msg.sender);



        uint256 wantLockedTotal = poolInfo[_pid].strat.wantLockedTotal();

        sharesTotal = poolInfo[_pid].strat.sharesTotal();



        require(_userShares > 0, "userShares is 0");

        require(sharesTotal > 0, "sharesTotal is 0");



        uint256 amount = _userShares * wantLockedTotal / sharesTotal;

        if (_wantAmt > amount) {

            _wantAmt = amount;

        }

        if (_wantAmt > 0) {

            sharesRemoved = poolInfo[_pid].strat.withdraw(msg.sender, _wantAmt);



            if (sharesRemoved > _userShares) {

                removeUserShares(_pid, msg.sender, _userShares);

            } else {

                removeUserShares(_pid, msg.sender, sharesRemoved);

            }



            uint256 wantBal = pool.want.balanceOf(address(this));

            if (wantBal < _wantAmt) {

                _wantAmt = wantBal;

            }

            pool.want.safeTransfer(_to, _wantAmt);

        }

        emit Withdraw(msg.sender, _pid, _wantAmt);

    }



    function withdrawAll(uint256 _pid) external autoCompound {

        _withdraw(_pid, type(uint256).max, msg.sender);

    }



    function resetAllowances() external onlyOwner {

        for (uint256 i=0; i<poolInfo.length; i++) {

            PoolInfo storage pool = poolInfo[i];

            pool.want.safeApprove(address(pool.strat), uint256(0));

            pool.want.safeIncreaseAllowance(address(pool.strat), type(uint256).max);

        }

    }



    function resetSingleAllowance(uint256 _pid) public onlyOwner {

        PoolInfo storage pool = poolInfo[_pid];

        pool.want.safeApprove(address(pool.strat), uint256(0));

        pool.want.safeIncreaseAllowance(address(pool.strat), type(uint256).max);

    }

    

    // Compounding Functionality

    function setCompoundMode(uint mode, bool autoC) external onlyOwner {

        compoundMode = mode;

        autocompoundOn = autoC;

        emit SetCompoundMode(mode, autoC);

    }



    modifier autoCompound {

        if (autocompoundOn && (compoundMode == 0 || operators[msg.sender] || (compoundMode == 1 && msg.sender == tx.origin))) {

            _compoundAll();

        }

        _;

    }



    function compoundAll() external {

        require(compoundMode == 0 || operators[msg.sender] || (compoundMode == 1 && msg.sender == tx.origin), "Compounding is restricted");

        _compoundAll();

    }

    

    function _compoundAll() internal {

        uint numPools = poolInfo.length;

        for (uint i; i < numPools; i++) {

            try poolInfo[i].strat.earn() {}

            catch (bytes memory reason) {

                emit CompoundError(i, reason);

            }

        }

    }

}
// File: vaults-v1/contracts/VaultHealerMaxi.sol



pragma solidity ^0.8.4;





contract VaultHealerMaxi is VaultHealer, Initializable {
    using Math for uint256;
    
    address public strategyMaxiCore;
    address public strategyMasterHealer;
    address public strategyMaxiMasterHealer;
    
    mapping(address => uint) public maxiDebt; //negative maximizer tokens to offset adding to pools
    
    function initialize(
        uint256 _pid,
        uint256 _tolerance,
        address _masterChef,
        address _uniRouter,
        address _wantAddress, //want == earned for maximizer core
        address _earnedToWmaticStep //address(0) if swapping earned->wmatic directly, or the address of an intermediate trade token such as weth
    ) external initializer onlyOwner {
        strategyMaxiCore = 0x85Ca967EbCf5572Aaf3953BCc51635B6A02D122A;
        strategyMasterHealer = 0x4b19F4755a162b0CC6990E181B474Db36AF9613a;
        strategyMaxiMasterHealer = 0x5aC89891AEbED834CD387B9Af727aD5A6A3a7fBD;
        IStrategy core = IStrategy(address(new VaultProxy(StratType.MAXIMIZER_CORE)));
        core.initialize(_pid, _tolerance, owner(), _masterChef, _uniRouter, _wantAddress, _earnedToWmaticStep);
        addPool(address(core));
    }
    
    function addMHStandardStrategy(
        uint256 _pid,
        uint256 _tolerance,
        address _masterChef,
        address _uniRouter,
        address _wantAddress,
        address _earnedAddress,
        address _earnedToWmaticStep
    ) external onlyOwner {
        IStrategy _strat = IStrategy(address(new VaultProxy(StratType.MASTER_HEALER)));
        _strat.initialize(_pid, _tolerance, owner(), _masterChef, _uniRouter, _wantAddress, _earnedAddress, _earnedToWmaticStep);
        addPool(address(_strat));
    }
    
    function addMHMaximizerStrategy(
        uint256 _pid,
        uint256 _tolerance,
        address _masterChef,
        address _uniRouter,
        address _wantAddress, 
        address _earnedAddress,
        address _earnedToWmaticStep //address(0) if swapping earned->wmatic directly, or the address of an intermediate trade token such as weth
    ) external onlyOwner {
        IStrategy _strat = IStrategy(address(new VaultProxy(StratType.MAXIMIZER)));
        _strat.initialize(_pid, _tolerance, owner(), _masterChef, _uniRouter, _wantAddress, _earnedAddress, _earnedToWmaticStep);
        addPool(address(_strat));
        require(_strat.maxiAddress() == address(poolInfo[0].want), "maximizer maximizes the wrong token!");
    }
    
    //for a particular account, shares contributed by one of the maximizers
    function coreSharesFromMaximizer(uint _pid, address _user) internal view returns (uint shares) {

        require(_pid > 0 && _pid < poolInfo.length, "VaultHealerMaxi: coreSharesFromMaximizer bad pid");
        if (poolInfo[_pid].stratType != StratType.MAXIMIZER) return 0;
        
        uint userStratShares = getUserShares(_pid, _user); //user's share of the maximizer
        
        IStrategy strategy = poolInfo[_pid].strat; //maximizer strategy
        uint stratSharesTotal = strategy.sharesTotal(); //total shares of the maximizer vault
        if (stratSharesTotal == 0) return 0;
        uint stratCoreShares = getUserShares(_pid, address(strategy));
        
        return userStratShares * stratCoreShares / stratSharesTotal;
    }
    function getUserShares(uint256 _pid, address _user) internal view override returns (uint shares) {
        
        shares = super.getUserShares(0, _user);
        
        if (_pid == 0 && !strats[_user]) {
            //Add the user's share of each maximizer's share of the core vault
            for (uint i = 1; i < poolInfo.length; i++) {
                shares += coreSharesFromMaximizer(i, _user);
            }
            shares -= maxiDebt[_user];
        }
    }
    function removeUserShares(uint256 _pid, address _user, uint sharesRemoved) internal override returns (uint shares) {
        if (_pid == 0 && !strats[_user] && sharesRemoved > super.getUserShares(0, _user)) {
            maxiDebt[_user] += sharesRemoved;
            return getUserShares(_pid, _user);
        } else {
            return super.removeUserShares(_pid, _user, sharesRemoved);
        }
    }
    
    //for maximizer functions to deposit the maximized token in the core vault
    function maximizerDeposit(uint256 _wantAmt) external {
        require(strats[msg.sender], "only callable by strategies");
        super._deposit(0, _wantAmt, msg.sender);
    }

    function _deposit(uint256 _pid, uint256 _wantAmt, address _to) internal override returns (uint sharesAdded) {
        IStrategy strat = poolInfo[_pid].strat;
        uint256 sharesTotal = strat.sharesTotal(); // must be total before shares are added
        sharesAdded = super._deposit(_pid, _wantAmt, _to);
        if (_pid > 0 && sharesTotal > 0 && poolInfo[_pid].stratType == StratType.MAXIMIZER) {
            //rebalance shares so core shares are the same as before for the individual user and for the rest of the pool
            uint maxiCoreShares = getUserShares(0, address(strat)); // core shares held by the maximizer
            
            //old/new == old/new; vault gets +shares, depositor gets -shares but it all evens out
            uint coreShareOffset = (maxiCoreShares * (sharesTotal + sharesAdded)).ceilDiv(sharesTotal) - maxiCoreShares; //ceilDiv benefits pool over user preventing abuse
            addUserShares(0, address(strat), coreShareOffset); 
            removeUserShares(0, _to, coreShareOffset);
        }
    }
    
    function _withdraw(uint256 _pid, uint256 _wantAmt, address _to) internal override returns (uint sharesTotal, uint sharesRemoved) {
        (sharesTotal, sharesRemoved) = super._withdraw(_pid, _wantAmt, _to);
        if (_pid > 0 && sharesTotal > 0 && poolInfo[_pid].stratType == StratType.MAXIMIZER) {
            //rebalance shares so core shares are the same as before for the individual user and for the rest of the pool
            address strat = address(poolInfo[_pid].strat);
            uint maxiCoreShares = getUserShares(0, strat); // core shares held by the maximizer
            
            uint coreShareOffset = maxiCoreShares - ((sharesTotal - sharesRemoved) * maxiCoreShares).ceilDiv(sharesTotal); //ceilDiv benefits pool over user preventing abuse
            removeUserShares(0, strat, coreShareOffset); 
            addUserShares(0, _to, coreShareOffset);
        }
    }
}