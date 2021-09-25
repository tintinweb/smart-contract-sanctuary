/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
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
}

interface IROY is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

interface IPancakeSwapRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract ROYMaster is Ownable, Withdrawable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    
    IROY public immutable roy;
    IERC20 public busd;
    IERC20[] public stableTokens;
    
    IERC20 public royx; // ROYX
    IPancakeSwapRouter public immutable wswapRouter; // PancakeRouter
    address public treasury; // feeCollector
    address public strategist;
    
    address[] public swapPath;
    address[] public swapPathReverse;
    
    uint public royxPermille = 0; // no ROYX collateral
    uint public treasuryPermille = 25; // 0.25% mint fee 
    uint public feePermille = 25; // 0.25% redeem fee
    
    uint256 public maxStakeAmount; // 3000 ETH
    uint256 public maxRedeemAmount; // 1000 ETH
    uint256 public maxStakePerBlock; // 3200 ETH 
    uint256 internal lastBlock;
    uint256 internal lastBlockbusdStaked;
    
    address public dead = 0x000000000000000000000000000000000000dEaD;
    
    mapping(address => uint256) public wusdClaimAmount;
    mapping(address => uint256) public wusdClaimBlock;
    mapping(address => uint256) public busdClaimAmount;
    mapping(address => uint256) public busdClaimBlock;
    
    event Stake(address indexed user, uint256 amount);
    event ROYClaim(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event BUSDClaim(address indexed user, uint256 amount);
    event BUSDWithdrawn(uint256 amount);
    event ROYXWithdrawn(uint256 amount);
    event SwapPathChanged(address[] swapPath);
    event ROYXPermilleChanged(uint256 royxPermille);
    event TreasuryPermilleChanged(uint256 treasuryPermille);
    event FeePermilleChanged(uint256 feePermille);
    event TreasuryAddressChanged(address treasury);
    event StrategistAddressChanged(address strategist);
    event MaxStakeAmountChanged(uint256 maxStakeAmount);
    event MaxRedeemAmountChanged(uint256 maxRedeemAmount);
    event MaxStakePerBlockChanged(uint256 maxStakePerBlock);
    
    // Testnet address 
    // ROY : 0xF44C577dD65eD644a700B5799569D5d3001d1FaF
    // BUSD : 0x322E4612792dcDD60A50f9802C823e7B51eF1e31
   
    // ROYX : 0xe70a11ce106de24664d52e9eb8e98db097e7d21c
    // treasury : 0x5ED1C1307D55CA4147433a915c16416392CAc1E9
    
    // PancakeRouter : 0xd99d1c33f9fc3444f8101754abc46c52416550d1
    
    constructor(IROY _roy, IERC20 _busd, IERC20 _royx, address _treasury, IPancakeSwapRouter _pancakewapRouter, uint256 _maxStakeAmount, uint256 _maxRedeemAmount, uint256 _maxStakePerBlock) {
        require(
            address(_roy) != address(0) &&
            address(_busd) != address(0) &&
            address(_royx) != address(0) &&
            address(_pancakewapRouter) != address(0) &&
            _treasury != address(0),
            "zero address in constructor"
        );
        roy = _roy;
        busd = _busd;
        stableTokens.push(_busd);
        royx = _royx;
        wswapRouter = _pancakewapRouter;
        treasury = _treasury;
        swapPath = [address(busd), address(royx)];
        swapPathReverse = [address(royx), address(busd)];
        maxStakeAmount = _maxStakeAmount;
        maxRedeemAmount = _maxRedeemAmount;
        maxStakePerBlock = _maxStakePerBlock;
    }
    
    function setStableCoin(IERC20 _newStableToken) public onlyOwner {
        require(address(_newStableToken) != address(0));
        busd = _newStableToken;
        stableTokens.push(_newStableToken);
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function setSwapPath(address[] calldata _swapPath) external onlyOwner {
        require(_swapPath.length > 1 && _swapPath[0] == address(busd) && _swapPath[_swapPath.length - 1] == address(royx), "invalid swap path");
        swapPath = _swapPath;
        
        emit SwapPathChanged(swapPath);
    }
    
    function setROYXPermille(uint _royxPermille) external onlyOwner {
        require(_royxPermille <= 10000, 'royxPermille too high!');
        royxPermille = _royxPermille;
        
        emit ROYXPermilleChanged(royxPermille);
    }
    
    function setTreasuryPermille(uint _treasuryPermille) external onlyOwner {
        require(_treasuryPermille <= 50, 'treasuryPermille too high!');
        treasuryPermille = _treasuryPermille;
        
        emit TreasuryPermilleChanged(treasuryPermille);
    }
    
    function setFeePermille(uint _feePermille) external onlyOwner {
        require(_feePermille <= 20, 'feePermille too high!');
        feePermille = _feePermille;
        
        emit FeePermilleChanged(feePermille);
    }
    
    function setTreasuryAddress(address _treasury) external onlyOwner {
        treasury = _treasury;
        
        emit TreasuryAddressChanged(treasury);
    }
    
    function setStrategistAddress(address _strategist) external onlyOwner {
        strategist = _strategist;
        
        emit StrategistAddressChanged(strategist);
    }
    
    function setMaxStakeAmount(uint256 _maxStakeAmount) external onlyOwner {
        maxStakeAmount = _maxStakeAmount;
        
        emit MaxStakeAmountChanged(maxStakeAmount);
    }
    
    function setMaxRedeemAmount(uint256 _maxRedeemAmount) external onlyOwner {
        maxRedeemAmount = _maxRedeemAmount;
        
        emit MaxRedeemAmountChanged(maxRedeemAmount);
    }
    
    function setMaxStakePerBlock(uint256 _maxStakePerBlock) external onlyOwner {
        maxStakePerBlock = _maxStakePerBlock;
        
        emit MaxStakePerBlockChanged(maxStakePerBlock);
    }
    
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, 'amount cant be zero');
        require(wusdClaimAmount[msg.sender] == 0, 'you have to claim first');
        require(amount <= maxStakeAmount, 'amount too high');
        if(lastBlock != block.number) {
            lastBlockbusdStaked = 0;
            lastBlock = block.number;
        }
        lastBlockbusdStaked += amount;
        require(lastBlockbusdStaked <= maxStakePerBlock, 'maximum stake per block exceeded');
        
        busd.safeTransferFrom(msg.sender, address(this), amount);
        if(feePermille > 0) {
            uint256 feeAmount = amount * feePermille / 10000;
            busd.safeTransfer(treasury, feeAmount);
            amount = amount - feeAmount;
        }
        roy.mint(address(this), amount);
        
        if(royxPermille > 0) {
            uint256 amountOutMin = 0;
            uint256 royxAmount = amount * royxPermille / 1000;
            
            uint[] memory amountsOutMin = wswapRouter.getAmountsOut(
                royxAmount,
                swapPath // [address(busd), address(royx)];
            );
            amountOutMin = amountsOutMin[1];
            
            busd.approve(address(wswapRouter), royxAmount);
            wswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                royxAmount,
                amountOutMin,
                swapPath,
                address(this),
                block.timestamp
            );
        }
        
        wusdClaimAmount[msg.sender] = amount;
        wusdClaimBlock[msg.sender] = block.number;
        
        claimROY();
        
        emit Stake(msg.sender, amount);
    }
    
    function claimROY() internal whenNotPaused {
        require(wusdClaimAmount[msg.sender] > 0, 'there is nothing to claim');
        // require(wusdClaimBlock[msg.sender] < block.number, 'you cant claim yet');
        
        uint256 amount = wusdClaimAmount[msg.sender];
        wusdClaimAmount[msg.sender] = 0;
        roy.transfer(msg.sender, amount);
        
        emit ROYClaim(msg.sender, amount);
    }
    
    function redeem(uint256 amount) internal whenNotPaused {
        require(amount > 0, 'amount cant be zero');
        require(busdClaimAmount[msg.sender] == 0, 'you have to claim first');
        require(amount <= maxRedeemAmount, 'amount too high');
        
        roy.transferFrom(msg.sender, dead, amount);
        busdClaimAmount[msg.sender] = amount;
        busdClaimBlock[msg.sender] = block.number;
        
        emit Redeem(msg.sender, amount);
    }
    
    function claimBUSD(uint256 amount) external nonReentrant whenNotPaused {
        
        redeem(amount);
        
        require(busdClaimAmount[msg.sender] > 0, 'there is nothing to claim');
        // require(busdClaimBlock[msg.sender] < block.number, 'you cant claim yet');
        
        // uint256 amount = busdClaimAmount[msg.sender];
        busdClaimAmount[msg.sender] = 0;
        
        uint256 busdTransferAmount = amount * (10000 - royxPermille - treasuryPermille) / 10000; // 1000 * (1000 - 0 - 250) / 10000
        uint256 busdTreasuryAmount = amount * treasuryPermille / 10000;
        uint256 royxTransferAmount = royx.balanceOf(address(this)) * amount / roy.totalSupply();
        roy.burn(dead, amount);
        busd.safeTransfer(treasury, busdTreasuryAmount);
        busd.safeTransfer(msg.sender, busdTransferAmount);
        
        if(royxPermille > 0) {
            uint256 amountOutMin = 0;
            
            uint[] memory amountsOutMin = wswapRouter.getAmountsOut(
                royxTransferAmount, // [address(royx), address(busd)];
                swapPathReverse // [address(royx), address(busd)];
            );
            amountOutMin = amountsOutMin[1];
            
            royx.approve(address(wswapRouter), royxTransferAmount);
            wswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                royxTransferAmount,
                amountOutMin,
                swapPathReverse,
                msg.sender,
                block.timestamp
            );
        }

        emit BUSDClaim(msg.sender, amount);
    }
    
    function emergencyRedeemAll() external nonReentrant whenPaused {
        uint256 amount = roy.balanceOf(msg.sender);
        require(amount > 0, 'amount cant be zero');
        require(busdClaimAmount[msg.sender] == 0, 'you have to claim first');
        roy.transferFrom(msg.sender, dead, amount);
        busdClaimAmount[msg.sender] = amount;
        busdClaimBlock[msg.sender] = block.number;
        
        emit Redeem(msg.sender, amount);
    }
    
    function emergencyClaimBUSDAll() external nonReentrant whenPaused {
        require(busdClaimAmount[msg.sender] > 0, 'there is nothing to claim');
        require(busdClaimBlock[msg.sender] < block.number, 'you cant claim yet');
        
        uint256 amount = busdClaimAmount[msg.sender];
        busdClaimAmount[msg.sender] = 0;
        
        uint256 busdTransferAmount = amount * (10000 - royxPermille - treasuryPermille) / 10000;
        roy.burn(dead, amount);
        busd.safeTransfer(msg.sender, busdTransferAmount);
        
        emit BUSDClaim(msg.sender, amount);
    }
    
    function withdrawBUSD(uint256 amount) external onlyOwner {
        require(strategist != address(0), 'strategist not set');
        busd.safeTransfer(strategist, amount);
        
        emit BUSDWithdrawn(amount);
    }
    
    function withdrawROYX(uint256 amount) external onlyWithdrawer {
        royx.safeTransfer(msg.sender, amount);
        
        emit ROYXWithdrawn(amount);
    }
}