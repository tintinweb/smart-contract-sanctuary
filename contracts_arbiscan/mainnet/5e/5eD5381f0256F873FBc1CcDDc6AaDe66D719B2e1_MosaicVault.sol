/**
 *Submitted for verification at arbiscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

//
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
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//
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

//
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

//
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

    uint256[49] private __gap;
}

//
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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

//
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

//
interface IInvestmentStrategy {
    struct Investment {
        address token;
        uint256 amount;
    }

    function makeInvestment(Investment[] calldata _investments, bytes calldata _data)
        external
        returns (uint256);

    function withdrawInvestment(Investment[] calldata _investments, bytes calldata _data) external;

    function claimTokens(bytes calldata _data) external returns (address);

    function investmentAmount(address _token) external view returns (uint256);
}

//
interface IMosaicHolding {
    event FoundsInvested(address indexed strategy, address indexed admin, uint256 cTokensReceived);

    event InvestmentWithdrawn(address indexed strategy, address indexed admin);

    event RebalancingThresholdChanged(
        address indexed admin,
        address indexed token,
        uint256 oldAmount,
        uint256 newAmount
    );

    event RebalancingInitiated(
        address indexed by,
        address indexed token,
        address indexed receiver,
        uint256 amount
    );

    event TokenClaimed(address indexed strategy, address indexed rewardTokenAddress);

    event SaveFundsStarted(address owner, address token, address receiver);

    event LiquidityMoved(address indexed to, address indexed tokenAddress, uint256 amount);

    event SaveFundsLockUpTimerStarted(address owner, uint256 time, uint256 durationToChangeTime);

    event SaveFundsLockUpTimeSet(address owner, uint256 time, uint256 durationToChangeTime);

    event ETHTransfered(address receiver, uint256 amount);

    function getTokenLiquidity(address _token, address[] calldata _investmentStrategies)
        external
        view
        returns (uint256);

    function saveFundsLockupTime() external view returns (uint256);

    function newSaveFundsLockUpTime() external view returns (uint256);

    function durationToChangeTimer() external view returns (uint256);

    function transfer(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;

    function transferETH(address _receiver, uint256 _amount) external;

    function setUniqRole(bytes32 _role, address _address) external;

    function approve(
        address _spender,
        address _token,
        uint256 _amount
    ) external;

    /**
     * @dev starts save funds transfer.
     * @param _token Token's balance the owner wants to withdraw
     * @param _to Receiver address
     */
    function startSaveFunds(address _token, address _to) external;

    /**
     * @dev manually moves funds back to L1.
     */
    function executeSaveFunds() external;

    /**
     * @dev starts save funds lockup timer change.
     * @param _time lock up time duration
     */
    function startSaveFundsLockUpTimerChange(uint256 _time) external;

    /**
     * @dev set save funds lock up time.
     */
    function setSaveFundsLockUpTime() external;

    function invest(
        IInvestmentStrategy.Investment[] calldata _investments,
        address _investmentStrategy,
        bytes calldata _data
    ) external;

    function withdrawInvestment(
        IInvestmentStrategy.Investment[] calldata _investments,
        address _investmentStrategy,
        bytes calldata _data
    ) external;

    function coverWithdrawRequest(
        address[] calldata investmentStrategies,
        address _token,
        uint256 _amount
    ) external;

    function claim(address _investmentStrategy, bytes calldata _data) external;
}

//
interface IMosaicExchange {
    function swap(
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOut,
        bytes calldata _data
    ) external returns (uint256);

    function getAmountsOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes calldata _data
    ) external returns (uint256);
}

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

//
interface IReceiptBase is IERC20 {
    function burn(address _from, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;

    function underlyingToken() external returns (address);
}

//
interface ITokenFactory {
    function createIOU(
        address _underlyingAddress,
        string calldata _tokenName,
        address _owner
    ) external returns (address);

    function createReceipt(
        address _underlyingAddress,
        string calldata _tokenName,
        address _owner
    ) external returns (address);
}

//
interface IVaultConfigBase {
    event TokenCreated(address _underlyingToken);

    function getMosaicHolding() external view returns (address);

    function setTokenFactoryAddress(address _tokenFactoryAddress) external;

    function setVault(address _vault) external;
}

//
interface IMosaicVaultConfig is IVaultConfigBase {
    event MinFeeChanged(uint256 newMinFee);
    event MaxFeeChanged(uint256 newMaxFee);
    event MinLiquidityBlockChanged(uint256 newMinLimitLiquidityBlocks);
    event MaxLiquidityBlockChanged(uint256 newMaxLimitLiquidityBlocks);
    event LockupTimeChanged(address indexed owner, uint256 oldVal, uint256 newVal, string valType);
    event TokenWhitelisted(
        address indexed erc20,
        address indexed newIou,
        address indexed newReceipt
    );
    event TokenWhitelistRemoved(address indexed erc20);
    event RemoteTokenAdded(
        address indexed erc20,
        address indexed remoteErc20,
        uint256 indexed remoteNetworkID,
        uint256 remoteTokenRatio
    );
    event RemoteTokenRemoved(address indexed erc20, uint256 indexed remoteNetworkID);

    event PauseNetwork(address admin, uint256 networkID);

    event UnpauseNetwork(address admin, uint256 networkID);

    struct WhitelistedToken {
        uint256 minTransferAllowed;
        uint256 maxTransferAllowed;
        address underlyingIOUAddress;
        address underlyingReceiptAddress;
    }

    function passiveLiquidityLocktime() external view returns (uint256);

    function minFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function maxLimitLiquidityBlocks() external view returns (uint256);

    function minLimitLiquidityBlocks() external view returns (uint256);

    function wethAddress() external view returns (address);

    function remoteTokenAddress(uint256 _id, address _token) external view returns (address);

    function remoteTokenRatio(uint256 _id, address _token) external view returns (uint256);

    function supportedAMMs(uint256 _ammID) external view returns (address);

    function pausedNetwork(uint256) external view returns (bool);

    function ableToPerformSmallBalanceSwap() external view returns (bool);

    function supportedMosaicNativeSwappers(uint256 _mosaicNativeSwapperID)
        external
        view
        returns (address);

