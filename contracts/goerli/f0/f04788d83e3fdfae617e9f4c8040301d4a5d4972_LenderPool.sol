/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

//SPDX-License-Identifier: MIT

// File contracts/interfaces/ILenderPool.sol

pragma solidity ^0.8.10;

interface ILenderPool {
    struct Round {
        bool paidTrade;
        uint16 bonusAPY;
        uint amountLent;
        uint startPeriod;
        uint endPeriod;
    }

    /**
     * @notice changes the minimum amount required for deposit (newRound)
     * @dev update `minimumDeposit` with `_minimumDeposit`
     * @param _minimumDeposit, new minimum deposit
     */
    function setMinimumDeposit(uint _minimumDeposit) external;

    /**
     * @notice create new Round on behalf of the lender, each deposit has its own round
     * @dev `lender` must approve the amount to be deposited first
     * @dev only `Owner` can launch a new round
     * @dev only function that can be `Paused`
     * @dev add new round to `_lenderRounds`
     * @dev `amount` will be transferred from `lender` to `address(this)`
     * @dev emits Deposit event
     * @param lender, address of the lender
     * @param amount, amount to be deposited by the lender, must be greater than minimumDeposit
     * @param bonusAPY, bonus ratio to be applied
     * @param tenure, duration of the round (expressed in number in days)
     * @param paidTrade, specifies whether if stable rewards will be paid in Trade(true) or in stable(false)
     */
    function newRound(
        address lender,
        uint amount,
        uint16 bonusAPY,
        uint8 tenure,
        bool paidTrade
    ) external;

    /**
     * @notice Withdraw the initial deposit of the specified lender for the specified roundId
     * @notice claim rewards of the specified roundId for the specific lender
     * @dev only `Owner` can withdraw
     * @dev round must be finish (`block.timestamp` must be higher than `round.endPeriod`)
     * @dev run `_claimRewards` and `_withdraw`
     * @param lender, address of the lender
     * @param roundId, Id of the round
     */
    function withdraw(address lender, uint roundId) external;

    /**
     * @notice Returns all the information of a specific round for a specific lender
     * @dev returns Round struct of the specific round for a specific lender
     * @param lender, address of the lender to be checked
     * @param roundId, Id of the round to be checked
     * @return Round ({ bool paidTrade, uint16 bonusAPY, uint amountLent, uint startPeriod, uint endPeriod })
     */
    function getRound(address lender, uint roundId)
        external
        view
        returns (Round memory);

    /**
     * @notice Returns the number of rounds for the a specific lender
     * @param lender, address of the lender to be checked
     * @return returns _roundCount[lender] (last known round)
     */
    function getNumberOfRounds(address lender) external view returns (uint);

    /**
     * @notice Returns the total amount lent for the lender on every round
     * @param lender, address of the lender to be checked
     * @return returns _amountLent[lender]
     */
    function getAmountLent(address lender) external view returns (uint);

    /**
     * @notice Returns roundIds of every finished round
     * @param lender, address of the lender to be checked
     * @return returns array with all finished round Ids
     */
    function getFinishedRounds(address lender)
        external
        view
        returns (uint[] memory);

    /**
     * @notice Returns the amount of stable rewards for a specific lender on a specific roundId
     * @dev run `_calculateRewards` with `_stableAPY` based on the amountLent
     * @param lender, address of the lender to be checked
     * @param roundId, Id of the round to be checked
     * @return returns the amount of stable rewards (based on stableInstance)
     */
    function stableRewardOf(address lender, uint roundId)
        external
        view
        returns (uint);

    /**
     * @notice Returns the amount of bonus rewards for a specific lender on a specific roundId
     * @dev run `_calculateRewards` with `_lenderRounds[lender][roundId].bonusAPY` based on the amountLent
     * @param lender, address of the lender to be checked
     * @param roundId, Id of the round to be checked
     * @return returns the amount of bonus rewards in stable (based on stableInstance)
     */
    function bonusRewardOf(address lender, uint roundId)
        external
        view
        returns (uint);

    /**
     * @dev Emitted when `amount` tokens are deposited into a pool by generating a new Round
     */
    event Deposit(address indexed owner, uint indexed roundId, uint amount);

