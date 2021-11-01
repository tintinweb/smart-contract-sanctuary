/**
 *Submitted for verification at polygonscan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT

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

// File: newo.sol



pragma solidity 0.8.0;


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

interface IXVMCgovernor {
    function costToVote() external returns (uint256);
    function maximumVoteTokens() external returns (uint256);
    function delayBeforeEnforce() external returns (uint256);
    function thresholdFibonaccening() external returns (uint256);
    function eventFibonacceningActive() external returns (bool);
    function setThresholdFibonaccening(uint256 newThreshold) external;
    function fibonacciDelayed() external returns (bool);
    function setInflation(uint256 newInflation) external;
    function delayFibonacci(bool _arg) external;
    function totalFibonacciEventsAfterGrand() external returns (uint256);
    function rewardPerBlockPriorFibonaccening() external returns (uint256);
    function blocks100PerSecond() external returns (uint256);
    function changeGovernorEnforced() external returns (bool);
    function eligibleNewGovernor() external returns (address);
}

interface IMasterChef {
    function XVMCPerBlock() external returns (uint256);
}

contract XVMCfibonaccening is Ownable {
    using SafeERC20 for IERC20;
    
    struct ProposalMinThresholdFibonaccening {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 proposedValue;
    }
    struct FibonacceningProposal {
        bool valid;
        uint256 firstCallTimestamp;
        uint256 valueSacrificedForVote;
        uint256 rewardPerBlock;
        uint256 duration;
        uint256 startTime;
    }
    struct ProposeGrandFibonaccening{
        bool valid;
        uint256 eventDate; 
        uint256 proposalTimestamp;
        uint256 amountSacrificedForVote;
        uint256 finalSupply;
    }
    
    FibonacceningProposal[] public fibonacceningProposals;
    ProposalMinThresholdFibonaccening[] public proposalMinThresholdFibonacceningList; 
    ProposeGrandFibonaccening[] public grandFibonacceningProposals;

    //WARNING: careful where we are using 1e18 and where not
    uint256 public immutable goldenRatio = 1618; //1.618 is the golden ratio
    address public immutable token = 0x6d0c966c8A09e354Df9C48b446A474CE3343D912; //XVMC token
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    //masterchef address
    address public immutable masterchef = 0x9BD741F077241b594EBdD745945B577d59C8768e;
    
    //addresses for time-locked deposits(autocompounding pools)
    address public immutable acPool1 = 0x9b6ae196A358Ea81c305D8A32018a4F4C90FC207;
    address public immutable acPool2 = 0x38d2503d751F35c2671cdae6E9011e7Be5CdF174;
    address public immutable acPool3 = 0x418E16d46c66435E72aC646A7bC2a0c286349C55;
    address public immutable acPool4 = 0x321521b99Dbb21705259eA3d84a1d83c37C98D0A;
    address public immutable acPool5 = 0x984981089d06A514AB54Bc3562850aFc75620e26;
    address public immutable acPool6 = 0xfD08FA4a344D147DCcE4f29D258B9F4ae18e6ee0;
    
    uint256 lastCallFibonaccening; //stores timestamp of last grand fibonaccening event
    
    bool eligibleGrandFibonaccening; // when big event is ready
    bool grandFibonacceningActivated; // if upgrading the contract after event, watch out this must be true
    uint256 desiredSupplyAfterGrandFibonaccening; // Desired supply to reach for Grand Fib Event
    
    uint256 targetBlock; // used for calculating target block
    bool isRunningGrand; //we use this during Grand Fib Event

    uint256 fibonacceningActiveID;
    uint256 fibonacceningActivatedBlock;
    
    bool expiredGrandFibonaccening;

    event ProposeSetMinThresholdFibonaccening(uint256 proposalID, uint256 valueSacrificedForVote, uint256 proposedMinDeposit, address indexed enforcer);
    event VetoSetMinThresholdFibonaccening(uint256 proposalID, address indexed enforcer);
    event ExecuteSetMinThresholdFibonaccening(uint256 proposalID, address indexed enforcer);
    
    event ProposeFibonaccening(uint256 proposalID, uint256 valueSacrificedForVote, uint256 startTime, uint256 durationInBlocks, uint256 newRewardPerBlock , address indexed enforcer);
    event VetoFibonaccening(uint256 proposalID, address indexed enforcer);
    event LeverPullFibonaccening(uint256 proposalID, address indexed enforcer);

    event EndFibonaccening(uint256 proposalID, address indexed enforcer);
    event CancleFibonaccening(uint256 proposalID, address indexed enforcer);
    
    event RebalanceInflation(uint256 newRewardPerBlock);
    
    event InitiateProposeGrandFibonaccening(uint256 proposalID, uint256 depositingTokens, uint256 eventDate, uint256 finalSupply, address indexed enforcer);
    event VetoProposeGrandFibonaccening(uint256 proposalID, address indexed enforcer);
    event GrandFibonacceningEnforce(uint256 proposalID, address indexed enforcer);
    
    event ChangeGovernor(address newGovernor);

    
    modifier whenReady() {
      require(block.timestamp > 1637147532, "after 17 Nov");
      _;
    }
    
    /**
     * Regulatory process for determining fibonaccening threshold,
     * which is the minimum amount of tokens required to be collected,
     * before a "fibonaccening" event can be scheduled;
     * 
     * Bitcoin has "halvening" events every 4 years where block rewards reduce in half
     * XVMC has "fibonaccening" events, which can can be scheduled once
     * this smart contract collects the minimum(threshold) of tokens. 
     * 
     * Tokens are collected as penalties from premature withdrawals, as well as voting costs inside this contract
     *
     * It's basically a mechanism to re-distribute the penalties(though the rewards can exceed the collected penalties)
     * 
     * It's meant to serve as a volatility-inducing event that attracts new users with high rewards
     * 
     * Effectively, the rewards are increased for a short period of time. 
     * Once the event expires, the tokens collected from penalties are
     * burned to give a sense of deflation AND the global inflation
     * for XVMC is reduced by a Golden ratio
    */
    function proposeSetMinThresholdFibonaccening(uint256 depositingTokens, uint256 newMinimum) external whenReady {
        require(newMinimum >= getTotalSupply() / 1000, "Min 0.1% of supply");
        require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "Costs to vote");
        require(depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens(), "preventing tyranny, maximum 0.05% of tokens");
        
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	proposalMinThresholdFibonacceningList.push(
    	    ProposalMinThresholdFibonaccening(true, block.timestamp, newMinimum)
    	    );
		
    	emit ProposeSetMinThresholdFibonaccening(
    	    proposalMinThresholdFibonacceningList.length - 1, depositingTokens, newMinimum, msg.sender
    	   );
    }
    function vetoSetMinThresholdFibonaccening(uint256 proposalID) external whenReady {
    	require(proposalMinThresholdFibonacceningList[proposalID].valid == true, "Invalid proposal"); 
    	
		IERC20(token).safeTransferFrom(msg.sender, owner(), proposalMinThresholdFibonacceningList[proposalID].proposedValue); 
    	proposalMinThresholdFibonacceningList[proposalID].valid = false;
    	
    	emit VetoSetMinThresholdFibonaccening(proposalID, msg.sender);
    }
    function executeSetMinThresholdFibonaccening(uint256 proposalID) external whenReady {
    	require(
    	    proposalMinThresholdFibonacceningList[proposalID].valid == true &&
    	    proposalMinThresholdFibonacceningList[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
    	    "conditions not met"
        );
    	
    	IXVMCgovernor(owner()).setThresholdFibonaccening(proposalMinThresholdFibonacceningList[proposalID].proposedValue);
    	proposalMinThresholdFibonacceningList[proposalID].valid = false; 
		
    	emit ExecuteSetMinThresholdFibonaccening(proposalID, msg.sender);
    }
    
    
    /**
     * Regulatory process for scheduling a "fibonaccening event"
    */    
    function proposeFibonaccening(uint256 depositingTokens, uint256 newRewardPerBlock, uint256 durationInBlocks, uint256 startTimestamp) external whenReady {
        require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "costs to submit decisions");
        require(IERC20(token).balanceOf(owner()) >= IXVMCgovernor(owner()).thresholdFibonaccening(), "need to collect penalties before calling");
        require(!(IXVMCgovernor(owner()).eventFibonacceningActive()), "Event already running");
        require(depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens(), "preventing tyranny");
        require(
            startTimestamp > block.timestamp + IXVMCgovernor(owner()).delayBeforeEnforce() && 
            startTimestamp - block.timestamp <= 31 days, "Not within min/max delay boundaries"); 
        require(
            (newRewardPerBlock * durationInBlocks) < (getTotalSupply() / 23),
            "Safeguard: Can't print more than 23% of tokens in single event"
        );
    
		IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens); 
        fibonacceningProposals.push(
            FibonacceningProposal (true, block.timestamp, depositingTokens, newRewardPerBlock, durationInBlocks, startTimestamp)
            );
    	
    	emit ProposeFibonaccening(fibonacceningProposals.length - 1, depositingTokens, startTimestamp, durationInBlocks, newRewardPerBlock, msg.sender);
    }
    function vetoFibonaccening(uint256 proposalID) external whenReady {
    	require(fibonacceningProposals[proposalID].valid == true, "Invalid proposal"); 
    	
		IERC20(token).safeTransferFrom(msg.sender, owner(), fibonacceningProposals[proposalID].valueSacrificedForVote); 
    	fibonacceningProposals[proposalID].valid = false; 
    	
    	emit VetoFibonaccening(proposalID, msg.sender);
    }

    /**
     * Activates a valid fibonaccening event
     * 
    */
    function leverPullFibonaccening(uint256 proposalID) external whenReady {
		require(!(IXVMCgovernor(owner()).fibonacciDelayed()), "event has been delayed");
        require(
            IERC20(token).balanceOf(owner()) >= IXVMCgovernor(owner()).thresholdFibonaccening(),
            "needa collect penalties");
    	require(fibonacceningProposals[proposalID].valid == true, "invalid proposal");
    	require(block.timestamp >= fibonacceningProposals[proposalID].startTime, "can only start when set");
    	require(!(IXVMCgovernor(owner()).eventFibonacceningActive()), "already active");
    	
        IERC20(token).safeTransferFrom(msg.sender, owner(), IXVMCgovernor(owner()).costToVote()); 
        
        IXVMCgovernor(owner()).setInflation(fibonacceningProposals[proposalID].rewardPerBlock);
    
        fibonacceningProposals[proposalID].valid = false;
        fibonacceningActiveID = proposalID;
        fibonacceningActivatedBlock = block.number;
    	IXVMCgovernor(owner()).delayFibonacci(true);
    	
    	emit LeverPullFibonaccening(proposalID, msg.sender);
    }
    
     /**
     * Ends fibonaccening event 
     * sets new inflation  
     * burns the tokens
    */
    function endFibonaccening() external whenReady {
        require(IXVMCgovernor(owner()).eventFibonacceningActive(), "no active event");
        require(
            block.number >= fibonacceningActivatedBlock + fibonacceningProposals[fibonacceningActiveID].duration, 
            "not yet expired"
           ); 
        
        uint256 newAmount = calculateFibonacceningNewRewardPerBlock();
        
        IXVMCgovernor(owner()).setInflation(newAmount);
        IXVMCgovernor(owner()).delayFibonacci(false);
        
    	IERC20(token).safeTransferFrom(owner(), deadAddress, IXVMCgovernor(owner()).thresholdFibonaccening()); // burns the tokens - "fibonaccening" sacrifice
		
    	emit EndFibonaccening(fibonacceningActiveID, msg.sender);
    }
    

    /**
     * In case we have multiple valid fibonaccening proposals
     * When the event is enforced, all other valid proposals can be invalidated
     * Just to clear up the space
    */
    function cancleFibonaccening(uint256 proposalID) external whenReady {
        require(IXVMCgovernor(owner()).eventFibonacceningActive(), "fibonaccening active required");

        require(fibonacceningProposals[proposalID].valid, "must be valid to negate ofc");
        
        fibonacceningProposals[proposalID].valid = false;
        emit CancleFibonaccening(proposalID, msg.sender);
    }
    
    /**
     * After the Grand Fibonaccening event, the inflation reduces to roughly 1.618% annually
     * On each new Fibonaccening event, it further reduces by Golden ratio(in percentile)
     * New inflation = Current inflation * ((100 - 1.618) / 100)
     */
    function rebalanceInflation() external whenReady {
        require(IXVMCgovernor(owner()).totalFibonacciEventsAfterGrand() > 0, "Only after the Grand Fibonaccening event");
        require(!(IXVMCgovernor(owner()).eventFibonacceningActive()), "Event is running");
        
        uint256 supplyToPrint = (getTotalSupply() * goldenRatio / 100000);
        for(uint256 i = 0; i < IXVMCgovernor(owner()).totalFibonacciEventsAfterGrand(); i++) {
            supplyToPrint = supplyToPrint * 98382 / 1000000;
        }
        
        uint256 rewardPerBlock = supplyToPrint / (365 * 24 * 360000 / IXVMCgovernor(owner()).blocks100PerSecond());
        IXVMCgovernor(owner()).setInflation(rewardPerBlock);
       
        emit RebalanceInflation(rewardPerBlock);
    }
    
       /**
     * If inflation is to drop below golden ratio, the grand fibonaccening event is ready
     */
    function isGrandFibonacceningReady() external whenReady {
		require(!eligibleGrandFibonaccening);
        if((IMasterChef(masterchef).XVMCPerBlock() - goldenRatio * 1e15) <= goldenRatio * 1e15) {
            eligibleGrandFibonaccening = true;
        }
    }

    /**
     * The Grand Fibonaccening Event, only happens once
	 * A lot of Supply is printed (x100 - x1,000,000)
	 * People like to buy on the way down
	 * People like high APYs
	 * People like to buy cheap coins
	 * Gotta catch 'em all!
     */    
    function initiateProposeGrandFibonaccening(uint256 depositingTokens, uint256 eventDate, uint256 finalSupply) external whenReady {
    	require(eligibleGrandFibonaccening && !grandFibonacceningActivated);
    	require(depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens(), "preventing tyranny, maximum 0.05% of tokens");
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "there is a minimum cost to vote");
    	require(finalSupply >= (100000000000 * 1e18) && finalSupply <= (1000000000000000 * 1e18));
    	require(eventDate > block.timestamp + IXVMCgovernor(owner()).delayBeforeEnforce());
    	
    	
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	grandFibonacceningProposals.push(
    	    ProposeGrandFibonaccening(true, eventDate, block.timestamp, depositingTokens, finalSupply)
    	    );
    	    
        emit GrandFibonacceningEnforce(grandFibonacceningProposals.length - 1, msg.sender);
    }
	
	/*
	* can be vetto'd during delayBeforeEnforce period.
	* afterwards it can not be cancled anymore
	* but it can still be front-ran by earlier event
	*/
    function vetoProposeGrandFibonaccening(uint256 proposalID) external whenReady {
    	require(!grandFibonacceningProposals[proposalID].valid, "already invalid");
    	require(
    	    grandFibonacceningProposals[proposalID].proposalTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
    	    "Past the point of no return" 
    	    );
    	
    	IERC20(token).safeTransferFrom(msg.sender, owner(), grandFibonacceningProposals[proposalID].amountSacrificedForVote); 
    	grandFibonacceningProposals[proposalID].valid = false;  
    	
    	emit VetoProposeGrandFibonaccening(proposalID, msg.sender);
    }
    
    /**
     * Grace period for potential improvements lasts until 31th of October
     * Afterwards the contract becomes 100% decentralized and immutable
     */
    function grandFibonacceningEnforce(uint256 proposalID) external whenReady {
        require(!grandFibonacceningActivated, "already called");
        require(grandFibonacceningProposals[proposalID].valid && grandFibonacceningProposals[proposalID].eventDate <= block.timestamp, "not yet valid");
    
        grandFibonacceningActivated = true;
        grandFibonacceningProposals[proposalID].valid = false;
        desiredSupplyAfterGrandFibonaccening = grandFibonacceningProposals[proposalID].finalSupply;
        
        emit GrandFibonacceningEnforce(proposalID, msg.sender);
    }
    
    /**
     * Function handling The Grand Fibonaccening
	 *
     */
    function grandFibonacceningRunning() external whenReady {
        require(grandFibonacceningActivated && !expiredGrandFibonaccening);
        
        if(isRunningGrand){
            require(block.number >= targetBlock, "target block not yet reached");
            IXVMCgovernor(owner()).setInflation(0);
            isRunningGrand = false;
			IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote() * 10);
        } else {
			require(!(IXVMCgovernor(owner()).fibonacciDelayed()), "event has been delayed");
            require(
                (getTotalSupply() * goldenRatio * goldenRatio / 1000000) < desiredSupplyAfterGrandFibonaccening, 
                "Last 2 events happen at once"
                );
			// Just a simple implementation that allows max twice per day(during these hours)
            require(
                ((block.timestamp / 60 / 60) % 24 >= 8) && (block.timestamp / 60 / 60) % 24 <= 10 || 
                (block.timestamp / 60 / 60) % 24 >= 16 && (block.timestamp / 60 / 60) % 24 <= 18,
                "can only call after 8 UTC and 16 UTC"
            );
			require(block.timestamp - lastCallFibonaccening > 10000);
			
			IERC20(token).safeTransferFrom(msg.sender, owner(), IXVMCgovernor(owner()).costToVote());
			
			lastCallFibonaccening = block.timestamp;
            uint256 targetedSupply = getTotalSupply() * goldenRatio / 1000;
			uint256 amountToPrint = targetedSupply - getTotalSupply();
            
            uint256 rewardPerBlock = amountToPrint / (360000 / IXVMCgovernor(owner()).blocks100PerSecond()); //print in roughly 1hour
			targetBlock = block.number + (amountToPrint / rewardPerBlock);
            IXVMCgovernor(owner()).setInflation(rewardPerBlock);
			
            isRunningGrand = true;
        }
    
    }
    
    /**
     * During the last print of the Grand Fibonaccening
     * It prints up to "double the dose" in order to reach the desired supply
     * Why? to create a big dump in the price, moving away from everyone's 
     * buy point. It creates a big gap with no overhead resistance, aloowing
     * the price to move back up effortlessly
     */
    function startLastPrintGrandFibonaccening() external whenReady {
        require(!(IXVMCgovernor(owner()).fibonacciDelayed()), "event has been delayed");
        require(grandFibonacceningActivated && !expiredGrandFibonaccening && !isRunningGrand);
        require(
            getTotalSupply() * goldenRatio * goldenRatio / 1000000 >= desiredSupplyAfterGrandFibonaccening,
            "on the last 2 we do it in one, call lastprint"
            );
        
        require((block.timestamp / 60 / 60) % 24 >= 16, "only after 17:00 UTC");
        
        IERC20(token).safeTransferFrom(msg.sender, owner(), IXVMCgovernor(owner()).costToVote());
        
        uint256 rewardPerBlock = ( desiredSupplyAfterGrandFibonaccening - getTotalSupply() ) / (360000 / IXVMCgovernor(owner()).blocks100PerSecond()); //print in roughly 1hour
		targetBlock = (desiredSupplyAfterGrandFibonaccening - getTotalSupply()) / rewardPerBlock;
        IXVMCgovernor(owner()).setInflation(rewardPerBlock);
                
        isRunningGrand = true;
        expiredGrandFibonaccening = true;
    }
    function expireLastPrintGrandFibonaccening() external whenReady {
        require(isRunningGrand && expiredGrandFibonaccening);
        require(block.number >= (targetBlock-7));
        
		uint256 tokensToPrint = (getTotalSupply() * (goldenRatio / 1000)) - getTotalSupply();
		
		//gosh, someone needs to do the math, this is probably wrong
        uint256 newEmissions =  tokensToPrint / (365 * 24 * 360000 / IXVMCgovernor(owner()).blocks100PerSecond()); 
		
        IXVMCgovernor(owner()).setInflation(newEmissions);
        isRunningGrand = false;
		IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote() * 10);
    }
    
    //transfers ownership of this contract to new governor(if eligible)
    function changeGovernor() external {
        require(IXVMCgovernor(owner()).changeGovernorEnforced());
        address newGov = IXVMCgovernor(owner()).eligibleNewGovernor();
        transferOwnership(newGov);
        
        emit ChangeGovernor(newGov); //Leave a trail of Governors
    }
    
    function getTotalSupply() private view returns (uint256) {
        return IERC20(token).totalSupply() - IERC20(token).balanceOf(owner()) - IERC20(token).balanceOf(deadAddress);
    }

    
    /**
     * After the Fibonaccening event ends, global inflation reduces
     * by -1.618 tokens/block prior to the Grand Fibonaccening and
     * by 1.618 percentile after the Grand Fibonaccening ( * ((100-1.618) / 100))
    */
    function calculateFibonacceningNewRewardPerBlock() private returns(uint256) {
        if(!expiredGrandFibonaccening) {
            return IXVMCgovernor(owner()).rewardPerBlockPriorFibonaccening() - goldenRatio * 1e15;
        } else {
            return IXVMCgovernor(owner()).rewardPerBlockPriorFibonaccening() * 98382 / 100000; 
        }
    }
}