    /**
     * @dev used to set the passive liquidity lock time
     * @param _locktime  Lock time in seconds until the passive liquidity withdrawal is unavailable
     */
    function setPassiveLiquidityLocktime(uint256 _locktime) external;

    /**
     * @dev used to set WETH address
     * @param _weth  Address of WETH token
     * @param _minTransferAmount Minimum transfer allowed amount
     * @param _maxTransferAmount Maximum transfer allowed amount
     */
    function setWethAddress(
        address _weth,
        uint256 _minTransferAmount,
        uint256 _maxTransferAmount
    ) external;

    function getUnderlyingIOUAddress(address _token) external view returns (address);

    function getUnderlyingReceiptAddress(address _token) external view returns (address);

    /**
     * @dev used to add address of the AMM used to swap tokens.
     * @param _ammID the integer constant for the AMM
     * @param _ammAddress Address of the AMM
     */
    function addSupportedAMM(uint256 _ammID, address _ammAddress) external;

    /**
     * @dev used to remove address of the AMM.
     * @param _ammID the integer constant for the AMM
     */
    function removeSupportedAMM(uint256 _ammID) external;

    function changeRemoteTokenRatio(
        address _tokenAddress,
        uint256 _remoteNetworkID,
        uint256 _remoteTokenRatio
    ) external;

    /**
     * @dev used to adds a whitelisted token to the contract.
     * @param _tokenAddress  SC address of the ERC20 token to add to supported tokens
     * @param _minTransferAmount Minimum amount of token can be transferred
     * @param _maxTransferAmount  Maximum amount of token can be transferred
     */
    function addWhitelistedToken(
        address _tokenAddress,
        uint256 _minTransferAmount,
        uint256 _maxTransferAmount
    ) external;

    /**
     * @dev used to removes whitelisted token from the contract.
     * @param _token  SC address of the ERC20 token to remove from supported tokens
     */
    function removeWhitelistedToken(address _token) external;

    function addTokenInNetwork(
        address _tokenAddress,
        address _tokenAddressRemote,
        uint256 _remoteNetworkID,
        uint256 _remoteTokenRatio
    ) external;

    function removeTokenInNetwork(address _tokenAddress, uint256 _remoteNetworkID) external;

    /**
     * @dev updates the minimum fee.
     * @param _newMinFee  value to be set as new minimum fee
     */
    function setMinFee(uint256 _newMinFee) external;

    /**
     * @dev updates the maximum fee.
     * @param _newMaxFee  value to be set as new minimum fee
     */
    function setMaxFee(uint256 _newMaxFee) external;

    /**
     * @dev updates the minimum limit liquidity block.
     * @param _newMinLimitLiquidityBlocks value to be set as new minimum limit liquidity block
     */
    function setMinLimitLiquidityBlocks(uint256 _newMinLimitLiquidityBlocks) external;

    /**
     * @dev updates the maximum limit liquidity block.
     * @param _newMaxLimitLiquidityBlocks value to be set as new maximum limit liquidity block
     */
    function setMaxLimitLiquidityBlocks(uint256 _newMaxLimitLiquidityBlocks) external;

    function generateId() external returns (bytes32);

    function inTokenTransferLimits(address, uint256) external returns (bool);

    /**
     * @dev used to pause a network.
     * @param _networkID  network ID of remote token
     */
    function pauseNetwork(uint256 _networkID) external;

    /**
     * @dev used to unpause a network.
     * @param _networkID  network ID of remote token
     */
    function unpauseNetwork(uint256 _networkID) external;

    function setAbleToPerformSmallBalanceSwap(bool _flag) external;

    function addSupportedMosaicNativeSwapper(
        uint256 _mosaicNativeSwapperID,
        address _mosaicNativeSwapperAddress
    ) external;

    function removeSupportedMosaicNativeSwapper(uint256 _mosaicNativeSwapperID) external;
}

//
interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 _wad) external;

    function balanceOf(address _account) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

//
/**
 * @dev Interface of L1Vault.
 */
interface IMosaicVault {
    event TransferInitiated(
        address indexed owner,
        address indexed erc20,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        address remoteDestinationAddress,
        bytes32 uniqueId,
        uint256 maxTransferDelay,
        address tokenOut,
        uint256 ammID,
        uint256 amountOutMin,
        bool _swapToNative
    );

    event WithdrawalCompleted(
        address indexed accountTo,
        uint256 amount,
        uint256 netAmount,
        address indexed tokenAddress,
        bytes32 indexed uniqueId,
        bool swapToNative
    );

    event TransferFundsRefunded(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        uint256 fullAmount,
        bytes32 uniqueId
    );
    event FundsDigested(address indexed tokenAddress, uint256 amount);

    event FeeTaken(
        address indexed owner,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 fee,
        uint256 baseFee,
        uint256 totalFee,
        bytes32 uniqueId
    );

    event DepositActiveLiquidity(
        address indexed tokenAddress,
        address indexed provider,
        uint256 amount,
        uint256 blocks
    );

    event DepositPassiveLiquidity(
        address indexed tokenAddress,
        address indexed provider,
        uint256 amount
    );

    event LiquidityWithdrawn(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 baseFee,
        uint256 mosaicFee,
        bool swapToNative
    );

    event LiquidityRefunded(
        address indexed tokenAddress,
        address indexed receiptAddress,
        address indexed user,
        uint256 amount,
        bytes32 uniqueId
    );

    event WithdrawRequest(
        address indexed user,
        address receiptToken,
        address indexed tokenIn,
        uint256 amountIn,
        address indexed tokenOut,
        address remoteTokenInAddress,
        address destinationAddress,
        uint256 ammId,
        uint256 destinationNetworkID,
        bytes data,
        bytes32 uniqueId,
        WithdrawRequestData _withdrawData
    );

    enum TransferState {
        UNKNOWN, // Default state
        SUCCESS,
        REFUNDED
    }

    struct WithdrawRequestData {
        uint256 amountOutMin;
        uint256 maxDelay;
        bool _swapToNative;
    }

    struct WithdrawData {
        uint256 feePercentage;
        uint256 baseFee;
        address[] investmentStrategies;
        uint256 ammId;
        bytes32 id;
        uint256 amountToSwapToNative;
        uint256 nativeSwapperId;
    }

    function setRelayer(address _relayer) external;

    function setVaultConfig(address _vaultConfig) external;