    /**
     * @dev Emitted when lender withdraw initial `amount` lent on a specific round
     */
    event Withdraw(address indexed owner, uint indexed roundId, uint amount);

    /**
     * @dev Emitted when `lender` claim rewards in Stable coin for a specific round
     */
    event ClaimStable(
        address indexed lender,
        uint indexed roundId,
        uint amount
    );

    /**
     * @dev Emitted when `lender` claim rewards in Trade token for a specific round
     */
    event ClaimTrade(address indexed lender, uint indexed roundId, uint amount);

    /**
     * @dev Emitted when Stable coin are swapped into Trade token
     */
    event Swapped(uint amountStable, uint amountTrade);
}


// File contracts/interfaces/IUniswapV2Router.sol

pragma solidity =0.8.10;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/security/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


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


// File contracts/LenderPool.sol

pragma solidity ^0.8.10;






/// @author Polytrade
/// @title LenderPool V1
contract LenderPool is ILenderPool, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// IERC20 Instance of the Stable coin
    IERC20 public immutable stableInstance;

    /// IUniswapV2Router instance of the router
    IUniswapV2Router public immutable router;

    /// Address of the Trade token
    address public immutable trade;

    /// uint16 StableAPY of the pool
    uint16 private immutable _stableAPY;

    /// PRECISION constant for calculation purpose
    uint private constant PRECISION = 1E6;

    /// uint minimum Deposit amount
    uint public minimumDeposit;

    /// _amountLent mapping of the total amountLent for each  lender
    mapping(address => uint) private _amountLent;

    /// _roundCount mapping that counts the amount of round for each lender
    mapping(address => uint) private _roundCount;

    /// _lenderRounds mapping that contains all roundIds and Round info for each lender
    mapping(address => mapping(uint => Round)) private _lenderRounds;

    constructor(address stableAddress_, uint16 stableAPY_) {
        stableInstance = IERC20(stableAddress_);
        _stableAPY = stableAPY_;
        // initialize IUniswapV2Router router
        router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // initialize trade token address
        trade = 0x06618B8FDA9fa44a598AfEEDcc1bf94117a78788;
    }

    /**
     * @notice changes the minimum amount required for deposit (newRound)
     * @dev update `minimumDeposit` with `_minimumDeposit`
     * @param _minimumDeposit, new minimum deposit
     */
    function setMinimumDeposit(uint _minimumDeposit) external onlyOwner {
        minimumDeposit = _minimumDeposit;
    }

    /**
     * @notice create new Round on behalf of the lender, each deposit has its own round
     * @dev `lender` must approve the amount to be deposited first
     * @dev only `Owner` can launch a new round
     * @dev only function that can be `Paused`
     * @dev add new round to `_lenderRounds`
     * @dev `amount` will be transferred from `lender` to `address(this)`
     * @dev emits Deposit event
     * @param lender, address of the lender
     * @param amount, amount to be deposited by the lender, must be greater than minimumDeposit
     * @param bonusAPY, bonus ratio to be applied
     * @param tenure, duration of the round (expressed in number in days)
     * @param paidTrade, specifies whether if stable rewards will be paid in Trade(true) or in stable(false)
     */
    function newRound(
        address lender,
        uint amount,
        uint16 bonusAPY,
        uint8 tenure,
        bool paidTrade
    ) external onlyOwner whenNotPaused {
        require(amount >= minimumDeposit, "Amount lower than minimumDeposit");
        Round memory round = Round({
            bonusAPY: bonusAPY,
            startPeriod: block.timestamp,
            endPeriod: block.timestamp + (tenure * 1 days),
            amountLent: amount,
            paidTrade: paidTrade
        });
        _lenderRounds[lender][_roundCount[lender]] = round;
        _roundCount[lender]++;
        _amountLent[lender] += amount;
        stableInstance.safeTransferFrom(lender, address(this), amount);
        emit Deposit(lender, _roundCount[lender] - 1, amount);
    }

    /**
     * @notice Withdraw all amounts lent and claim rewards for all finished rounds
     * @dev `withdraw` function is called for each finished round
     * @dev only `Owner` can withdrawAllFinishedRounds
     * @param lender, address of the lender
     */
    function withdrawAllFinishedRounds(address lender) external onlyOwner {
        uint[] memory rounds = _getFinishedRounds(lender);

        for (uint i = 0; i < rounds.length; i++) {
            withdraw(lender, rounds[i]);
        }
    }

    /**
     * @notice Returns all the information of a specific round for a specific lender
     * @dev returns Round struct of the specific round for a specific lender
     * @param lender, address of the lender to be checked
     * @param roundId, Id of the round to be checked
     * @return Round ({ bool paidTrade, uint16 bonusAPY, uint amountLent, uint startPeriod, uint endPeriod })
     */
    function getRound(address lender, uint roundId)
        external
        view
        returns (Round memory)
    {
        return _lenderRounds[lender][roundId];
    }

    /**
     * @notice Returns the number of rounds for the a specific lender
     * @param lender, address of the lender to be checked
     * @return returns _roundCount[lender] (last known round)
     */
    function getNumberOfRounds(address lender) external view returns (uint) {
        return _roundCount[lender];
    }

    /**
     * @notice Returns the total amount lent for the lender on every round
     * @param lender, address of the lender to be checked
     * @return returns _amountLent[lender]
     */
    function getAmountLent(address lender) external view returns (uint) {
        return _amountLent[lender];
    }

    /**
     * @notice Returns roundIds of every finished round
     * @param lender, address of the lender to be checked
     * @return returns array with all finished round Ids
     */
    function getFinishedRounds(address lender)
        external
        view
        returns (uint[] memory)
    {
        return _getFinishedRounds(lender);
    }

    /**
     * @notice Returns the amount of stable rewards for a specific lender on a specific roundId
     * @dev run `_calculateRewards` with `_stableAPY` based on the amountLent
     * @param lender, address of the lender to be checked
     * @param roundId, Id of the round to be checked
     * @return returns the amount of stable rewards (based on stableInstance)
     */
    function stableRewardOf(address lender, uint roundId)
        external
        view
        returns (uint)
    {
        return _calculateRewards(lender, roundId, _stableAPY);
    }

    /**
     * @notice Returns the amount of bonus rewards for a specific lender on a specific roundId
     * @dev run `_calculateRewards` with `_lenderRounds[lender][roundId].bonusAPY` based on the amountLent
     * @param lender, address of the lender to be checked
     * @param roundId, Id of the round to be checked
     * @return returns the amount of bonus rewards in stable (based on stableInstance)
     */
    function bonusRewardOf(address lender, uint roundId)
        external
        view
        returns (uint)
    {
        return
            _calculateRewards(
                lender,
                roundId,
                _lenderRounds[lender][roundId].bonusAPY
            );
    }

    /**
     * @notice Returns the total amount of rewards for a specific lender on a specific roundId
     * @dev calculate rewards for stable (stableAPY) and bonus (bonusAPY)
     * @param lender, address of the lender to be checked
     * @param roundId, Id of the round to be checked
     * @return returns the total amount of rewards (stable + bonus) in stable (based on stableInstance)
     */
    function totalRewardOf(address lender, uint roundId)
        external
        view
        returns (uint)
    {
        uint stableReward = _calculateRewards(lender, roundId, _stableAPY);

        uint bonusReward = _calculateRewards(
            lender,
            roundId,
            _lenderRounds[lender][roundId].bonusAPY
        );

        return stableReward + bonusReward;
    }

    /**
     * @notice Withdraw the initial deposit of the specified lender for the specified roundId
     * @notice claim rewards of the specified roundId for the specific lender
     * @dev only `Owner` can withdraw
     * @dev round must be finish (`block.timestamp` must be higher than `round.endPeriod`)
     * @dev run `_claimRewards` and `_withdraw`
     * @param lender, address of the lender
     * @param roundId, Id of the round
     */
    function withdraw(address lender, uint roundId) public onlyOwner {
        Round memory round = _lenderRounds[lender][roundId];
        require(
            block.timestamp >= round.endPeriod,
            "Round is not finished yet"
        );
        _claimRewards(lender, roundId);
        _withdraw(lender, roundId, round.amountLent);
    }

    /**
     * @notice Claim rewards for the specified lender and the specified roundId
     * @dev only `Owner` can withdraw
     * @dev if round `paidTrade` is `true`, swap all rewards into Trade tokens
     * @dev if round `paidTrade` is `false` and swap only bonusRewards and transfer stableRewards to the lender
     * @dev emits ClaimTrade whenever Stable are swapped into Trade
     * @dev emits ClaimStable whenever Stable are sent to the lender
     * @param lender, address of the lender
     * @param roundId, Id of the round
     */
    function _claimRewards(address lender, uint roundId) private {
        Round memory round = _lenderRounds[lender][roundId];
        stableInstance.approve(address(router), ~uint(0));
        if (round.paidTrade) {
            uint amountTrade = _swapExactTokens(
                lender,
                roundId,
                (_stableAPY + round.bonusAPY)
            );
            emit ClaimTrade(lender, roundId, amountTrade);
        } else {
            uint amountStable = _calculateRewards(lender, roundId, _stableAPY);
            stableInstance.safeTransfer(lender, amountStable);
            emit ClaimStable(lender, roundId, amountStable);
            uint amountTrade = _swapExactTokens(
                lender,
                roundId,
                round.bonusAPY
            );
            emit ClaimTrade(lender, roundId, amountTrade);
        }
    }

    /**
     * @notice Withdraw the initial deposit of the specified lender for the specified roundId
     * @dev transfer the initial amount deposited to the lender
     * @dev emits Withdraw event
     * @param lender, address of the lender
     * @param roundId, Id of the round
     * @param amount, amount to withdraw
     */
    function _withdraw(
        address lender,
        uint roundId,
        uint amount
    ) private {
        _amountLent[lender] -= amount;
        _lenderRounds[lender][roundId].amountLent -= amount;
        stableInstance.safeTransfer(lender, amount);
        emit Withdraw(lender, roundId, amount);
    }

    /**
     * @notice Swap Stable for Trade using IUniswap router interface
     * @dev emits Swapped event (amountStable sent, amountTrade received)
     * @param lender, address of the lender
     * @param roundId, Id of the round
     * @param rewardAPY, rewardAPY
     * @return amount TRADE swapped
     */
    function _swapExactTokens(
        address lender,
        uint roundId,
        uint16 rewardAPY
    ) private returns (uint) {
        uint amountStable = _calculateRewards(lender, roundId, rewardAPY);
        uint amountTrade = router.swapExactTokensForTokens(
            amountStable,
            0,
            _getPath(),
            lender,
            block.timestamp
        )[2];
        emit Swapped(amountStable, amountTrade);
        return amountTrade;
    }

    /**
     * @notice Calculate the amount of rewards
     * @dev ((rewardAPY * amountLent * timePassed) / 365)
     * @param lender, address of the lender
     * @param roundId, Id of the round
     * @param rewardAPY, rewardAPY
     * @return amount rewards
     */
    function _calculateRewards(
        address lender,
        uint roundId,
        uint16 rewardAPY
    ) private view returns (uint) {
        Round memory round = _lenderRounds[lender][roundId];

        uint timePassed = (block.timestamp >= round.endPeriod)
            ? round.endPeriod - round.startPeriod
            : block.timestamp - round.startPeriod;

        uint result = ((rewardAPY * round.amountLent * timePassed) / 365 days);
        return ((result * PRECISION) / 1E10);
    }

    /**
     * @notice Returns roundIds of every finished round
     * @param lender, address of the lender to be checked
     * @return returns array with all finished round Ids for the specified lender
     */
    function _getFinishedRounds(address lender)
        private
        view
        returns (uint[] memory)
    {
        uint length = _roundCount[lender];
        uint j = 0;
        for (uint i = 0; i < length; i++) {
            if (
                block.timestamp >= _lenderRounds[lender][i].endPeriod &&
                _lenderRounds[lender][i].amountLent > 0
            ) {
                j++;
            }
        }
        uint[] memory result = new uint[](j);
        j = 0;
        for (uint i = 0; i < length; i++) {
            if (
                block.timestamp >= _lenderRounds[lender][i].endPeriod &&
                _lenderRounds[lender][i].amountLent > 0
            ) {
                result[j] = i;
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Returns Path (used by IUniswap router)
     * @return returns array of path (Stable, WETH, Trade)
     */
    function _getPath() private view returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = address(stableInstance);
        path[1] = router.WETH();
        path[2] = trade;

        return path;
    }
}