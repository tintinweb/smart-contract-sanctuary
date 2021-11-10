/**
 *Submitted for verification at polygonscan.com on 2021-11-10
*/

// File: OpenZeppelin/Context.sol

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
// File: OpenZeppelin/Ownable.sol

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: OpenZeppelin/Address.sol

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
// File: Interfaces/IPollyToken.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IPollyToken {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    /**
     * @dev Burns amount of tokens (also reduces total Supply)
     */
    function burn(uint256 amount) external;

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
// File: Interfaces/IERC20.sol

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
// File: Interfaces/IWETH.sol

pragma solidity 0.8.1;


interface IWETH is IERC20 {
    function withdraw(uint wad) external;
}
// File: OpenZeppelin/SafeERC20.sol

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
// File: Interfaces/IBentoBoxV1.sol

pragma solidity ^0.8.1;


interface IBentoBoxV1 {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogFlashLoan(address indexed borrower, address indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);
    event LogRegisterProtocol(address indexed protocol);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogStrategyDivest(address indexed token, uint256 amount);
    event LogStrategyInvest(address indexed token, uint256 amount);
    event LogStrategyLoss(address indexed token, uint256 amount);
    event LogStrategyProfit(address indexed token, uint256 amount);
    event LogStrategyQueued(address indexed token, address indexed strategy);
    event LogStrategySet(address indexed token, address indexed strategy);
    event LogStrategyTargetPercentage(address indexed token, uint256 targetPercentage);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint256 share);
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    struct AccrueInfo {
        uint64 interestPerSecond;
        uint64 lastAccrued;
        uint128 feesEarnedFraction;
    }
    
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);

    function claimOwnership() external;
    
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable;

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function balanceOf(address amount1, address amount2) external view returns (uint256 amountOut);

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;


    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}
// File: Interfaces/IERC20Metadata.sol

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
// File: Interfaces/IPie.sol

pragma solidity 0.8.1;


interface IPie is IERC20 {
    function joinPool(uint256 _amount) external;
    function exitPool(uint256 _amount) external;
    function calcTokensForAmount(uint256 _amount) external view  returns(address[] memory tokens, uint256[] memory amounts);
}
// File: Interfaces/IPieRegistry.sol

pragma solidity 0.8.1;
interface IPieRegistry {
    function inRegistry(address _pool) external view returns(bool);
    function entries(uint256 _index) external view returns(address);
    function addSmartPool(address _smartPool) external;
    function removeSmartPool(uint256 _index) external;
}
// File: Interfaces/ILendingLogic.sol

pragma solidity ^0.8.1;

interface ILendingLogic {
    /**
        @notice Get the APR based on underlying token.
        @param _token Address of the underlying token
        @return Interest with 18 decimals
    */
    function getAPRFromUnderlying(address _token) external view returns(uint256);

    /**
        @notice Get the APR based on wrapped token.
        @param _token Address of the wrapped token
        @return Interest with 18 decimals
    */
    function getAPRFromWrapped(address _token) external view returns(uint256);

    /**
        @notice Get the calls needed to lend.
        @param _underlying Address of the underlying token
        @param _amount Amount of the underlying token
        @return targets Addresses of the contracts to call
        @return data Calldata of the calls
    */
    function lend(address _underlying, uint256 _amount, address _tokenHolder) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the calls needed to unlend
        @param _wrapped Address of the wrapped token
        @param _amount Amount of the underlying tokens
        @return targets Addresses of the contracts to call
        @return data Calldata of the calls
    */
    function unlend(address _wrapped, uint256 _amount, address _tokenHolder) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the underlying wrapped exchange rate
        @param _wrapped Address of the wrapped token
        @return The exchange rate
    */
    function exchangeRate(address _wrapped) external returns(uint256);

    /**
        @notice Get the underlying wrapped exchange rate in a view (non state changing) way
        @param _wrapped Address of the wrapped token
        @return The exchange rate
    */
    function exchangeRateView(address _wrapped) external view returns(uint256);
}
// File: Interfaces/ILendingRegistry.sol

pragma solidity 0.8.1;