    /**
     * @dev used to provide active liquidity.
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _blocksForActiveLiquidity users choice of active liquidity
     */
    function provideActiveLiquidity(
        uint256 _amount,
        address _tokenAddress,
        uint256 _blocksForActiveLiquidity
    ) external payable;

    /**
     * @dev used to provide passive liquidity.
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     */
    function providePassiveLiquidity(uint256 _amount, address _tokenAddress) external payable;

    /// @notice External function called to add withdraw liquidity request
    /// @param _receiptToken Address of the iou token provider have
    /// @param _amountIn Amount of tokens provider want to withdraw
    /// @param _tokenOut Address of the token which LP wants to receive
    /// @param _ammID the amm to use for swapping
    /// @param _data extra call data
    /// @param _destinationNetworkId networkId of the _receiptToken's underlying token
    /// @param _withdrawRequestData set of data for withdraw
    function withdrawLiquidityRequest(
        address _receiptToken,
        uint256 _amountIn,
        address _tokenOut,
        address _destinationAddress,
        uint256 _ammID,
        bytes calldata _data,
        uint256 _destinationNetworkId,
        WithdrawRequestData calldata _withdrawRequestData
    ) external returns (bytes32 transferId);

    /**
     *  @notice Called by relayer to withdraw liquidity from the vault
     *  @param _accountTo eth address to send the withdrawal tokens
     *  @param _amount amount of token in
     *  @param _tokenIn address of the token in
     *  @param _tokenOut address of the token out
     *  @param _amountOutMin minimum amount out user wants
     *  @param _withdrawData set of data for withdraw
     *  @param _data additional _data required for each AMM implementation
     */
    function withdrawLiquidity(
        address _accountTo,
        uint256 _amount,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin,
        WithdrawData calldata _withdrawData,
        bytes calldata _data
    ) external;

    /**
     * @dev used to release funds
     * @param _accountTo eth address to send the withdrawal tokens
     * @param _amount amount of token in
     * @param _tokenIn address of the token in
     * @param _tokenOut address of the token out
     * @param _amountOutMin minimum amount out user want
     * @param _data additional data required for each AMM implementation
     * @param _withdrawData set of data for withdraw
     */
    function withdrawTo(
        address _accountTo,
        uint256 _amount,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin,
        WithdrawData calldata _withdrawData,
        bytes calldata _data
    ) external;

    /**
     * @dev used by the relayer or by the owner to refund a failed withdrawal request
     * @param _user user's address
     * @param _amount amount to be refunded out of which the transaction cost was substracted
     * @param _receiptToken receipt's address
     * @param _id withdrawal id generated by the relayer.
     */
    function revertLiquidityWithdrawalRequest(
        address _user,
        uint256 _amount,
        address _receiptToken,
        bytes32 _id
    ) external;

    /**
     * @dev transfer ERC20 token to another Mosaic vault.
     * @param _amount amount of tokens to deposit
     * @param _tokenAddress  SC address of the ERC20 token to deposit
     * @param _remoteDestinationAddress SC address of the ERC20 supported tokens in a diff network
     * @param _remoteNetworkID  network ID of remote token
     * @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
     * @param _swapToNative true if a part will be swapped to native token in destination
     * @return transferId - transfer unique identifier
     */
    function transferERC20ToLayer(
        uint256 _amount,
        address _tokenAddress,
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId,
        uint256 _amountOutMin,
        bool _swapToNative
    ) external returns (bytes32 transferId);

    /**
     * @dev transfer ETH to another Mosaic vault
     * @param _remoteDestinationAddress SC address of the ERC20 supported tokens in a diff network
     * @param _remoteNetworkID  network ID of remote token
     * @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
     * @param _swapToNative true if a part will be swapped to native token in destination
     * @return transferId - transfer unique identifier
     */
    function transferETHToLayer(
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId,
        uint256 _amountOutMin,
        bool _swapToNative
    ) external payable returns (bytes32 transferId);

    /*
     * @dev returns transfer state
     * @param _transferId id of the transfer
     */
    function getTransferState(bytes32 _transferId) external view returns (TransferState);

    /**
     * @dev called by the relayer or by the owner to refund a failed transfer transaction
     * @param _token address of token user want to withdraw.
     * @param _user user's address.
     * @param _amount amount of tokens to be refunded.
     * @param _originalAmount amount of tokens user initiated a transfer for.
     * @param _id id generated by the relayer.
     */
    function refundTransferFunds(
        address _token,
        address _user,
        uint256 _amount,
        uint256 _originalAmount,
        bytes32 _id,
        address[] calldata _investmentStrategies
    ) external;

    /**
     * @dev used to send random tokens to the holding.
     * @param _token Address of the ERC20 token
     */
    function digestFunds(address _token) external;

    /**
     * @dev used to pause the contract.
     */

    function pause() external;

    /**
     * @dev used to unpause the contract.
     */

    function unpause() external;
}

//
interface IMosaicNativeSwapper {
    event SwappedToNative(address _tokenIn, uint256 amountIn, uint256 amountOut, address addressTo);

    function swapToNative(
        address _tokenIn,
        uint256 _amount,
        address _to,
        bytes calldata _data
    ) external returns (uint256);
}

//
library FeeOperations {
    uint256 internal constant FEE_FACTOR = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return (amount * fee) / FEE_FACTOR;
    }
}

