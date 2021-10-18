/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

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
    function changeGovernorEnforced() external returns (bool);
    function eligibleNewGovernor() external returns (address);
    function fibonacciDelayed() external returns (bool);
    function setInflation(uint256 newInflation) external;
    function blocks100PerSecond() external returns (uint256);
}

interface IMasterChef {
    function totalAllocPoint() external returns (uint256);
}

//contract that regulates the farms for XVMC
contract XVMCrapidAdoptionBoost is Ownable {
    using SafeERC20 for IERC20;
    
    uint256 public immutable goldenRatio = 1618; //1.618 is the golden ratio
    address public immutable token = 0x6d0c966c8A09e354Df9C48b446A474CE3343D912; //XVMC token
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    bool rapidAdoptionBoost; //can only be called once, after 22 september
    bool bigFibonacciActivated;
    bool bigFibonacciStopped;
    
    uint256 preProgrammedCounter = 500; // used for Rapid Adoption Boost, to decrease rewards periodically
    uint256 preProgrammedCounterTimestamp;
    
    uint256 fibonacciPayoutEndBlock; // block that ends the event
    bool endFibonacciPayout;
    
    uint256 lastReward;
    
    modifier whenReady() {
      require(block.timestamp > 1636384802, "after Nov 8");
      _;
    }
    
    /**
     * Event called "RapidAdoptionBoost"
     * Increase rewards RAPIDLY to encourage the staking and locking in the tokens
     * XVMC is like mafia, once you are in, you're in. There is no getting out.
     * 
     * Programmed to reduce periodically upon calling
     * Users get rewarded costToVote for calling
     */
    function activateRapidAdoptionBoost() external whenReady {
		require(!(IXVMCgovernor(owner()).fibonacciDelayed()), "event has been delayed");
        require(!rapidAdoptionBoost, "Already activated");
        require(block.timestamp > 1636384802 + 24 * 3600, "Can be activated 24hours after full decentralization");
        rapidAdoptionBoost = true;
    }
    function updatePreProgrammedRewards() external whenReady {
        require(rapidAdoptionBoost && preProgrammedCounter > 0, "Must be activated"); 
        if(block.timestamp > 1637421602 && preProgrammedCounter != 0) {
            IXVMCgovernor(owner()).setInflation(25694201337 * 1e9); //set to roughly 25tokens/block.
            preProgrammedCounter = 0; //kill the function due to Fibonacci Payout event
        }
        if(preProgrammedCounter == 500) {
            IXVMCgovernor(owner()).setInflation(500 * 1e18);
            lastReward = 500 * 1e18;
            preProgrammedCounter--;
            preProgrammedCounterTimestamp = block.timestamp;
            IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote());
        } else if(preProgrammedCounter < 500 && preProgrammedCounter > 46) {
            require(preProgrammedCounterTimestamp + 15 minutes < block.timestamp, "wait 15minutes");
            lastReward -= goldenRatio * 1e15;
            IXVMCgovernor(owner()).setInflation(lastReward);
            preProgrammedCounter--; 
            preProgrammedCounterTimestamp = block.timestamp;
            IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote());
        } else if(preProgrammedCounter < 46 && preProgrammedCounter > 27) {
            require(preProgrammedCounterTimestamp + 4 hours < block.timestamp, "wait 4hours");
            lastReward -= goldenRatio * 1e15;
            IXVMCgovernor(owner()).setInflation(lastReward);
            preProgrammedCounter--; 
            preProgrammedCounterTimestamp = block.timestamp;
            IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote());
        } else if(preProgrammedCounter < 28 && preProgrammedCounter > 14) {
            require(preProgrammedCounterTimestamp + 6 hours < block.timestamp, "wait 6hours");
            lastReward -= goldenRatio * 1e15;
            IXVMCgovernor(owner()).setInflation(lastReward);
            preProgrammedCounter--; 
            preProgrammedCounterTimestamp = block.timestamp;
            IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote());
        } else if(preProgrammedCounter < 15 && preProgrammedCounter > 4) {
            require(preProgrammedCounterTimestamp + 8 hours < block.timestamp, "wait 8hours");
            lastReward -= goldenRatio * 1e15;
            IXVMCgovernor(owner()).setInflation(lastReward);
            preProgrammedCounter--;
            preProgrammedCounterTimestamp = block.timestamp;
            IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote());
        } else if(preProgrammedCounter < 5 && preProgrammedCounter > 1) {
            require(preProgrammedCounterTimestamp + 12 hours < block.timestamp, "wait 12hrs");
            lastReward -= goldenRatio * 1e15;
            IXVMCgovernor(owner()).setInflation(lastReward);
            preProgrammedCounter--;
            preProgrammedCounterTimestamp = block.timestamp;
            IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote());
        } else if(preProgrammedCounter == 1) {
            require(preProgrammedCounterTimestamp + 1 days < block.timestamp, "wait 1day");
            IXVMCgovernor(owner()).setInflation(25694201337 * 1e9); //set to roughly 25tokens/block. 
            preProgrammedCounter = 0; 
            IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote());
        }
    }
    
    /**
     * November 23 is Fibonacci Day, an annual holiday that honors one of the most
     * influential mathematicians of the Middle Ages - Leonardo Bonacci,
     * popularly known as Leonardo Fibonacci.
     * 
     * Event starts on 22nd of November at 12PM(noon) UTC
     * Roughly +23.6% of entire supply is printed in a period of 48hours
     * function can be called 12hours prior, and expires 12hours after, total(roughly) 48hours duration
     */
    function startFibonacciPayout() external whenReady {
		require(!(IXVMCgovernor(owner()).fibonacciDelayed()), "event has been delayed");
        require(!bigFibonacciActivated && block.timestamp > 1637582400);
		IERC20(token).safeTransferFrom(msg.sender, owner(), IXVMCgovernor(owner()).costToVote() * 5);
        
		bigFibonacciActivated = true;
        uint256 toPrint = getTotalSupply() * 236 / 1000;
        uint256 newReward = toPrint / (48 * 360000 / IXVMCgovernor(owner()).blocks100PerSecond());
        fibonacciPayoutEndBlock = block.number + toPrint / newReward;
        IXVMCgovernor(owner()).setInflation(newReward); 
    }
    
    /**
     * ends the Fibonacci payout, sets the inflation to standard 25.69XVMC/block
    */
    function terminateFibonacciPayout() external whenReady {
        require(bigFibonacciActivated && !endFibonacciPayout);
        require(block.number >= fibonacciPayoutEndBlock, "must print 23.6% supply");
		
        IXVMCgovernor(owner()).setInflation(2569 * 1e16); // set to 25.69tokens/block
        endFibonacciPayout = true;
        IERC20(token).safeTransferFrom(owner(), payable(msg.sender), IXVMCgovernor(owner()).costToVote() * 5);
    }
    
    //transfers ownership of this contract to new governor(if eligible)
    function changeGovernor() external {
        require(IXVMCgovernor(owner()).changeGovernorEnforced());
        transferOwnership(IXVMCgovernor(owner()).eligibleNewGovernor());
    }
    
    function getTotalSupply() private view returns (uint256) {
        return IERC20(token).totalSupply() - IERC20(token).balanceOf(owner()) - IERC20(token).balanceOf(deadAddress);
    }
}