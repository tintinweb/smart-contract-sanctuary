/**
 *Submitted for verification at snowtrace.io on 2022-01-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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
 * 
 * The renounceOwnership removed to prevent accidents
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a withdrawer) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the withdrawer account will be the one that deploys the contract. This
 * can later be changed with {transferWithdrawership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyWithdrawer`, which can be applied to your functions to restrict their use to
 * the withdrawer.
 */
abstract contract Withdrawable is Context, Ownable {

    /**
     * @dev So here we seperate the rights of the classic ownership into 'owner' and 'withdrawer'
     * this way the developer/owner stays the 'owner' and can make changes at any time
     * but cannot withdraw anymore as soon as the 'withdrawer' gets changes (to the chef contract)
     */
    address private _withdrawer;

    event WithdrawershipTransferred(address indexed previousWithdrawer, address indexed newWithdrawer);

    /**
     * @dev Initializes the contract setting the deployer as the initial withdrawer.
     */
    constructor () {
        address msgSender = _msgSender();
        _withdrawer = msgSender;
        emit WithdrawershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current withdrawer.
     */
    function withdrawer() public view returns (address) {
        return _withdrawer;
    }

    /**
     * @dev Throws if called by any account other than the withdrawer.
     */
    modifier onlyWithdrawer() {
        require(_withdrawer == _msgSender(), "Withdrawable: caller is not the withdrawer");
        _;
    }

    /**
     * @dev Transfers withdrawership of the contract to a new account (`newWithdrawer`).
     * Can only be called by the current owner.
     */
    function transferWithdrawership(address newWithdrawer) public virtual onlyOwner {
        require(newWithdrawer != address(0), "Withdrawable: new withdrawer is the zero address");

        emit WithdrawershipTransferred(_withdrawer, newWithdrawer);
        _withdrawer = newWithdrawer;
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
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
}

interface IStatikToken is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}

interface IThorusRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract StatikMaster is Ownable, Withdrawable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IStatikToken;

    IStatikToken public immutable statik;
    IERC20 public immutable usdc;
    IERC20 public immutable thorus;
    IThorusRouter public immutable thorusRouter;
    address public treasury;
    address public strategist;

    address[] public swapPath;
    address[] public swapPathReverse;

    uint public thorusPermille = 200;
    uint public treasuryPermille = 19;
    uint public feePermille = 10;

    uint256 public maxStakeAmount;
    uint256 public maxRedeemAmount;
    uint256 public maxStakePerSecond;
    uint256 internal lastSecond;
    uint256 internal lastSecondUsdcStaked;
    uint256 internal lastSecondThorusPermilleChanged;

    uint256 internal constant decimalDifference = 10 ** 12;
    address private constant dead = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) public statikClaimAmount;
    mapping(address => uint256) public statikClaimSecond;
    mapping(address => uint256) public usdcClaimAmount;
    mapping(address => uint256) public usdcClaimSecond;
    uint256 public totalUsdcClaimAmount;

    event Stake(address indexed user, uint256 amount);
    event StatikClaim(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event UsdcClaim(address indexed user, uint256 amount);
    event UsdcWithdrawn(uint256 amount);
    event ThorusWithdrawn(uint256 amount);
    event SwapPathChanged(address[] swapPath);
    event ThorusPermilleChanged(uint256 thorusPermille);
    event TreasuryPermilleChanged(uint256 treasuryPermille);
    event FeePermilleChanged(uint256 feePermille);
    event TreasuryAddressChanged(address treasury);
    event StrategistAddressChanged(address strategist);
    event MaxStakeAmountChanged(uint256 maxStakeAmount);
    event MaxRedeemAmountChanged(uint256 maxRedeemAmount);
    event MaxStakePerSecondChanged(uint256 maxStakePerSecond);

    constructor(IStatikToken _statik, IERC20 _usdc, IERC20 _thorus, IThorusRouter _thorusRouter, address _treasury, uint256 _maxStakeAmount, uint256 _maxRedeemAmount, uint256 _maxStakePerSecond) {
        require(
            address(_statik) != address(0) &&
            address(_usdc) != address(0) &&
            address(_thorus) != address(0) &&
            address(_thorusRouter) != address(0) &&
            _treasury != address(0),
            "zero address in constructor"
        );
        statik = _statik;
        usdc = _usdc;
        thorus = _thorus;
        thorusRouter = _thorusRouter;
        treasury = _treasury;
        swapPath = [address(usdc), address(thorus)];
        swapPathReverse = [address(thorus), address(usdc)];
        maxStakeAmount = _maxStakeAmount;
        maxRedeemAmount = _maxRedeemAmount;
        maxStakePerSecond = _maxStakePerSecond;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSwapPath(address[] calldata _swapPath) external onlyOwner {
        require(_swapPath.length > 1 && _swapPath[0] == address(usdc) && _swapPath[_swapPath.length - 1] == address(thorus), "invalid swap path");
        swapPath = _swapPath;
        swapPathReverse = new address[](_swapPath.length);
        for(uint256 i=0; i<_swapPath.length; i++)
            swapPathReverse[i] = _swapPath[_swapPath.length - 1 - i];

        emit SwapPathChanged(_swapPath);
    }

    function setThorusPermille(uint _thorusPermille) external onlyOwner {
        require(_thorusPermille <= 500, 'thorusPermille too high!');
        thorusPermille = _thorusPermille;
        lastSecondThorusPermilleChanged = block.timestamp;

        emit ThorusPermilleChanged(_thorusPermille);
    }

    function setTreasuryPermille(uint _treasuryPermille) external onlyOwner {
        require(_treasuryPermille <= 50, 'treasuryPermille too high!');
        treasuryPermille = _treasuryPermille;

        emit TreasuryPermilleChanged(_treasuryPermille);
    }

    function setFeePermille(uint _feePermille) external onlyOwner {
        require(_feePermille <= 20, 'feePermille too high!');
        feePermille = _feePermille;

        emit FeePermilleChanged(_feePermille);
    }

    function setTreasuryAddress(address _treasury) external onlyOwner {
        require(_treasury != address(0), 'zero address');
        treasury = _treasury;

        emit TreasuryAddressChanged(_treasury);
    }

    function setStrategistAddress(address _strategist) external onlyOwner {
        strategist = _strategist;

        emit StrategistAddressChanged(_strategist);
    }

    function setMaxStakeAmount(uint256 _maxStakeAmount) external onlyOwner {
        require(maxStakePerSecond >= _maxStakeAmount, 'value not valid');
        maxStakeAmount = _maxStakeAmount;

        emit MaxStakeAmountChanged(_maxStakeAmount);
    }

    function setMaxRedeemAmount(uint256 _maxRedeemAmount) external onlyOwner {
        maxRedeemAmount = _maxRedeemAmount;

        emit MaxRedeemAmountChanged(_maxRedeemAmount);
    }

    function setMaxStakePerSecond(uint256 _maxStakePerSecond) external onlyOwner {
        require(_maxStakePerSecond >= maxStakeAmount, 'value not valid');
        maxStakePerSecond = _maxStakePerSecond;

        emit MaxStakePerSecondChanged(_maxStakePerSecond);
    }

    function stake(uint256 amount, uint256 thorusAmountOutMin, uint256 statikAmountOutMin) external nonReentrant whenNotPaused {
        require(block.timestamp > lastSecondThorusPermilleChanged, 'thorusPermille just changed');
        require(amount > 0, 'amount cannot be zero');
        require(statikClaimAmount[msg.sender] == 0, 'you have to claim first');
        require(amount <= maxStakeAmount, 'amount too high');
        if(lastSecond != block.timestamp) {
            lastSecondUsdcStaked = amount;
            lastSecond = block.timestamp;
        } else {
            lastSecondUsdcStaked += amount;
        }
        require(lastSecondUsdcStaked <= maxStakePerSecond, 'maximum stake per second exceeded');

        usdc.safeTransferFrom(msg.sender, address(this), amount);
        if(feePermille > 0) {
            uint256 feeAmount = amount * feePermille / 1000;
            usdc.safeTransfer(treasury, feeAmount);
            amount = amount - feeAmount;
        }

        uint256 amountWithDecimals = amount * decimalDifference;

        statik.mint(address(this), amountWithDecimals);
        uint256 thorusAmount = amount * thorusPermille / 1000;
        usdc.approve(address(thorusRouter), thorusAmount);
        thorusRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            thorusAmount,
            thorusAmountOutMin,
            swapPath,
            address(this),
            block.timestamp
        );

        require(amountWithDecimals >= statikAmountOutMin, 'statikAmountOutMin not met');
        statikClaimAmount[msg.sender] = amountWithDecimals;
        statikClaimSecond[msg.sender] = block.timestamp;

        emit Stake(msg.sender, amount);
    }

    function claimStatik() external nonReentrant whenNotPaused {
        require(statikClaimAmount[msg.sender] > 0, 'there is nothing to claim');
        require(statikClaimSecond[msg.sender] < block.timestamp, 'you cannnot claim yet');

        uint256 amount = statikClaimAmount[msg.sender];
        statikClaimAmount[msg.sender] = 0;
        statik.safeTransfer(msg.sender, amount);

        emit StatikClaim(msg.sender, amount);
    }

    function redeem(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, 'amount cannot be zero');
        require(usdcClaimAmount[msg.sender] == 0, 'you have to claim first');
        require(amount <= maxRedeemAmount, 'amount too high');

        statik.safeTransferFrom(msg.sender, dead, amount);
        usdcClaimAmount[msg.sender] = amount;
        usdcClaimSecond[msg.sender] = block.timestamp;
        totalUsdcClaimAmount += amount;

        emit Redeem(msg.sender, amount);
    }

    function claimUsdc(uint256 thorusAmountOutMin, uint256 usdcAmountOutMin) external nonReentrant whenNotPaused {
        require(usdcClaimAmount[msg.sender] > 0, 'there is nothing to claim');
        require(usdcClaimSecond[msg.sender] < block.timestamp, 'you cannnot claim yet');
        require(block.timestamp > lastSecondThorusPermilleChanged, 'thorusPermille just changed');

        uint256 amount = usdcClaimAmount[msg.sender];
        usdcClaimAmount[msg.sender] = 0;
        totalUsdcClaimAmount -= amount;

        uint256 amountWithoutDecimals = amount / decimalDifference;

        uint256 usdcTransferAmount = amountWithoutDecimals * (1000 - thorusPermille - treasuryPermille) / 1000;
        require(usdcTransferAmount >= usdcAmountOutMin, 'usdcAmountOutMin not met');
        uint256 usdcTreasuryAmount = amountWithoutDecimals * treasuryPermille / 1000;
        uint256 thorusTransferAmount = thorus.balanceOf(address(this)) * amount / statik.totalSupply();
        statik.burn(amount);
        usdc.safeTransfer(treasury, usdcTreasuryAmount);
        usdc.safeTransfer(msg.sender, usdcTransferAmount);
        thorus.approve(address(thorusRouter), thorusTransferAmount);
        thorusRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            thorusTransferAmount,
            thorusAmountOutMin,
            swapPathReverse,
            msg.sender,
            block.timestamp
        );

        emit UsdcClaim(msg.sender, amount);
    }

    function emergencyRedeemAll() external nonReentrant whenPaused {
        uint256 amount = statik.balanceOf(msg.sender);
        require(amount > 0, 'amount cannot be zero');
        require(usdcClaimAmount[msg.sender] == 0, 'you have to claim first');
        statik.safeTransferFrom(msg.sender, dead, amount);
        usdcClaimAmount[msg.sender] = amount;
        usdcClaimSecond[msg.sender] = block.timestamp;
        totalUsdcClaimAmount += amount;

        emit Redeem(msg.sender, amount);
    }

    function emergencyClaimUsdcAll() external nonReentrant whenPaused {
        require(usdcClaimAmount[msg.sender] > 0, 'there is nothing to claim');
        require(usdcClaimSecond[msg.sender] < block.timestamp, 'you cannot claim yet');

        uint256 amount = usdcClaimAmount[msg.sender];
        usdcClaimAmount[msg.sender] = 0;
        totalUsdcClaimAmount -= amount;

        uint256 amountWithoutDecimals = amount / decimalDifference;

        uint256 usdcTransferAmount = amountWithoutDecimals * (1000 - thorusPermille - treasuryPermille) / 1000;
        uint256 usdcTreasuryAmount = amountWithoutDecimals * treasuryPermille / 1000;
        statik.burn(amount);
        usdc.safeTransfer(treasury, usdcTreasuryAmount);
        usdc.safeTransfer(msg.sender, usdcTransferAmount);

        emit UsdcClaim(msg.sender, amount);
    }

    function withdrawUsdc(uint256 amount) external onlyOwner {
        require(strategist != address(0), 'strategist not set');
        usdc.safeTransfer(strategist, amount);

        emit UsdcWithdrawn(amount);
    }

    function withdrawThorus(uint256 amount) external onlyWithdrawer {
        thorus.safeTransfer(msg.sender, amount);

        emit ThorusWithdrawn(amount);
    }
}