//
//@title: Composable Finance Mosaic ERC20 Vault
contract MosaicVault is
    IMosaicVault,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct DepositInfo {
        address token;
        uint256 amount;
    }

    struct TemporaryWithdrawData {
        address tokenIn;
        address remoteTokenIn;
        bytes32 id;
    }

    /// @notice Public mapping to keep track of all the withdrawn funds
    mapping(bytes32 => bool) public hasBeenWithdrawn;

    /// @notice Public mapping to keep track of all the refunded funds
    mapping(bytes32 => bool) public hasBeenRefunded;

    /// @dev mapping userAddress => tokenAddress => activeLiquidityAvailableAfterBlock (block number)
    mapping(address => mapping(address => uint256)) private activeLiquidityAvailableAfterBlock;

    /// @dev mapping userAddress => tokenAddress => passiveLiquidityAvailableAfterTimestamp (block timestamp)
    mapping(address => mapping(address => uint256)) public passiveLiquidityAvailableAfterTimestamp;

    /// @notice Public mapping to track the user deposits
    /// @dev bytes32 => DepositInfo struct (token address, amount)
    mapping(bytes32 => DepositInfo) public deposits;

    /// @notice Store the last withdrawn ID
    bytes32 public lastWithdrawID;

    /// @notice Store the last refunded ID
    bytes32 public lastRefundedID;

    /// @notice Relayer address
    address public relayer;

    IMosaicVaultConfig public vaultConfig;

    /// @notice Initialize function to set up the contract
    /// @dev it should be called immediately after deploy
    /// @param _mosaicVaultConfig Address of the MosaicVaultConfig
    function initialize(address _mosaicVaultConfig) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        vaultConfig = IMosaicVaultConfig(_mosaicVaultConfig);
    }

    /// @notice External callable function to set the relayer address
    function setRelayer(address _relayer) external override onlyOwner {
        relayer = _relayer;
    }

    /// @notice External callable function to set the vault config address
    function setVaultConfig(address _vaultConfig) external override onlyOwner {
        vaultConfig = IMosaicVaultConfig(_vaultConfig);
    }

    /// @notice External function used by the user to provide active liquidity to the vault
    ///         User will receive equal amount of IOU tokens
    /// @param _amount Amount of tokens he want to deposit; 0 for ETH
    /// @param _tokenAddress Address of the token he want to deposit; 0x0 for ETH
    /// @param _blocksForActiveLiquidity For how many blocks the liquidity is locked
    function provideActiveLiquidity(
        uint256 _amount,
        address _tokenAddress,
        uint256 _blocksForActiveLiquidity
    )
        public
        payable
        override
        nonReentrant
        whenNotPaused
        inBlockApproveRange(_blocksForActiveLiquidity)
    {
        require(_amount > 0 || msg.value > 0, "ERR: AMOUNT");
        if (msg.value > 0) {
            require(
                vaultConfig.getUnderlyingIOUAddress(vaultConfig.wethAddress()) != address(0),
                "ERR: WETH NOT WHITELISTED"
            );
            _provideLiquidity(msg.value, vaultConfig.wethAddress(), _blocksForActiveLiquidity);
        } else {
            require(_tokenAddress != address(0), "ERR: INVALID TOKEN");
            require(
                vaultConfig.getUnderlyingIOUAddress(_tokenAddress) != address(0),
                "ERR: TOKEN NOT WHITELISTED"
            );
            _provideLiquidity(_amount, _tokenAddress, _blocksForActiveLiquidity);
        }
    }

    /// @notice External function used by the user to provide passive liquidity to the vault
    ///         User will receive equal amount of Receipt tokens
    /// @param _amount Deposited token's amount; 0 for ETH
    /// @param _tokenAddress Deposited token's address; 0x0 for ETH
    function providePassiveLiquidity(uint256 _amount, address _tokenAddress)
        external
        payable
        override
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0 || msg.value > 0, "ERR: AMOUNT");
        if (msg.value > 0) {
            require(
                vaultConfig.getUnderlyingIOUAddress(vaultConfig.wethAddress()) != address(0),
                "ERR: WETH NOT WHITELISTED"
            );
            _provideLiquidity(msg.value, vaultConfig.wethAddress(), 0);
        } else {
            require(_tokenAddress != address(0), "ERR: INVALID TOKEN");
            require(
                vaultConfig.getUnderlyingIOUAddress(_tokenAddress) != address(0),
                "ERR: TOKEN NOT WHITELISTED"
            );
            _provideLiquidity(_amount, _tokenAddress, 0);
        }
    }

    /// @dev Internal function called to deposit liquidity, both passive and active liquidity
    /// @param _amount Deposited token's amount; 0 for ETH
    /// @param _tokenAddress Deposited token's address; WETH address for ETH
    /// @param _blocksForActiveLiquidity For how many blocks the liquidity is locked.
    ///                                  Should be 0 if liquidity is passive
    function _provideLiquidity(
        uint256 _amount,
        address _tokenAddress,
        uint256 _blocksForActiveLiquidity
    ) private {
        uint256 finalAmount = _amount;
        //ETH
        if (msg.value > 0) {
            uint256 previousWethAmount = IWETH(_tokenAddress).balanceOf(address(this));
            IWETH(_tokenAddress).deposit{value: msg.value}();
            uint256 currentWethAmount = IWETH(_tokenAddress).balanceOf(address(this));
            require(currentWethAmount > previousWethAmount, "ERR: NOT WRAPPED");
            finalAmount = currentWethAmount - previousWethAmount;
            require(finalAmount >= msg.value, "ERR: LESS wETH THAN ETH");

            IERC20Upgradeable(_tokenAddress).safeTransfer(
                vaultConfig.getMosaicHolding(),
                finalAmount
            );
        } else {
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                vaultConfig.getMosaicHolding(),
                finalAmount
            );
        }
        if (_blocksForActiveLiquidity > 0) {
            //active liquidity
            IReceiptBase(vaultConfig.getUnderlyingIOUAddress(_tokenAddress)).mint(
                msg.sender,
                finalAmount
            );
            _updateActiveLiquidityAvailableAfterBlock(_tokenAddress, _blocksForActiveLiquidity);
            emit DepositActiveLiquidity(
                _tokenAddress,
                msg.sender,
                finalAmount,
                _blocksForActiveLiquidity
            );
        } else {
            //passive liquidity
            IReceiptBase(vaultConfig.getUnderlyingReceiptAddress(_tokenAddress)).mint(
                msg.sender,
                finalAmount
            );
            _updatePassiveLiquidityAvailableAfterTimestamp(_tokenAddress);
            emit DepositPassiveLiquidity(_tokenAddress, msg.sender, finalAmount);
        }
    }

    /// @notice Internal function called to update the availability of the active liquidity for a token and user
    /// @param _token address of the token which availability will be updated
    /// @param _blocksForActiveLiquidity number of blocks the active liquidity will last
    function _updateActiveLiquidityAvailableAfterBlock(
        address _token,
        uint256 _blocksForActiveLiquidity
    ) private {
        uint256 _availableAfter = activeLiquidityAvailableAfterBlock[msg.sender][_token];
        uint256 _newAvailability = block.number + _blocksForActiveLiquidity;
        if (_availableAfter < _newAvailability) {
            activeLiquidityAvailableAfterBlock[msg.sender][_token] = _newAvailability;
        }
    }

    /// @notice Internal function called to update the availability of the passive liquidity for a token and user
    /// @param _token address of the token which availability will be updated
    function _updatePassiveLiquidityAvailableAfterTimestamp(address _token) private {
        uint256 _availableAfter = passiveLiquidityAvailableAfterTimestamp[msg.sender][_token];
        uint256 _newAvailability = block.timestamp + vaultConfig.passiveLiquidityLocktime();
        if (_availableAfter < _newAvailability) {
            passiveLiquidityAvailableAfterTimestamp[msg.sender][_token] = _newAvailability;
        }
    }

    /// @notice External function called to add withdraw liquidity request
    /// @param _receiptToken Address of the iou token provider have
    /// @param _amountIn Amount of tokens provider want to withdraw
    /// @param _tokenOut Address of the token which LP wants to receive
    /// @param _ammID the amm to use for swapping
    /// @param _data extra call data
    /// @param _destinationNetworkId networkId of the _receiptToken's underlying token
    /// @param _withdrawRequestData set of data for withdraw
    function withdrawLiquidityRequest(
        address _receiptToken,
        uint256 _amountIn,
        address _tokenOut,
        address _destinationAddress,
        uint256 _ammID,
        bytes calldata _data,
        uint256 _destinationNetworkId,
        WithdrawRequestData calldata _withdrawRequestData
    ) external override nonReentrant returns (bytes32) {
        require(_amountIn > 0, "ERR: AMOUNT");
        require(paused() == false, "ERR: PAUSED");
        require(vaultConfig.pausedNetwork(_destinationNetworkId) == false, "ERR: PAUSED NETWORK");

        TemporaryWithdrawData memory tempData = _getTemporaryWithdrawData(
            _receiptToken,
            _tokenOut,
            _destinationNetworkId
        );

        require(IReceiptBase(_receiptToken).balanceOf(msg.sender) >= _amountIn, "ERR: BALANCE LOW");
        IReceiptBase(_receiptToken).burn(msg.sender, _amountIn);

        emit WithdrawRequest(
            msg.sender,
            _receiptToken,
            tempData.tokenIn,
            _amountIn,
            _tokenOut,
            tempData.remoteTokenIn,
            _destinationAddress,
            _ammID,
            _destinationNetworkId,
            _data,
            tempData.id,
            _withdrawRequestData
        );

        return tempData.id;
    }

    /// @dev for solving stack too deep error
    /// @param _receiptToken Address of the iou token provider have
    /// @param _tokenOut Address of the token which LP wants to receive
    /// @param _networkId networkId of the _receiptToken's underlying token
    function _getTemporaryWithdrawData(
        address _receiptToken,
        address _tokenOut,
        uint256 _networkId
    ) private validAddress(_tokenOut) returns (TemporaryWithdrawData memory) {
        address tokenIn = IReceiptBase(_receiptToken).underlyingToken();
        address remoteTokenIn;
        // this condition is needed when the withdraw liquidity is requested on another network
        if (_networkId != block.chainid) {
            remoteTokenIn = vaultConfig.remoteTokenAddress(_networkId, tokenIn);
            require(remoteTokenIn != address(0), "ERR: TOKEN NOT WHITELISTED DESTINATION");
        } else {
            remoteTokenIn = tokenIn;
        }

        if (vaultConfig.getUnderlyingIOUAddress(tokenIn) == _receiptToken) {
            // active liquidity
            // check if active liquidity is still locked
            require(
                activeLiquidityAvailableAfterBlock[msg.sender][tokenIn] <= block.number,
                "ERR: LIQUIDITY STILL LOCKED"
            );
        } else if (vaultConfig.getUnderlyingReceiptAddress(tokenIn) == _receiptToken) {
            // passive liquidity
            // check if passive liquidity is still locked
            require(
                passiveLiquidityAvailableAfterTimestamp[msg.sender][tokenIn] <= block.timestamp,
                "ERR: LIQUIDITY STILL LOCKED"
            );
            // passive liquidity can only be withdrawn in the same token
            require(remoteTokenIn == _tokenOut, "ERR: TOKEN OUT DIFFERENT");
        } else {
            revert("ERR: TOKEN NOT WHITELISTED");
        }
        return TemporaryWithdrawData(tokenIn, remoteTokenIn, vaultConfig.generateId());
    }

    /// @notice Called by relayer to withdraw liquidity from the vault
    /// @param _accountTo eth address to send the withdrawal tokens
    /// @param _amount amount of token in
    /// @param _tokenIn address of the token in
    /// @param _tokenOut address of the token out
    /// @param _amountOutMin minimum amount out user wants
    /// @param _withdrawData set of data for withdraw
    /// @param _data additional data required for each AMM implementation
    function withdrawLiquidity(
        address _accountTo,
        uint256 _amount,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin,
        WithdrawData calldata _withdrawData,
        bytes calldata _data
    ) external override {
        uint256 withdrawAmount = _withdraw(
            _accountTo,
            _amount,
            _tokenIn,
            _tokenOut,
            _amountOutMin,
            _withdrawData,
            _data
        );

        emit LiquidityWithdrawn(
            _accountTo,
            _tokenIn,
            _tokenOut,
            _amount,
            withdrawAmount,
            _withdrawData.baseFee,
            _withdrawData.feePercentage,
            _withdrawData.amountToSwapToNative > 0
        );
    }

    /// @notice method called by the relayer to release transfer funds
    /// @param _accountTo eth address to send the withdrawal tokens
    /// @param _amount amount of token in
    /// @param _tokenIn address of the token in
    /// @param _tokenOut address of the token out
    /// @param _amountOutMin minimum amount out user wants
    /// @param _withdrawData set of data for withdraw
    /// @param _data additional data required for each AMM implementation
    function withdrawTo(
        address _accountTo,
        uint256 _amount,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin,
        WithdrawData calldata _withdrawData,
        bytes calldata _data
    ) external override {
        uint256 withdrawAmount = _withdraw(
            _accountTo,
            _amount,
            _tokenIn,
            _tokenOut,
            _amountOutMin,
            _withdrawData,
            _data
        );

        emit WithdrawalCompleted(
            _accountTo,
            _amount,
            withdrawAmount,
            _tokenOut,
            _withdrawData.id,
            _withdrawData.amountToSwapToNative > 0
        );
    }

    /// @dev internal function called by `withdrawLiquidity` and `withdrawTo`
    /// @param _accountTo eth address to send the withdrawal tokens
    /// @param _amount amount of token in
    /// @param _tokenIn address of the token in
    /// @param _tokenOut address of the token out
    /// @param _amountOutMin minimum amount out user wants
    /// @param _withdrawData set of data for withdraw
    /// @param _data additional data required for each AMM implementation
    function _withdraw(
        address _accountTo,
        uint256 _amount,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin,
        WithdrawData calldata _withdrawData,
        bytes calldata _data
    )
        internal
        onlyWhitelistedToken(_tokenIn)
        validAddress(_tokenOut)
        nonReentrant
        onlyOwnerOrRelayer
        whenNotPaused
        returns (uint256 withdrawAmount)
    {
        IMosaicHolding mosaicHolding = IMosaicHolding(vaultConfig.getMosaicHolding());
        require(hasBeenWithdrawn[_withdrawData.id] == false, "ERR: ALREADY WITHDRAWN");
        if (_tokenOut == _tokenIn) {
            require(
                mosaicHolding.getTokenLiquidity(_tokenIn, _withdrawData.investmentStrategies) >=
                    _amount,
                "ERR: VAULT BAL"
            );
        }
        uint256 amountToNative = _withdrawData.amountToSwapToNative;
        if (amountToNative > 0) {
            require(vaultConfig.ableToPerformSmallBalanceSwap(), "ERR: UNABLE TO SWAP TO NATIVE");
        }
        require(amountToNative <= _amount, "ERR: AMOUNT TO NATIVE TOO HIGH");
        hasBeenWithdrawn[_withdrawData.id] = true;
        lastWithdrawID = _withdrawData.id;

        withdrawAmount = _takeFees(
            _tokenIn,
            _amount,
            _accountTo,
            _withdrawData.id,
            _withdrawData.baseFee,
            _withdrawData.feePercentage
        );

        mosaicHolding.coverWithdrawRequest(
            _withdrawData.investmentStrategies,
            _tokenIn,
            withdrawAmount
        );
        if (amountToNative > 0) {
            if (amountToNative > withdrawAmount) {
                amountToNative = withdrawAmount;
            }
            swapToNativeAndTransfer(
                _tokenIn,
                _accountTo,
                amountToNative,
                _withdrawData.nativeSwapperId
            );
            withdrawAmount -= amountToNative;
        }

        if (_tokenOut != _tokenIn) {
            withdrawAmount = _swap(
                withdrawAmount,
                _amountOutMin,
                _tokenIn,
                _tokenOut,
                _withdrawData.ammId,
                _data
            );
        }

        mosaicHolding.transfer(_tokenOut, _accountTo, withdrawAmount);
    }

    /// @notice Swaps `_amountToNative` from `_tokenIn` to native token and sends it to `_accountTo`
    /// @dev moved to function to avoid Stack too deep
    /// @param _tokenIn address of the token to be swapped
    /// @param _accountTo address which will receive the native tokens
    /// @param _amountToNative amount in `tokenIn` tokens that will be converted to native tokens
    function swapToNativeAndTransfer(
        address _tokenIn,
        address _accountTo,
        uint256 _amountToNative,
        uint256 _nativeSwapperId
    ) internal {
        address mosaicNativeSwapperAddress = vaultConfig.supportedMosaicNativeSwappers(
            _nativeSwapperId
        );
        require(mosaicNativeSwapperAddress != address(0), "ERR: NATIVE SWAPPER NOT SET");
        IMosaicNativeSwapper mosaicNativeSwapper = IMosaicNativeSwapper(mosaicNativeSwapperAddress);

        // holding => vault
        IMosaicHolding(vaultConfig.getMosaicHolding()).transfer(
            _tokenIn,
            address(this),
            _amountToNative
        );

        // vault => nativeSwapper
        IERC20Upgradeable(_tokenIn).safeIncreaseAllowance(
            mosaicNativeSwapperAddress,
            _amountToNative
        );
        mosaicNativeSwapper.swapToNative(_tokenIn, _amountToNative, _accountTo, "");
    }

    /// @notice in case of liquidity withdrawal request fails, the owner or the relayer calls this method to refund the user with his receipt tokens
    /// @param _user user's address
    /// @param _amount refunded amount which should be a bit smaller than the original one to cover the transaction cost
    /// @param _receiptToken receipt token user had
    /// @param _id request's id
    function revertLiquidityWithdrawalRequest(
        address _user,
        uint256 _amount,
        address _receiptToken,
        bytes32 _id
    ) external override onlyOwnerOrRelayer nonReentrant {
        require(_amount > 0, "ERR: AMOUNT");
        require(hasBeenRefunded[_id] == false, "REFUNDED");

        address tokenAddress = IReceiptBase(_receiptToken).underlyingToken();
        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;

        require(
            tokenAddress != address(0) &&
                (vaultConfig.getUnderlyingReceiptAddress(tokenAddress) != address(0) ||
                    vaultConfig.getUnderlyingIOUAddress(tokenAddress) != address(0)),
            "ERR: TOKEN NOT WHITELISTED"
        );

        if (vaultConfig.getUnderlyingIOUAddress(tokenAddress) == _receiptToken) {
            IReceiptBase(vaultConfig.getUnderlyingIOUAddress(tokenAddress)).mint(_user, _amount);
        } else if (vaultConfig.getUnderlyingReceiptAddress(tokenAddress) == _receiptToken) {
            IReceiptBase(vaultConfig.getUnderlyingReceiptAddress(tokenAddress)).mint(
                _user,
                _amount
            );
        }

        emit LiquidityRefunded(tokenAddress, _receiptToken, _user, _amount, _id);
    }

    /// @dev internal function called to calculate the on-chain fees
    /// @param _token address of the token in
    /// @param _amount amount of token in
    /// @param _accountTo address who will receive the withdrawn liquidity
    /// @param _withdrawRequestId id of the withdraw request
    /// @param _baseFee base fee of the withdraw
    /// @param _feePercentage fee percentage of the withdraw
    function _takeFees(
        address _token,
        uint256 _amount,
        address _accountTo,
        bytes32 _withdrawRequestId,
        uint256 _baseFee,
        uint256 _feePercentage
    ) private returns (uint256) {
        if (_baseFee > 0) {
            IMosaicHolding(vaultConfig.getMosaicHolding()).transfer(_token, relayer, _baseFee);
        }
        uint256 fee = 0;
        if (_feePercentage > 0) {
            require(
                _feePercentage >= vaultConfig.minFee() && _feePercentage <= vaultConfig.maxFee(),
                "ERR: FEE PERCENTAGE OUT OF RANGE"
            );

            fee = FeeOperations.getFeeAbsolute(_amount, _feePercentage);

            IMosaicHolding(vaultConfig.getMosaicHolding()).transfer(
                _token,
                vaultConfig.getMosaicHolding(),
                fee
            );
        }

        uint256 totalFee = _baseFee + fee;
        require(totalFee < _amount, "ERR: FEE EXCEEDS AMOUNT");
        if (totalFee > 0) {
            emit FeeTaken(
                msg.sender,
                _accountTo,
                _token,
                _amount,
                fee,
                _baseFee,
                fee + _baseFee,
                _withdrawRequestId
            );
        }
        return _amount - totalFee;
    }

    /// @dev internal function used to swap tokens
    /// _amountIn amount of the token in
    /// _amountOutMin min amount expected of the token out after the swap
    /// _tokenIn address of the token in
    /// _tokenOut address of the token out
    /// _ammID the amm to use for swapping
    /// _data extra call data for the swap
    function _swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        address _tokenOut,
        uint256 _ammID,
        bytes memory _data
    ) private returns (uint256) {
        address mosaicHolding = vaultConfig.getMosaicHolding();
        IMosaicHolding(mosaicHolding).transfer(_tokenIn, address(this), _amountIn);
        address ammAddress = vaultConfig.supportedAMMs(_ammID);
        require(ammAddress != address(0), "ERR: AMM NOT SUPPORTED");

        IERC20Upgradeable(_tokenIn).safeApprove(ammAddress, _amountIn);

        uint256 amountToSend = IMosaicExchange(ammAddress).swap(
            _tokenIn,
            _tokenOut,
            _amountIn,
            _amountOutMin,
            _data
        );
        require(amountToSend >= _amountOutMin, "ERR: AMM PRICE LOW");
        IERC20Upgradeable(_tokenOut).safeTransfer(mosaicHolding, amountToSend);
        return amountToSend;
    }

    /// @notice transfer ERC20 token to another Mosaic vault
    /// @param _amount amount of tokens to transfer
    /// @param _tokenAddress SC address of the ERC20 token to transfer
    /// @param _remoteDestinationAddress address that will receive the transfer on destination
    /// @param _remoteNetworkID destination network
    /// @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
    /// @param _tokenOut SC address of the ERC20 token that will be received in the destination network
    /// @param _remoteAmmId id of the AMM that will be used in the destination network
    /// @param _amountOutMin min amount of the token out the user expects to receive
    /// @param _swapToNative true if a part will be swapped to native token in destination
    function transferERC20ToLayer(
        uint256 _amount,
        address _tokenAddress,
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId,
        uint256 _amountOutMin,
        bool _swapToNative
    )
        external
        override
        onlyWhitelistedRemoteTokens(_remoteNetworkID, _tokenAddress)
        nonReentrant
        whenNotPausedNetwork(_remoteNetworkID)
        returns (bytes32 transferId)
    {
        require(_amount > 0, "ERR: AMOUNT");

        transferId = vaultConfig.generateId();

        uint256[3] memory ammConfig;
        ammConfig[0] = _remoteAmmId;
        ammConfig[1] = _maxTransferDelay;
        ammConfig[2] = _amountOutMin;

        _transferERC20ToLayer(
            _amount,
            _tokenAddress,
            _remoteDestinationAddress,
            _remoteNetworkID,
            _tokenOut,
            ammConfig,
            transferId,
            _swapToNative
        );
    }

    /// @notice transfer ETH converted to WETH to another Mosaic vault
    /// @param _remoteDestinationAddress address that will receive the transfer on destination
    /// @param _remoteNetworkID destination network
    /// @param _maxTransferDelay delay in seconds for the relayer to execute the transaction
    /// @param _tokenOut SC address of the ERC20 token that will be received in the destination network
    /// @param _remoteAmmId id of the AMM that will be used in the destination network
    /// @param _amountOutMin min amount of the token out the user expects to receive
    /// @param _swapToNative true if a part will be swapped to native token in destination
    function transferETHToLayer(
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        uint256 _maxTransferDelay,
        address _tokenOut,
        uint256 _remoteAmmId,
        uint256 _amountOutMin,
        bool _swapToNative
    )
        external
        payable
        override
        nonReentrant
        whenNotPausedNetwork(_remoteNetworkID)
        returns (bytes32 transferId)
    {
        require(msg.value > 0, "ERR: AMOUNT");
        address weth = vaultConfig.wethAddress();
        require(weth != address(0), "ERR: WETH NOT SET");
        require(
            vaultConfig.getUnderlyingIOUAddress(weth) != address(0),
            "ERR: WETH NOT WHITELISTED"
        );
        // check if ETH transfer is possible
        require(
            vaultConfig.remoteTokenAddress(_remoteNetworkID, weth) != address(0),
            "ERR: ETH NOT WHITELISTED REMOTE"
        );

        uint256[3] memory ammConfig;
        ammConfig[0] = _remoteAmmId;
        ammConfig[1] = _maxTransferDelay;
        ammConfig[2] = _amountOutMin;

        transferId = vaultConfig.generateId();
        _transferERC20ToLayer(
            msg.value,
            vaultConfig.wethAddress(),
            _remoteDestinationAddress,
            _remoteNetworkID,
            _tokenOut,
            ammConfig,
            transferId,
            _swapToNative
        );
    }

    /// @dev Internal function called to transfer ERC20 to another Mosaic vault
    /// @param _amount amount of tokens to transfer
    /// @param _tokenAddress SC address of the ERC20 token to transfer
    /// @param _remoteDestinationAddress address that will receive the transfer on destination
    /// @param _remoteNetworkID destination network
    /// @param _tokenOut SC address of the ERC20 token that will be received in the destination network
    /// @param _ammConfig => 0 - amm id , 1 - delay, 2, amount out
    /// @param _id id of the transfer
    /// @param _swapToNative true if a part will be swapped to native token in destination
    function _transferERC20ToLayer(
        uint256 _amount,
        address _tokenAddress,
        address _remoteDestinationAddress,
        uint256 _remoteNetworkID,
        address _tokenOut,
        uint256[3] memory _ammConfig, // 0 - amm id , 1 - delay, 2, amount out
        bytes32 _id,
        bool _swapToNative
    ) private inTokenTransferLimits(_tokenAddress, _amount) {
        if (_tokenAddress == vaultConfig.wethAddress()) {
            // convert to WETH
            IWETH(_tokenAddress).deposit{value: _amount}();
            // transfer funds to holding
            IERC20Upgradeable(_tokenAddress).safeTransfer(vaultConfig.getMosaicHolding(), _amount);
        } else {
            // transfer funds to holding
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender,
                vaultConfig.getMosaicHolding(),
                _amount
            );
        }

        deposits[_id] = DepositInfo({token: _tokenAddress, amount: _amount});

        // NOTE: _tokenOut == address(0) is reserved for
        //       the native token of the destination layer
        //       for eg: MATIC for Polygon
        emit TransferInitiated(
            msg.sender,
            _tokenAddress,
            vaultConfig.remoteTokenAddress(_remoteNetworkID, _tokenAddress),
            _remoteNetworkID,
            _amount,
            _remoteDestinationAddress,
            _id,
            _ammConfig[1],
            _tokenOut,
            _ammConfig[0],
            _ammConfig[2],
            _swapToNative
        );
    }

    /*
     * @dev returns transfer state
     * @param _transferId id of the transfer
     */
    function getTransferState(bytes32 _transferId)
        external
        view
        override
        returns (TransferState transferState)
    {
        if (hasBeenRefunded[_transferId]) {
            transferState = TransferState.REFUNDED;
        } else if (hasBeenWithdrawn[_transferId]) {
            transferState = TransferState.SUCCESS;
        } else {
            transferState = TransferState.UNKNOWN;
        }
    }

    /// @notice called by the owner of the contract or by the relayer to return funds back to the user in case of a failed transfer
    ///         This method will mark the `id` as used and emit the event that funds have been refunded
    /// @param _token address of the ERC20 token
    /// @param _user address of the user that will receive the tokens
    /// @param _amount amount of tokens to be refunded
    /// @param _originalAmount amount of tokens transfered in the first place
    /// @param _id id of the original transfer
    /// @param _investmentStrategies list of addresses of the investment strategies
    function refundTransferFunds(
        address _token,
        address _user,
        uint256 _amount,
        uint256 _originalAmount,
        bytes32 _id,
        address[] calldata _investmentStrategies
    ) external override nonReentrant onlyOwnerOrRelayer {
        // should not be refunded
        require(hasBeenRefunded[_id] == false, "ERR: ALREADY REFUNDED");

        // check if the vault has enough locked balance
        require(
            IMosaicHolding(vaultConfig.getMosaicHolding()).getTokenLiquidity(
                _token,
                _investmentStrategies
            ) >= _amount,
            "ERR: VAULT BAL"
        );

        // check if the deposit data matches
        require(
            deposits[_id].token == _token && deposits[_id].amount == _originalAmount,
            "ERR: INVALID DEPOSIT"
        );

        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;

        IMosaicHolding mosaicHolding = IMosaicHolding(vaultConfig.getMosaicHolding());
        mosaicHolding.coverWithdrawRequest(_investmentStrategies, _token, _amount);
        mosaicHolding.transfer(_token, _user, _amount);

        delete deposits[_id];

        emit TransferFundsRefunded(_token, _user, _amount, _originalAmount, _id);
    }

    /**
     * @notice Used to transfer randomly sent tokens to this contract to the Mosaic holding
     * @param _token Token's address
     */
    function digestFunds(address _token) external override onlyOwner validAddress(_token) {
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(balance > 0, "ERR: BALANCE");
        IERC20Upgradeable(_token).safeTransfer(vaultConfig.getMosaicHolding(), balance);
        emit FundsDigested(_token, balance);
    }

    /// @notice External payable function called when ether is sent to the contract
    ///         Receiving ether is considered an active liquidity
    receive() external payable {
        provideActiveLiquidity(0, address(0), vaultConfig.maxLimitLiquidityBlocks());
    }

    /// @notice External callable function to pause the contract
    function pause() external override whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice External callable function to unpause the contract
    function unpause() external override whenPaused onlyOwner {
        _unpause();
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "ERR: INVALID ADDRESS");
        _;
    }

    modifier onlyWhitelistedToken(address _tokenAddress) {
        require(
            vaultConfig.getUnderlyingIOUAddress(_tokenAddress) != address(0),
            "ERR: TOKEN NOT WHITELISTED"
        );
        _;
    }

    modifier onlyWhitelistedRemoteTokens(uint256 _networkID, address _tokenAddress) {
        require(
            vaultConfig.remoteTokenAddress(_networkID, _tokenAddress) != address(0),
            "ERR: TOKEN NOT WHITELISTED DESTINATION"
        );
        _;
    }

    modifier whenNotPausedNetwork(uint256 _networkID) {
        require(paused() == false, "ERR: PAUSED");
        require(vaultConfig.pausedNetwork(_networkID) == false, "ERR: PAUSED NETWORK");
        _;
    }

    modifier onlyOwnerOrRelayer() {
        require(_msgSender() == owner() || _msgSender() == relayer, "ERR: PERMISSIONS");
        _;
    }

    modifier inTokenTransferLimits(address _token, uint256 _amount) {
        require(vaultConfig.inTokenTransferLimits(_token, _amount), "ERR: TRANSFER LIMITS");
        _;
    }

    modifier inBlockApproveRange(uint256 _blocksForActiveLiquidity) {
        require(
            _blocksForActiveLiquidity >= vaultConfig.minLimitLiquidityBlocks() &&
                _blocksForActiveLiquidity <= vaultConfig.maxLimitLiquidityBlocks(),
            "ERR: BLOCK RANGE"
        );
        _;
    }
}