interface ILendingRegistry {
    // Maps wrapped token to protocol
    function wrappedToProtocol(address _wrapped) external view returns(bytes32);
    // Maps wrapped token to underlying
    function wrappedToUnderlying(address _wrapped) external view returns(address);
    function underlyingToProtocolWrapped(address _underlying, bytes32 protocol) external view returns (address);
    function protocolToLogic(bytes32 _protocol) external view returns (address);

    /**
        @notice Set which protocl a wrapped token belongs to
        @param _wrapped Address of the wrapped token
        @param _protocol Bytes32 key of the protocol
    */
    function setWrappedToProtocol(address _wrapped, bytes32 _protocol) external;

    /**
        @notice Set what is the underlying for a wrapped token
        @param _wrapped Address of the wrapped token
        @param _underlying Address of the underlying token
    */
    function setWrappedToUnderlying(address _wrapped, address _underlying) external;

    /**
        @notice Set the logic contract for the protocol
        @param _protocol Bytes32 key of the procol
        @param _logic Address of the lending logic contract for that protocol
    */
    function setProtocolToLogic(bytes32 _protocol, address _logic) external;
    /**
        @notice Set the wrapped token for the underlying deposited in this protocol
        @param _underlying Address of the unerlying token
        @param _protocol Bytes32 key of the protocol
        @param _wrapped Address of the wrapped token
    */
    function setUnderlyingToProtocolWrapped(address _underlying, bytes32 _protocol, address _wrapped) external;

    /**
        @notice Get tx data to lend the underlying amount in a specific protocol
        @param _underlying Address of the underlying token
        @param _amount Amount to lend
        @param _protocol Bytes32 key of the protocol
        @return targets Addresses of the contracts to call
        @return data Calldata for the calls
    */
    function getLendTXData(address _underlying, uint256 _amount, bytes32 _protocol) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the tx data to unlend the wrapped amount
        @param _wrapped Address of the wrapped token
        @param _amount Amount of wrapped token to unlend
        @return targets Addresses of the contracts to call
        @return data Calldata for the calls
    */
    function getUnlendTXData(address _wrapped, uint256 _amount) external view returns(address[] memory targets, bytes[] memory data);
}
// File: Interfaces/IUniRouter.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: Interfaces/IRecipe.sol

pragma solidity 0.8.1;

interface IRecipe {
    function bake(
        address _inputToken,
        address _outputToken,
        uint256 _maxInput,
        bytes memory _data
    ) external returns (uint256 inputAmountUsed, uint256 outputAmount);
}
// File: UniPieRecipeV2.sol

pragma solidity 0.8.1;












//import "hardhat/console.sol";

