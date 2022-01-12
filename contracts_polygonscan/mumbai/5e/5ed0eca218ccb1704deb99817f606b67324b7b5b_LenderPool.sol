/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

//SPDX-License-Identifier: MIT
// File contracts/interfaces/ILenderPool.sol

pragma solidity ^0.8.11;

interface ILenderPool {
    struct Round {
        bool paidTrade;
        uint16 stableAPY;
        uint16 bonusAPY;
        uint48 startPeriod;
        uint48 endPeriod;
        uint amountLent;
    }

    struct LenderInfo {
        uint amountLent;
        uint roundCount;
    }

    /**
     * @notice changes the minimum amount required for deposit (newRound)
     * @dev update `minimumDeposit` with `newMinimumDeposit`
     * @param newMinimumDeposit, new amount for minimum deposit
     */
    function setMinimumDeposit(uint newMinimumDeposit) external;

    /**
     * @notice create new Round on behalf of the lender, each deposit has its own round
     * @dev `lender` must approve the amount to be deposited first
     * @dev only `Owner` can launch a new round
     * @dev add new round to `_lenderRounds`
     * @dev `amount` will be transferred from `lender` to `address(this)`
     * @dev emits Deposit event
     * @param lender, address of the lender
     * @param amount, amount to be deposited by the lender, must be greater than minimumDeposit
     * @param bonusAPY, bonus ratio to be applied
     * @param paidTrade, specifies whether if stable rewards will be paid in Trade(true) or in stable(false)
     */
    function newRound(
        address lender,
        uint amount,
        uint16 bonusAPY,
        bool paidTrade
    ) external;

    /**
     * @notice transfer tokens from the contract to the treasury
     * @dev only `Owner` can send to treasury
     * @param tokenAddress address of the token to be transferred
     * @param amount amount of tokens to be transferred
     */
    function sendToTreasury(address tokenAddress, uint amount) external;

    /**
     * @notice Withdraw the initial deposit of the specified lender for the specified roundId
     * @notice claim rewards of the specified roundId for the specific lender
     * @dev only `Owner` can withdraw
     * @dev round must be finish (`block.timestamp` must be higher than `round.endPeriod`)
     * @dev run `_claimRewards` and `_withdraw`
     * @param lender, address of the lender
     * @param roundId, Id of the round
     * @param amountOutMin, The minimum amount tokens to receive
     */
    function withdraw(
        address lender,
        uint roundId,
        uint amountOutMin
    ) external;

    /**
     * @notice Returns all the information of a specific round for a specific lender
     * @dev returns Round struct of the specific round for a specific lender
     * @param lender, address of the lender to be checked
     * @param roundId, Id of the round to be checked
     * @return Round ({ bool paidTrade, uint16 bonusAPY, uint amountLent, uint64 startPeriod, uint64 endPeriod })
     */
    function getRound(address lender, uint roundId)
        external
        view
        returns (Round memory);

    /**
     * @notice Returns the latest round for a specific lender
     * @param lender, address of the lender to be checked
     * @return returns the latest round for a specific Lender
     */
    function getLatestRound(address lender) external view returns (uint);

    /**
     * @notice Returns the total amount lent for the lender on every round
     * @param lender, address of the lender to be checked
     * @return returns amount lent by a lender
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
     * @dev Emitted when `minimumDeposit` is updated
     */
    event MinimumDepositUpdated(
        uint previousMinimumDeposit,
        uint newMinimumDeposit
    );

    /**
     * @dev Emitted when Treasury Address is updated
     */
    event NewTreasuryAddress(
        address oldTreasuryAddress,
        address newTreasuryAddress
    );

    /**
     * @dev Emitted when Tenure is updated
     */
    event TenureUpdated(uint16 oldTenure, uint16 newTenure);

