/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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


// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: tahu_staking.sol



pragma solidity ^0.8.0;







interface PancakeRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract TAHUStakeMachine is Ownable, Pausable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    // 0xCff0C14f03dd325163565820585a7349Ff3Cf0E1 testnet tahu
    // 0xB8EdD4261031c620431FE070B9e4B516571E9918 mainnet tahu
    IERC20 public TAHU;

    // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 testnet router
    // 0x10ED43C718714eb63d5aA57B78B54704E256024E mainnet router
    PancakeRouter public ROUTER;

    // 0x78867bbeef44f2326bf8ddd1941a4439382ef2a7 testnet busd
    // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 mainnet busd
    IERC20 public BUSD;

    // 0xae13d989dac2f0debff460ac112a837c89baa7cd testnet wbnb
    // 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c mainnet wbnb
    IERC20 public WBNB;

    struct StakeProfile {
        uint stakedTimestamp;
        uint stakedAmount;
        uint stakedBlock;
        uint aprProfile;
        uint reward;
    }

    struct LockProfile {
        uint rewardTimestamp;
    }

    struct APRProfile {
        uint multiplier;
        uint divider;
        uint duration; // in second
    }

    mapping( address => StakeProfile[] ) public stakesOf;
    // mapping( address => StakeProfile ) public stake2Of;
    mapping( address => LockProfile ) public lockOf;
    mapping( uint => APRProfile ) public APROf;

    uint public total_staked;
    uint public total_apr_package;
    uint public PENALTY_FEE;
    uint public WITHDRAWAL_USD_LIMIT; // 100 usd
    uint public WITHDRAWAL_DURATION; // 1 day 
    uint public WITHDRAWAL_PERCENTAGE; 
    
    event Staked(address indexed account, uint staked_amount, uint package);
    event Harvested(address indexed account, uint harvest_amount, uint reward, uint current_reward);
    event Unstaked(address indexed account, uint reward, uint fee, uint staked_amount, uint package);

    constructor(address _tahu, address _router, address _wbnb, address _busd) {
        TAHU = IERC20(_tahu);
        ROUTER = PancakeRouter(_router);
        WBNB = IERC20(_wbnb);
        BUSD = IERC20(_busd);

        total_apr_package = 0;
        PENALTY_FEE = 30;
        WITHDRAWAL_USD_LIMIT = 100 * 1E18; // 100 usd
        WITHDRAWAL_DURATION = 86400; // 1 day 
        WITHDRAWAL_PERCENTAGE = 20;
    }

    function update(address _fcb, address _router, address _wbnb, address _busd) external onlyOwner {
        TAHU = IERC20(_fcb);
        ROUTER = PancakeRouter(_router);
        WBNB = IERC20(_wbnb);
        BUSD = IERC20(_busd);
    }


    function calculateReward(address _account) public view returns (uint) {
        uint reward = 0;
        for(uint i=0; i<stakesOf[_account].length; i++) {
            reward = reward + stakesOf[_account][i].stakedAmount * ( block.number - stakesOf[_account][i].stakedBlock ) * APROf[stakesOf[_account][i].aprProfile].multiplier / APROf[stakesOf[_account][i].aprProfile].divider;
        }
        return reward;
    }

    function calculateRewardOf(address _account, uint _index) public view returns (uint) {
        return stakesOf[_account][_index].stakedAmount * ( block.number - stakesOf[_account][_index].stakedBlock ) * APROf[stakesOf[_account][_index].aprProfile].multiplier / APROf[stakesOf[_account][_index].aprProfile].divider;
    }

    function setPenaltyFee(uint _fee) external onlyOwner {
        PENALTY_FEE = _fee;
    }

    function getTotalStake(address _account) public view returns (uint) {
        uint amount = 0;
        for(uint i=0; i<stakesOf[_account].length; i++) {
            amount = amount + stakesOf[_account][i].stakedAmount;
        }
        return amount;
    }

    function getStakeOf(address _account, uint _index) public view returns (uint) {
        return stakesOf[_account][_index].stakedAmount;
    }

    function getTotalRewardOfStake(address _account) public view returns (uint) {
        uint rewards = 0;
        for(uint i=0; i<stakesOf[_account].length; i++) {
            rewards = rewards + stakesOf[_account][i].reward;
        }
        return rewards + this.calculateReward(_account);
    }

    function setWithdrawalUSDAmount(uint _limit) external onlyOwner {
        WITHDRAWAL_USD_LIMIT = _limit;
    }

    function setWithdrawalDuration(uint _duration) external onlyOwner {
        WITHDRAWAL_DURATION = _duration;
    }

    function setWithdrawalPercentage(uint _percentage) external onlyOwner {
        WITHDRAWAL_PERCENTAGE = _percentage;
    }

    function setPairPath(address _wbnb, address _busd) external onlyOwner {
        WBNB = IERC20(_wbnb);
        BUSD = IERC20(_busd);
    }

    function getTAHUAmountInUSD(uint _usd) external view returns (uint) {
        address[] memory path = new address[](3);
        path[0] = address(BUSD);
        path[1] = address(WBNB);
        path[2] = address(TAHU);

        uint[] memory amounts = ROUTER.getAmountsOut(_usd, path);
        return amounts[2];
    }

    function createAPR(uint _index, uint _multiplier, uint _divider, uint _duration) external onlyOwner {
        require(_index > 0, "0 is default. Use index more than 0.");
        APROf[_index].multiplier = _multiplier;
        APROf[_index].divider = _divider;
        APROf[_index].duration = _duration;
        total_apr_package = total_apr_package + 1;
    }

    function getAllAPRPackage() external view returns (APRProfile[] memory) {
        APRProfile[] memory _package = new APRProfile[](total_apr_package);
        for(uint i=0; i<total_apr_package; i++) {
            _package[i] = APROf[i];
        }
        return _package;
    }

    function stake(uint _amount, uint _package) external nonReentrant whenNotPaused {
        require(TAHU.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(TAHU.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance.");
        require(_amount > 0, "Stake amount must be greater than zero.");
        require(_package > 0 && _package <= total_apr_package, "Must pick a package.");
        bool new_stake = true;

        for(uint i=0; i<stakesOf[msg.sender].length; i++) {
            if(stakesOf[msg.sender][i].aprProfile == _package && stakesOf[msg.sender][i].stakedAmount > 0) {
                uint reward = this.calculateRewardOf(msg.sender, i);
                stakesOf[msg.sender][i].reward = stakesOf[msg.sender][i].reward + reward;


                stakesOf[msg.sender][i].stakedTimestamp = block.timestamp;
                stakesOf[msg.sender][i].stakedAmount = stakesOf[msg.sender][i].stakedAmount + _amount;
                stakesOf[msg.sender][i].stakedBlock = block.number;
                stakesOf[msg.sender][i].aprProfile = _package;

                new_stake = false;
            }
        }

        if(new_stake) {

            StakeProfile memory _stake;
            _stake.stakedTimestamp = block.timestamp;
            _stake.stakedAmount = _amount;
            _stake.stakedBlock = block.number;
            _stake.aprProfile = _package;

            stakesOf[msg.sender].push(_stake);
        }

        total_staked = total_staked + _amount;
        TAHU.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount, _package);
    }

    function unstake(uint _package) external nonReentrant {

        uint reward = 0;
        // uint total = this.getTAHUAmountInUSD(WITHDRAWAL_USD_LIMIT);
        uint total = 0;
        uint fee = 0;

        for(uint i=0; i<stakesOf[msg.sender].length; i++) {
            if(stakesOf[msg.sender][i].aprProfile == _package) {
                require(stakesOf[msg.sender][i].stakedAmount > 0, "Stake amount is zero.");
            }
        }
        
        require((lockOf[msg.sender].rewardTimestamp + WITHDRAWAL_DURATION) < block.timestamp, "Withdrawal locked.");
        require(TAHU.balanceOf(address(this)) >= this.getTAHUAmountInUSD(WITHDRAWAL_USD_LIMIT), "Insufficient balance in contract.");
        require(_package > 0 && _package <= total_apr_package, "Must pick a package.");

        

        for(uint i=0; i<stakesOf[msg.sender].length; i++) {
            if(stakesOf[msg.sender][i].aprProfile == _package) {
                require(stakesOf[msg.sender][i].stakedAmount > 0, "Stake amount is zero.");

                total = stakesOf[msg.sender][i].stakedAmount * WITHDRAWAL_PERCENTAGE / 100;

                reward = this.calculateRewardOf(msg.sender, i);

                stakesOf[msg.sender][i].reward = stakesOf[msg.sender][i].reward + reward;

                if(stakesOf[msg.sender][i].stakedAmount <= total) {
                    total = stakesOf[msg.sender][i].stakedAmount;
                }

                stakesOf[msg.sender][i].stakedAmount = stakesOf[msg.sender][i].stakedAmount - total;

                if((stakesOf[msg.sender][i].stakedTimestamp + APROf[stakesOf[msg.sender][i].aprProfile].duration) > block.timestamp) { // penalty
                    fee = total * PENALTY_FEE / 100;
                }

                lockOf[msg.sender].rewardTimestamp = block.timestamp;

                emit Unstaked(msg.sender, reward, fee, stakesOf[msg.sender][i].stakedAmount, stakesOf[msg.sender][i].aprProfile);
            }
        }

        total_staked = total_staked - total;
        
        total = total - fee;
        
        TAHU.safeTransfer(msg.sender, total);
    }

    function harvest(uint _package) external nonReentrant {

        require(_package > 0 && _package <= total_apr_package, "Must pick a package.");

        uint reward = 0;
        // uint total = this.getTAHUAmountInUSD(WITHDRAWAL_USD_LIMIT);
        uint total = 0;

        for(uint i=0; i<stakesOf[msg.sender].length; i++) {
            if(stakesOf[msg.sender][i].aprProfile == _package) {
                
                reward = calculateRewardOf(msg.sender, i);
                stakesOf[msg.sender][i].stakedBlock = block.number;
                stakesOf[msg.sender][i].reward = stakesOf[msg.sender][i].reward + reward;

                total = stakesOf[msg.sender][i].reward * WITHDRAWAL_PERCENTAGE / 100;

                if(stakesOf[msg.sender][i].reward <= total) {
                    total = stakesOf[msg.sender][i].reward;
                }

                stakesOf[msg.sender][i].reward = stakesOf[msg.sender][i].reward - total;
                emit Harvested(msg.sender, total, reward, stakesOf[msg.sender][i].reward);

            }
        }

        require(reward > 0, "No reward to harvest.");
        require(TAHU.balanceOf(address(this)) >= reward, "Insufficient balance in contract.");
        require((lockOf[msg.sender].rewardTimestamp + WITHDRAWAL_DURATION) < block.timestamp, "Withdrawal locked.");


        lockOf[msg.sender].rewardTimestamp = block.timestamp;
        TAHU.safeTransfer(msg.sender, total);
        
    }


    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    }
}