contract UniPieRecipeV2 is IRecipe, Ownable {
    using SafeERC20 for IERC20;

    IERC20 immutable WETH;
    IUniRouter immutable sushiRouter;
    ILendingRegistry immutable lendingRegistry;
    IPieRegistry immutable pieRegistry;
    
    uint256 public baoFee = 0;
    address public baoAddress = 0xc81278a52AD0e1485B7C3cDF79079220Ddd68b7D;
    address public feeRecipient = 0x000000000000000000000000000000000000dEaD;
    

    event HopUpdated(address indexed _token, address indexed _hop);

    // Adds a custom hop before reaching the destination token
    mapping(address => CustomHop) public customHops;

    struct CustomHop {
        address hop;
        // DexChoice dex;
    }

    enum DexChoice {Uni, Sushi}

    constructor(
        address _weth,
        address _sushiRouter,
        address _lendingRegistry,
        address _pieRegistry,
        address _bentoBox,
        address _masterKontract
    ) { 
        require(_weth != address(0), "WETH_ZERO");
        require(_sushiRouter != address(0), "SUSHI_ROUTER_ZERO");
        require(_lendingRegistry != address(0), "LENDING_MANAGER_ZERO");
        require(_pieRegistry != address(0), "PIE_REGISTRY_ZERO");

        WETH = IERC20(_weth);
        sushiRouter = IUniRouter(_sushiRouter);
        lendingRegistry = ILendingRegistry(_lendingRegistry);
        pieRegistry = IPieRegistry(_pieRegistry);
        
        _bentoBox.call{ value: 0 }(abi.encodeWithSelector(IBentoBoxV1.setMasterContractApproval.selector,address(this),_masterKontract,true,0,0x0000000000000000000000000000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000000000000000000000000000));
    }

    function bake(
        address _inputToken,
        address _outputToken,
        uint256 _maxInput,
        bytes memory _data
    ) external override returns(uint256 inputAmountUsed, uint256 outputAmount) {
        IERC20 inputToken = IERC20(_inputToken);
        IERC20 outputToken = IERC20(_outputToken);

        inputToken.safeTransferFrom(_msgSender(), address(this), _maxInput);

        (uint256 mintAmount) = abi.decode(_data, (uint256));

        outputAmount = _bake(_inputToken, _outputToken, _maxInput, mintAmount);

        uint256 remainingInputBalance = inputToken.balanceOf(address(this));
        
        uint256 feeAmount = ((_maxInput - remainingInputBalance) * baoFee) / (1e18 + 1);
        
        if(remainingInputBalance > 0 && feeAmount != 0) {
            IPollyToken baoToken = IPollyToken(baoAddress);
            WETH.approve(address(sushiRouter), 0);
            WETH.approve(address(sushiRouter), type(uint256).max);
            address[] memory route = getRoute(address(WETH), baoAddress, address(0));
            uint256 estimatedAmount = sushiRouter.getAmountsOut(feeAmount, route)[1];
            sushiRouter.swapExactTokensForTokens(feeAmount, estimatedAmount, route, address(this), block.timestamp + 1);
            baoToken.burn(baoToken.balanceOf(address(this)));
        }
        
        if(remainingInputBalance > 0) {
            inputToken.transfer(_msgSender(), inputToken.balanceOf(address(this)));
        }

        outputToken.safeTransfer(_msgSender(), outputAmount);  

        return(inputAmountUsed, outputAmount);
    }

    function _bake(address _inputToken, address _outputToken, uint256 _maxInput, uint256 _mintAmount) internal returns(uint256 outputAmount) {
        swap(_inputToken, _outputToken, _mintAmount);

        outputAmount = IERC20(_outputToken).balanceOf(address(this));

        return(outputAmount);
    }

    function swap(address _inputToken, address _outputToken, uint256 _outputAmount) internal {
        //console.log("Buying", _outputToken, "with", _inputToken);

        if(_inputToken == _outputToken) {
            return;
        }

        // if input is not WETH buy WETH
        if(_inputToken != address(WETH)) {
            uint256 wethAmount = getPrice(address(WETH), _outputToken, _outputAmount);
            swapUniOrSushi(_inputToken, address(WETH), wethAmount);
            swap(address(WETH), _outputToken, _outputAmount);
            return;
        }

        if(pieRegistry.inRegistry(_outputToken)) {
            // console.log("Swapping to PIE", _outputToken);
            swapPie(_outputToken, _outputAmount);
            return;
        }
        
        address underlying = lendingRegistry.wrappedToUnderlying(_outputToken);
        if(underlying != address(0)) {
            // calc amount according to exchange rate
            ILendingLogic lendingLogic = getLendingLogicFromWrapped(_outputToken);
            uint256 exchangeRate = lendingLogic.exchangeRate(_outputToken); // wrapped to underlying
            uint256 underlyingAmount = _outputAmount * exchangeRate / (1e18) + 1;

            swap(_inputToken, underlying, underlyingAmount);
            (address[] memory targets, bytes[] memory data) = lendingLogic.lend(underlying, underlyingAmount, address(this));

            //execute lending transactions
            for(uint256 i = 0; i < targets.length; i ++) {
                (bool success, ) = targets[i].call{ value: 0 }(data[i]);
                require(success, "CALL_FAILED");
            }

            return;
        }

        // else normal swap
        swapUniOrSushi(_inputToken, _outputToken, _outputAmount);
    }

    function swapPie(address _pie, uint256 _outputAmount) internal {
        IPie pie = IPie(_pie);
        (address[] memory tokens, uint256[] memory amounts) = pie.calcTokensForAmount(_outputAmount);

        for(uint256 i = 0; i < tokens.length; i ++) {
            swap(address(WETH), tokens[i], amounts[i]+1);
            IERC20 token = IERC20(tokens[i]);
            token.approve(_pie, 0);
            token.approve(_pie, amounts[i]+1);
            //console.log("BentoBalance: ",IBentoBoxV1(0x0319000133d3AdA02600f0875d2cf03D442C3367).balanceOf(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,address(this)));
            //console.log("TokenBalance: ",token.balanceOf(address(this)));
            //console.log("Token Amount: ",amounts[i]);
            require(amounts[i] <= token.balanceOf(address(this)), "We are trying to deposit more then we have");
        }
        pie.joinPool(_outputAmount);
    }

    function swapUniOrSushi(address _inputToken, address _outputToken, uint256 _outputAmount) internal {

        IERC20 inputToken = IERC20(_inputToken);

        CustomHop memory customHop = customHops[_outputToken];

        if(address(_inputToken) == _outputToken) {
            return;
        }

        if(customHop.hop != address(0)) {
            hopSwapSushi(_inputToken, customHop.hop, _outputToken, _outputAmount);
            return;
        }
        
        address[] memory route = getRoute(_inputToken, _outputToken, address(0));

        inputToken.approve(address(sushiRouter), 0);
        inputToken.approve(address(sushiRouter), type(uint256).max);
        sushiRouter.swapTokensForExactTokens(_outputAmount, type(uint256).max, route, address(this), block.timestamp + 1);

    }
    
    function hopSwapSushi(address _inputToken,address _hopToken, address _outputToken, uint256 _outputAmount) internal {
        IERC20 inputToken = IERC20(_inputToken);
        
        address[] memory route = getRoute(_inputToken, _outputToken, _hopToken);
        
        inputToken.approve(address(sushiRouter), 0);
        inputToken.approve(address(sushiRouter), type(uint256).max);
        sushiRouter.swapTokensForExactTokens(_outputAmount, type(uint256).max, route, address(this), block.timestamp + 1);
    }

    function setCustomHop(address _token, address _hop) external onlyOwner {
        customHops[_token] = CustomHop({
            hop: _hop
            // dex: _dex
        });
    }

    function saveToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }
  
    function saveEth(address payable _to, uint256 _amount) external onlyOwner {
        _to.call{value: _amount}("");
    }
    
    function setBaoFee(uint256 _newFee) external onlyOwner{
        require(_newFee <= 10**18);
        baoFee = _newFee;
    }
    
    function setFeeToken(address _newFeeToken) external onlyOwner {
        baoAddress = _newFeeToken;
    }
    
    function setFeeRecipient(address _newFeeRecipient) external onlyOwner {
        feeRecipient = _newFeeRecipient;
    }

    function getPrice(address _inputToken, address _outputToken, uint256 _outputAmount) public returns(uint256)  {
        if(_inputToken == _outputToken) {
            return _outputAmount;
        }

        // CustomHop memory customHop = customHops[_outputToken];
        // if(customHop.hop != address(0)) {
        //     //get price for hop
        //     uint256 hopAmount = getPrice(customHop.hop, _outputToken, _outputAmount);
        //     return getPrice(_inputToken, _outputToken, hopAmount);
        // }

        address underlying = lendingRegistry.wrappedToUnderlying(_outputToken);
        if(underlying != address(0)) {
            // calc amount according to exchange rate
            ILendingLogic lendingLogic = getLendingLogicFromWrapped(_outputToken);
            uint256 exchangeRate = lendingLogic.exchangeRate(_outputToken); // wrapped to underlying
            uint256 underlyingAmount = _outputAmount * exchangeRate / (10**18) + 1;

            return getPrice(_inputToken, underlying, underlyingAmount);
        }

        // check if token is pie
        if(pieRegistry.inRegistry(_outputToken)) {
            uint256 ethAmount =  getPricePie(_outputToken, _outputAmount);

            // if input was not WETH
            if(_inputToken != address(WETH)) {
                return getPrice(_inputToken, address(WETH), ethAmount);
            }

            return ethAmount;
        }

        // if input and output are not WETH (2 hop swap)
        if(_inputToken != address(WETH) && _outputToken != address(WETH)) {
            (uint256 middleInputAmount,) = getBestPriceSushiUni(address(WETH), _outputToken, _outputAmount);
            (uint256 inputAmount,) = getBestPriceSushiUni(_inputToken, address(WETH), middleInputAmount);

            return inputAmount;
        }

        // else single hop swap
        (uint256 inputAmount,) = getBestPriceSushiUni(_inputToken, _outputToken, _outputAmount);

        return inputAmount;
    }

    function getBestPriceSushiUni(address _inputToken, address _outputToken, uint256 _outputAmount) internal returns(uint256, DexChoice) {
        uint256 sushiAmount = getPriceUniLike(_inputToken, _outputToken, _outputAmount, sushiRouter);

        return (sushiAmount, DexChoice.Sushi);
    }

    function getRoute(address _inputToken, address _outputToken, address _hop) internal returns(address[] memory route) {
        // if both input and output are not WETH
        if(_inputToken != address(WETH) && _outputToken != address(WETH)) {
            route = new address[](3);
            route[0] = _inputToken;
            route[1] = address(WETH);
            route[2] = _outputToken;
            return route;
        }
        
        if(_hop != address(0)){
            route = new address[](3);
            route[0] = _inputToken;
            route[1] = _hop;
            route[2] = _outputToken;
            return route;
        }

        route = new address[](2);
        route[0] = _inputToken;
        route[1] = _outputToken;

        return route;
    }

    function getPriceUniLike(address _inputToken, address _outputToken, uint256 _outputAmount, IUniRouter _router) internal returns(uint256) {
        if(_inputToken == _outputToken) {
            return(_outputAmount);
        }
        
        try _router.getAmountsIn(_outputAmount, getRoute(_inputToken, _outputToken, address(0))) returns(uint256[] memory amounts) {
            return amounts[0];
        } catch {
            return type(uint256).max;
        }
    }

    // NOTE input token must be WETH
    function getPricePie(address _pie, uint256 _pieAmount) internal returns(uint256) {
        IPie pie = IPie(_pie);
        (address[] memory tokens, uint256[] memory amounts) = pie.calcTokensForAmount(_pieAmount);

        uint256 inputAmount = 0;

        for(uint256 i = 0; i < tokens.length; i ++) {
            inputAmount += getPrice(address(WETH), tokens[i], amounts[i]);
        }

        return inputAmount;
    }

    function getLendingLogicFromWrapped(address _wrapped) internal view returns(ILendingLogic) {
        return ILendingLogic(
                lendingRegistry.protocolToLogic(
                    lendingRegistry.wrappedToProtocol(
                        _wrapped
                    )
                )
        );
    }

    function encodeData(uint256 _outputAmount) external pure returns(bytes memory){
        return abi.encode((_outputAmount));
    }
}
// File: V1CompatibleRecipe.sol.sol

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;