    /**
     * @dev Emitted when `_stableAPY` is updated
     */
    event StableAPYUpdated(uint previousStableAPY, uint newStableAPY);

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

pragma solidity =0.8.11;

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

    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view
        returns (uint[] memory amounts);

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

pragma solidity ^0.8.11;





/// @author Polytrade
/// @title LenderPool V1
contract LenderPool is ILenderPool, Ownable {
    using SafeERC20 for IERC20;

    /// IERC20 Instance of the Stable coin
    IERC20 public immutable stableInstance;

    /// IUniswapV2Router instance of the router
    IUniswapV2Router public immutable router;

    /// Address of the Trade token
    address public immutable trade;

    /// Address of the Treasury
    address public treasury;

    /// uint16 StableAPY of the pool
    uint16 public stableAPY;

    /// PRECISION constant for calculation purpose
    uint private constant PRECISION = 1E6;

    /// duration of each round (expressed in number in days)
    uint16 public tenure;

    /// uint minimum Deposit amount
    uint public minimumDeposit;

    /// uint total rounds
    uint public totalRounds;

    /// uint total liquidity (Current deposited)
    uint public totalLiquidity;

    /// uint total deposited (Since Pool creation)
    uint public totalDeposited;

    /// _lenderInfo mapping of the total amountLent and counts the amount of round for each lender
    mapping(address => LenderInfo) private _lenderInfo;

    /// _lenderRounds mapping that contains all roundIds and Round info for each lender
    mapping(address => mapping(uint => Round)) private _lenderRounds;

    constructor(
        uint16 stableAPY_,
        uint16 tenure_,
        address stableAddress_,
        address clientPortal_,
        address tradeToken_
    ) {
        stableInstance = IERC20(stableAddress_);
        stableAPY = stableAPY_;
        tenure = tenure_;
        // initialize IUniswapV2Router router
        router = IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        // initialize trade token address
        trade = tradeToken_;

        stableInstance.approve(address(router), ~uint(0));
        stableInstance.approve(address(clientPortal_), ~uint(0));
    }

    /**
     * @notice changes the minimum amount required for deposit (newRound)
     * @dev update `minimumDeposit` with `newMinimumDeposit`
     * @param newMinimumDeposit, new amount for minimum deposit
     */
    function setMinimumDeposit(uint newMinimumDeposit) external onlyOwner {
        uint oldMinimumDeposit = minimumDeposit;
        minimumDeposit = newMinimumDeposit;
        emit MinimumDepositUpdated(oldMinimumDeposit, newMinimumDeposit);
    }

    /**
     * @notice changes the Stable APY
     * @dev update `_stableAPY` with `newStableAPY`
     * @param newStableAPY, new APY for the LenderPool
     */
    function setStableAPY(uint16 newStableAPY) external onlyOwner {
        uint oldStableAPY = stableAPY;
        stableAPY = newStableAPY;
        emit StableAPYUpdated(oldStableAPY, newStableAPY);
    }

    /**
     * @notice changes the tenure
     * @dev update `tenure` with `newTenure`
     * @param newTenure, new tenure for this LenderPool
     */
    function setTenure(uint16 newTenure) external onlyOwner {
        require(newTenure >= 30 && newTenure <= 365, "Invalid tenure");
        uint16 oldTenure = tenure;
        tenure = newTenure;
        emit TenureUpdated(oldTenure, newTenure);
    }

    /**
     * @dev Set TreasuryAddress linked to the contract to a new treasuryAddress
     * Can only be called by the owner
     */
    function setTreasuryAddress(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Cannot set address(0)");
        address oldTreasury = treasury;
        treasury = _newTreasury;
        emit NewTreasuryAddress(oldTreasury, _newTreasury);
    }

    /**
     * @notice create new Round on behalf of the lender, each deposit has its own round
     * @dev `lender` must approve the amount to be deposited first
     * @dev only `Owner` can launch a new round
     * @dev add new round to `_lenderRounds`
     * @dev `amount` will be transferred from `lender` to `address(this)`
     * @dev emits Deposit event
     * @param lender, address of the lender
     * @param amount, amount to be deposited by the lender, must be greater than minimumDeposit
     * @param bonusAPY, bonus ratio to be applied
     * @param paidTrade, specifies whether if stable rewards will be paid in Trade(true) or in stable(false)
     */
    function newRound(
        address lender,
        uint amount,
        uint16 bonusAPY,
        bool paidTrade
    ) external onlyOwner {
        require(amount >= minimumDeposit, "Amount lower than minimumDeposit");
        Round memory round = Round({
            stableAPY: stableAPY,
            bonusAPY: bonusAPY,
            startPeriod: uint48(block.timestamp),
            endPeriod: uint48(block.timestamp + (tenure * 1 days)),
            amountLent: amount,
            paidTrade: paidTrade
        });

        _lenderRounds[lender][_lenderInfo[lender].roundCount] = round;
        _lenderInfo[lender].roundCount++;
        _lenderInfo[lender].amountLent += amount;
        totalDeposited += amount;
        totalLiquidity += amount;
        totalRounds++;

        stableInstance.safeTransferFrom(lender, address(this), amount);
        emit Deposit(lender, _lenderInfo[lender].roundCount - 1, amount);
    }

    /**
     * @notice transfer tokens from the contract to the treasury
     * @dev only `Owner` can send to treasury
     * @param tokenAddress address of the token to be transferred
     * @param amount amount of tokens to be transferred
     */
    function sendToTreasury(address tokenAddress, uint amount)
        external
        onlyOwner
    {
        IERC20 tokenContract = IERC20(tokenAddress);

        tokenContract.safeTransfer(treasury, amount);
    }

    /**
     * @notice Returns all the information of a specific round for a specific lender
     * @dev returns Round struct of the specific round for a specific lender
     * @param lender, address of the lender to be checked
     * @param roundId, Id of the round to be checked
     * @return Round ({ bool paidTrade, uint16 bonusAPY, uint amountLent, uint64 startPeriod, uint64 endPeriod })
     */
    function getRound(address lender, uint roundId)
        external
        view
        returns (Round memory)
    {
        return _lenderRounds[lender][roundId];
    }

    /**
     * @notice Returns the latest round for a specific lender
     * @param lender, address of the lender to be checked
     * @return returns the latest round for a specific Lender
     */
    function getLatestRound(address lender) external view returns (uint) {
        return _lenderInfo[lender].roundCount - 1;
    }

    /**
     * @notice Returns the total amount lent for the lender on every round
     * @param lender, address of the lender to be checked
     * @return returns amount lent by a lender
     */
    function getAmountLent(address lender) external view returns (uint) {
        return _lenderInfo[lender].amountLent;
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
        return
            _calculateRewards(
                lender,
                roundId,
                _lenderRounds[lender][roundId].stableAPY
            );
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
     * @notice Withdraw the initial deposit of the specified lender for the specified roundId
     * @notice claim rewards of the specified roundId for the specific lender
     * @dev only `Owner` can withdraw
     * @dev round must be finish (`block.timestamp` must be higher than `round.endPeriod`)
     * @dev run `_claimRewards` and `_withdraw`
     * @param lender, address of the lender
     * @param roundId, Id of the round
     * @param amountOutMin, The minimum amount tokens to receive
     */
    function withdraw(
        address lender,
        uint roundId,
        uint amountOutMin
    ) public onlyOwner {
        Round memory round = _lenderRounds[lender][roundId];
        require(
            block.timestamp >= round.endPeriod,
            "Round is not finished yet"
        );
        uint amountLent = _lenderRounds[lender][roundId].amountLent;
        require(amountLent > 0, "No amount lent");
        _claimRewards(lender, roundId, amountOutMin);
        _withdraw(lender, roundId, amountLent);
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
     * @param amountOutMin, The minimum amount tokens to receive
     */
    function _claimRewards(
        address lender,
        uint roundId,
        uint amountOutMin
    ) private {
        Round memory round = _lenderRounds[lender][roundId];
        if (round.paidTrade) {
            _distributeRewards(
                lender,
                roundId,
                (round.stableAPY + round.bonusAPY),
                amountOutMin
            );
        } else {
            uint amountStable = _calculateRewards(
                lender,
                roundId,
                round.stableAPY
            );
            stableInstance.safeTransfer(lender, amountStable);
            emit ClaimStable(lender, roundId, amountStable);

            _distributeRewards(lender, roundId, round.bonusAPY, amountOutMin);
        }
    }

    function _distributeRewards(
        address lender,
        uint roundId,
        uint16 rewardAPY,
        uint amountOutMin
    ) private {
        uint balance = IERC20(trade).balanceOf(address(this));

        uint quotation = _getQuotation(lender, roundId, rewardAPY);

        if (balance >= quotation) {
            IERC20(trade).safeTransfer(lender, quotation);
            emit ClaimTrade(lender, roundId, quotation);
        } else {
            uint amountTrade = _swapExactTokens(
                lender,
                roundId,
                rewardAPY,
                amountOutMin
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
        _lenderInfo[lender].amountLent -= amount;
        _lenderRounds[lender][roundId].amountLent -= amount;
        totalLiquidity -= amount;
        stableInstance.safeTransfer(lender, amount);
        emit Withdraw(lender, roundId, amount);
    }

    /**
     * @notice Swap Stable for Trade using IUniswap router interface
     * @dev emits Swapped event (amountStable sent, amountTrade received)
     * @param lender, address of the lender
     * @param roundId, Id of the round
     * @param rewardAPY, rewardAPY
     * @param amountOutMin, The minimum amount tokens to receive
     * @return amount TRADE swapped
     */
    function _swapExactTokens(
        address lender,
        uint roundId,
        uint16 rewardAPY,
        uint amountOutMin
    ) private returns (uint) {
        uint amountStable = _calculateRewards(lender, roundId, rewardAPY);
        uint amountTrade = router.swapExactTokensForTokens(
            amountStable,
            amountOutMin,
            _getPath(),
            lender,
            block.timestamp
        )[2];
        emit Swapped(amountStable, amountTrade);
        return amountTrade;
    }

    /**
     * @notice Get quotation for Trade(token) using IUniswap router interface
     * @dev calls getAmountsOut to get a quotation for TRADE
     * @param lender, address of the lender
     * @param roundId, Id of the round
     * @param rewardAPY, rewardAPY
     * @return quotation of amount TRADE for stable
     */
    function _getQuotation(
        address lender,
        uint roundId,
        uint16 rewardAPY
    ) private view returns (uint) {
        uint amountStable = _calculateRewards(lender, roundId, rewardAPY);
        uint amountTrade = router.getAmountsOut(amountStable, _getPath())[2];
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
        uint length = _lenderInfo[lender].roundCount;
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