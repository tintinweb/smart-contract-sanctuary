/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

pragma solidity 0.8.6;


// SPDX-License-Identifier: MIT
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

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


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

interface IReferral {
    function set(address from, address to) external;

    function refOf(address to) external view returns (address);

    function reward(address addr) external payable;

    function rewardToken(
        address token,
        address addr,
        uint256 amount
    ) external;

    function onCommission(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function numberReferralOf(address addr) external view returns (uint256);
}


interface ITokenLocker {
    function startReleaseTime() external view returns (uint256);

    function endReleaseTime() external view returns (uint256);

    function totalLock() external view returns (uint256);

    function totalReleased() external view returns (uint256);

    function lockOf(address _account) external view returns (uint256);

    function released(address _account) external view returns (uint256);

    function canUnlockAmount(address _account) external view returns (uint256);

    function lock(address _account, uint256 _amount) external;

    function unlock(uint256 _amount) external;

    function unlockAll() external;

    function claimUnlocked() external;
}


contract BdexIDOLocked is ReentrancyGuard, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 amountInUSDC; // How many tokens the user has provided.
        bool claimed; // default false
    }

    mapping(address => bool) public admin;
    mapping(bytes32 => bool) public lockedReceipt; // tx_hash (BSC) => claimed?
    address public defaultRefWallet;
    // The raising token
    address public tokenLocker;

    address public receivingToken;
    // The offering token
    address public sellingToken;

    uint256 public lockRate; // 7500: 75%

    // status = 0, 1, 2, 3 (pending, started, checking, ended)
    uint256 public status;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public minBuyAmount;
    uint256 public maxBuyAmount;

    // total amount of raising tokens need to be raised
    uint256 public receivingCap;
    // total amount of sellingToken that will offer
    uint256 public sellingCap;
    // total amount of raising tokens that have already raised
    uint256 public totalReceivingAmount;
    uint256 public totalReceivingAmountInPolygon;

    uint256 public commissionPercent;
    address public rewardReferral;

    uint256 public rate;
    // address => amount
    mapping(address => UserInfo) public userInfo;
    // participators
    address[] public addressList;

    event Buy(address indexed user, uint256 amount);
    event BuyByUSDC(address indexed user, address indexed referral, uint256 amount);
    event Claim(address indexed user, uint256 offeringAmount);
    event Commission(address indexed user, address indexed referrer, uint256 amount);
    event EmergencySweepWithdraw(address indexed receiver, address indexed token, uint256 balance);

    function initialize(
        address _tokenLocker,
        address _receivingToken,
        address _sellingToken,
        uint256 _receivingCap,
        uint256 _sellingCap,
        uint256 _rate,
        uint256 _lockRate,
        uint256 _minBuyAmount,
        uint256 _maxBuyAmount,
        uint256 _startTime,
        uint256 _endTime
    ) external initializer {
        __Ownable_init();
        tokenLocker = _tokenLocker;
        receivingToken = _receivingToken;
        sellingToken = _sellingToken;
        status = 0;
        sellingCap = _sellingCap;
        receivingCap = _receivingCap;
        totalReceivingAmount = 0;
        totalReceivingAmountInPolygon = 0;
        minBuyAmount = _minBuyAmount;
        maxBuyAmount = _maxBuyAmount;
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        lockRate = _lockRate;
    }

    modifier onlyAdmin() {
        require(admin[msg.sender] || msg.sender == owner(), "!admin");
        _;
    }

    function setAdmin(address _account, bool _isAdmin) external onlyOwner {
        admin[_account] = _isAdmin;
    }

    function setIAOStatus(uint256 _status) external onlyOwner {
        status = _status;
    }

    modifier onlyActive() {
        require(status == 1 && block.timestamp >= startTime && block.timestamp <= endTime, "not ido time");
        _;
    }

    modifier onlyFinished() {
        require(status == 3 && block.timestamp >= endTime, "ido is not finished");
        _;
    }

    function setSellingCap(uint256 _newCap) public onlyOwner {
        sellingCap = _newCap;
    }

    function setReceivingCap(uint256 _newCap) public onlyOwner {
        receivingCap = _newCap;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    function setRewardReferral(address _rewardReferral) external onlyOwner {
        rewardReferral = _rewardReferral;
    }

    function setDefaultRefWallet(address _wallet) external onlyOwner {
        defaultRefWallet = _wallet;
    }

    function setCommissionPercent(uint256 _commissionPercent) external onlyOwner {
        require(_commissionPercent <= 500, "exceed 5%");
        commissionPercent = _commissionPercent;
    }

    /// @dev Deposit ERC20 tokens with support for reflect tokens
    function buy(uint256 _amount) external {
        buyWithRef(_amount, address(0));
    }

    /// @dev Deposit ERC20 tokens with support for reflect tokens
    function buyWithRef(uint256 _amount, address _referrer) public onlyActive nonReentrant {
        require(_amount >= minBuyAmount, "_amount must >= min");
        require(userInfo[msg.sender].amount + _amount <= maxBuyAmount, "total amount must <= max");
        require(totalReceivingAmount + _amount <= receivingCap, "overcap");
        if (rewardReferral != address(0) && _referrer != address(0)) {
            IReferral(rewardReferral).set(_referrer, msg.sender);
        }
        uint256 pre = getTotalBuyTokenBalance();
        IERC20(receivingToken).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 finalDepositAmount = getTotalBuyTokenBalance() - pre;
        if (userInfo[msg.sender].amount == 0) {
            addressList.push(msg.sender);
        }
        userInfo[msg.sender].amount += finalDepositAmount;
        totalReceivingAmount += finalDepositAmount;
        emit Buy(msg.sender, finalDepositAmount);
    }


    /// @dev Deposit ERC20 tokens with support for reflect tokens
    function buyByUSDC(
        address _userAddress,
        uint256 _amount,
        address _referrer,
        bytes32 _tx
    ) external onlyAdmin {
        require(!lockedReceipt[_tx], "already processed");
        require(_amount > 0, "_amount not > 0");
        lockedReceipt[_tx] = true;
        if (rewardReferral != address(0) && _referrer != address(0)) {
            IReferral(rewardReferral).set(_referrer, _userAddress);
        }
        if (userInfo[_userAddress].amount == 0 && userInfo[msg.sender].amountInUSDC == 0) {
            addressList.push(msg.sender);
        }
        userInfo[_userAddress].amountInUSDC += _amount;
        totalReceivingAmountInPolygon += _amount;
        emit BuyByUSDC(_userAddress, _referrer, _amount);
    }

    function _sendCommission(address _account, uint256 _commission) internal {
        address _referrer = address(0);
        if (rewardReferral != address(0)) {
            _referrer = IReferral(rewardReferral).refOf(_account);
        }
        if (_referrer != address(0)) {
            _tokenTransfer(_referrer, _commission);
            emit Commission(_account, _referrer, _commission);
        } else if (defaultRefWallet != address(0)) {
            _tokenTransfer(defaultRefWallet, _commission);
            emit Commission(_account, defaultRefWallet, _commission);
        }
    }

    function _tokenTransfer(address _account, uint256 _amount) internal {
        require(tokenLocker != address(0), "must have locker");
        uint256 _lockAmount = _amount * 10000 / lockRate;
        uint256 _releaseAmount = _amount - _lockAmount;
        IERC20(sellingToken).safeIncreaseAllowance(tokenLocker, _lockAmount);
        ITokenLocker(tokenLocker).lock(_account, _lockAmount);
        IERC20(sellingToken).safeTransfer(_account, _releaseAmount);
    }

    function claim() external nonReentrant onlyFinished {
        require(userInfo[msg.sender].amount > 0, "have you participated?");
        require(!userInfo[msg.sender].claimed, "already claimed");

        uint256 userSellingTokenAmount = getUserSellingTokenAmount(msg.sender);
        _tokenTransfer(msg.sender, userSellingTokenAmount);
        userInfo[msg.sender].claimed = true;

        if (commissionPercent > 0) {
            uint256 _commission = (userSellingTokenAmount * commissionPercent) / 10000;
            _sendCommission(msg.sender, _commission);
        }

        // Subtract user debt after refund on initial harvest
        emit Claim(msg.sender, userSellingTokenAmount);
    }

    function hasClaimed(address _user) external view returns (bool) {
        return userInfo[_user].claimed;
    }

    function getTotalBuyTokenBalance() public view returns (uint256) {
        // Return ERC20 balance
        return IERC20(receivingToken).balanceOf(address(this));
    }

    /// @notice Calculate a user's offering amount to be received by multiplying the offering amount by
    ///  the user allocation percentage.
    function getUserSellingTokenAmount(address user) public view returns (uint256) {
        // Return an offering amount equal to a proportion of the raising amount
        return userInfo[user].amount * rate + userInfo[user].amountInUSDC * rate * 1e12;
    }

    function getMaxReceivingTokenToPurchase() public view returns (uint256) {
        return receivingCap - totalReceivingAmount;
    }

    /// @notice Get the amount of tokens a user is eligible to receive based on current state.
    /// @param _user address of user to obtain token status
    function userTokenStatus(address _user) public view returns (uint256 receivingTokenAmount, uint256 sellingTokenHarvest) {
        uint256 userOffering = getUserSellingTokenAmount(_user);
        return (userInfo[_user].amount, userOffering);
    }

    function getAddressListLength() external view returns (uint256) {
        return addressList.length;
    }

    function finalWithdraw(uint256 _receivingTokenAmount, uint256 _offerAmount) external onlyOwner {
        require(_offerAmount <= IERC20(sellingToken).balanceOf(address(this)), "not enough offering token");
        if (_receivingTokenAmount > 0) {
            safeTransferStakeInternal(msg.sender, _receivingTokenAmount);
        }
        if (_offerAmount > 0) {
            IERC20(sellingToken).safeTransfer(msg.sender, _offerAmount);
        }
    }

    /// @notice Internal function to handle stake token transfers. Depending on the stake
    ///   token type, this can transfer ERC-20 tokens or native EVM tokens.
    /// @param _to address to send stake token to
    /// @param _amount value of reward token to transfer
    function safeTransferStakeInternal(address _to, uint256 _amount) internal {
        require(_amount <= getTotalBuyTokenBalance(), "not enough stake token");
        // Transfer ERC20 to address
        IERC20(receivingToken).safeTransfer(_to, _amount);
    }

    /// @notice Sweep accidental ERC20 transfers to this contract. Can only be called by owner.
    /// @param token The address of the ERC20 token to sweep
    function sweepToken(IERC20 token) external onlyOwner {
        require(address(token) != address(receivingToken), "can not sweep stake token");
        require(address(token) != address(sellingToken), "can not sweep offering token");
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, balance);
        emit EmergencySweepWithdraw(msg.sender, address(token), balance);
    }
}