contract V1CompatibleRecipe is UniPieRecipeV2 {
    using SafeERC20 for IERC20;

    constructor(
        address _weth,
        address _sushiRouter,
        address _lendingRegistry,
        address _pieRegistry,
        address _bentoBox,
        address _masterKontract) UniPieRecipeV2(_weth, _sushiRouter, _lendingRegistry, _pieRegistry, _bentoBox, _masterKontract) {
            //nothing here
    }

    function toPie(address _pie, uint256 _outputAmount) external payable {
        uint256 calculatedSpend = getPrice(address(WETH), _pie, _outputAmount);
        // console.log("calculated spend", calculatedSpend);

        // convert to WETH
        address(WETH).call{value: msg.value}("");
        
        // bake pie
        uint256 outputAmount = _bake(address(WETH), _pie, msg.value, _outputAmount);

        // transfer output
        IERC20(_pie).safeTransfer(_msgSender(), outputAmount);

        // if any WETH left convert it into ETH and send it back
        uint256 wethBalance = WETH.balanceOf(address(this));
        if(wethBalance != 0) {
            // console.log("returning WETH");
            // console.log(wethBalance);
            IWETH(address(WETH)).withdraw(wethBalance);
            payable(msg.sender).transfer(wethBalance);
        }
    }

    function calcToPie(address _pie, uint256 _poolAmount) external returns(uint256) {
        return getPrice(address(WETH), _pie, _poolAmount);
    }

    fallback () external payable {}
}