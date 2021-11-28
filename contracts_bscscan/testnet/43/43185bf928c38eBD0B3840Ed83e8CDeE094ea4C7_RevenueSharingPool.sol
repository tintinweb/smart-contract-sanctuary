/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

// File: utils/Counters.sol



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: RevenueSharingPool(Latest).sol


pragma solidity 0.8.10;





contract RevenueSharingPool is Ownable {
    // Utility Libraries  
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _roundId;

    // swap token related variables
    IERC20 public luckyBusd;
    
    // contract global variables
    uint256 public START_ROUND_DATE;
    mapping(uint256 => uint256) public MAX_DATE;
    uint256 public numberOfDate;
    
    // staking related variables
    mapping(uint256 => mapping(uint256 => uint256)) public totalStake;
    mapping(uint256 => uint256) public totalLuckyRevenue;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public stakeAmount;
    address[] internal stakeholders;
    mapping(address => bool) public whitelists;
    
    // user info variables
    struct UserInfo {
        uint256 amount;
        uint256 rewardDept;
        uint256 pendingReward;
        uint256 lastUpdateRoundId;
    }
    
    mapping(address => UserInfo) public userInfo;
    
    // pool info
    struct PoolInfo {
	    uint256 winLoss;
	    uint256 TPV;
	    string symbol;
	    uint256 TVL;
	    uint256 percentOfRevshare;
	    uint256 participants;
	    uint256 totalLuckyRevenue;
    }
    
    mapping(uint256 => PoolInfo) public poolInfo;

    event DepositStake(address indexed account, uint256 amount, uint256 timestamp);
    event WithdrawStake(address indexed account, uint256 amount, uint256 timestamp);
    event ClaimReward(address indexed account, uint256 amount, uint256 timestamp);
    event DistributeLuckyRevenue(address from, address to, uint256 amounts);
    event UpdateMaxDate(uint256 newMaxDate);
    event AddWhitelist(address indexed account);
    event RemoveWhitelist(address indexed account);
    
    modifier isWhitelisted(address addr) {
        require(whitelists[addr], "Permission Denied");
        _;
    }

    constructor (
        address _luckyBusd,
        address owner_
    ){
        luckyBusd = IERC20(_luckyBusd);
        START_ROUND_DATE = block.timestamp;        
        transferOwnership(owner_);
        numberOfDate = 7;
        MAX_DATE[0] = numberOfDate;
    }
    
    //-------------------------Staking Functions -------------------------//
    
    // deposit LUCKY-BUSD LP token
    function depositToken(uint256 amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(amount > 0, "Insufficient deposit amount!");
        luckyBusd.safeTransferFrom(msg.sender, address(this), amount);
        uint256 depositDate = getDepositDate();
        uint256 roundId = getCurrentRoundId();
        
        addStakeholder(msg.sender);
        
        if (!isStakeUpToDate(roundId)) {
           updatePendingStake(); 
        }
        
        user.amount += amount;
        updateStake(roundId, depositDate, amount);
        emit DepositStake(msg.sender, amount, block.timestamp);
    }
    
    // withdraw LUCKY-BUSD LP token
    function withdrawToken() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 roundId = getCurrentRoundId();

        if (!isStakeUpToDate(roundId)) {
           updatePendingStake(); 
        }
        
        updatePendingReward();
        uint256 amount = user.amount;
        user.amount = 0;
        removeStake(roundId);
        removeStakeholder(msg.sender);
        luckyBusd.safeTransfer(msg.sender, amount);
        emit WithdrawStake(msg.sender, amount, block.timestamp);
    }
    
    // emergency withdraw LUCKY-BUSD LP token without calculated pending reward (just withdraw LP)
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 roundId = getCurrentRoundId();
        uint256 amount = user.amount;
        user.amount = 0;
        user.lastUpdateRoundId = roundId;
        removeStake(roundId);
        removeStakeholder(msg.sender);
        luckyBusd.safeTransfer(msg.sender, amount);
        emit WithdrawStake(msg.sender, amount, block.timestamp);
    }
    
    // claim LUCKY reward
    function claimReward() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 roundId = getCurrentRoundId();
        
        if (user.amount > 0) {
            if (!isStakeUpToDate(roundId)) {
               updatePendingStake(); 
            }
            updatePendingReward();
        }
        
        uint256 claimableLuckyReward = user.pendingReward;
        require(claimableLuckyReward > 0, "Not enough claimable LUCKY reward!");
        user.rewardDept += claimableLuckyReward;
        user.pendingReward -= claimableLuckyReward;
        emit ClaimReward(msg.sender, claimableLuckyReward, block.timestamp);
    }
    
    //-------------------------Updater Functions -------------------------//
    
   function addStakeholder(address account) internal {
       (bool _isStakeholder, ) = isStakeholder(account);
       if (!_isStakeholder) stakeholders.push(account);
   }

   function removeStakeholder(address account) internal {
       (bool _isStakeholder, uint256 i) = isStakeholder(account);
       if (_isStakeholder){
           stakeholders[i] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
    }
    
    function updateRoundId() internal {
        _roundId.increment(); // increase round id when owner deposit revenue share to the contract
    }
    
    // Update max number of day in a round (default 7 days)
    function updateMaxDate(uint256 newMaxDate) external onlyOwner {
        uint256 currentRoundId = getCurrentRoundId();
        numberOfDate = newMaxDate;
        MAX_DATE[currentRoundId] = numberOfDate;
        emit UpdateMaxDate(newMaxDate);
    }
    
    function addWhitelist(address addr) external onlyOwner {
        whitelists[addr] = true;
        emit AddWhitelist(addr);
    }

    function removeWhitelist(address addr) external onlyOwner {
        whitelists[addr] = false;
        emit RemoveWhitelist(addr);
    }
    
    function updatePoolInfo(uint256 winLoss, uint256 TPV, string memory symbol, uint256 revenueAmount, uint256 percentOfRevshare, uint256 roundID) internal {
	    uint256 totalValueLock = luckyBusd.balanceOf(address(this));
	    PoolInfo storage _poolInfo = poolInfo[roundID];
	    _poolInfo.winLoss = winLoss;
	    _poolInfo.TPV = TPV;
        _poolInfo.symbol = symbol;
        _poolInfo.percentOfRevshare = percentOfRevshare;
	    _poolInfo.TVL = totalValueLock;
	    _poolInfo.participants = stakeholders.length;
	    _poolInfo.totalLuckyRevenue = revenueAmount;
    }

    function removeStake(uint256 roundId) internal {
        for (uint256 i = 1; i <= MAX_DATE[roundId]; i++) {
            uint256 amount = stakeAmount[roundId][i][msg.sender];
            stakeAmount[roundId][i][msg.sender] -= amount;
            totalStake[roundId][i] -= amount;
        }
    }
    
    function updateStake(uint256 roundId, uint256 depositDate, uint256 amount) internal {
        for(uint256 i = depositDate; i <= MAX_DATE[roundId]; i++) {
            stakeAmount[roundId][i][msg.sender] += amount;
            totalStake[roundId][i] += amount;
        }
    }
    
    // Update pending stake of msg.sender from last update round to current round (MasterPool)
    function updatePendingStake() internal {
        UserInfo storage user = userInfo[msg.sender];
        uint256 lastUpdateRoundId = user.lastUpdateRoundId;
        uint256 currentRoundId = getCurrentRoundId();
        uint256 amount = user.amount;
        // If last update stake amount is on round 2 so we need to update stake amount from round 3 - 5
        for(uint256 i = (lastUpdateRoundId + 1); i <= currentRoundId; i++) {
            for(uint256 j = 1; j <= MAX_DATE[currentRoundId]; j++) {
                stakeAmount[i][j][msg.sender] = amount;
            }
        }
        user.lastUpdateRoundId = currentRoundId;
    }
    
    function updateTotalStake(uint256 roundId) internal {
        uint256 _totalStake = luckyBusd.balanceOf(address(this));
        for(uint256 i = 1; i <= MAX_DATE[roundId]; i++) {
            totalStake[roundId][i] = _totalStake;
        }
    }
    
    function updatePendingReward() internal {
        UserInfo storage user = userInfo[msg.sender];
        uint256 luckyReward = calculateTotalLuckyReward(msg.sender);
        uint256 luckyRewardDept = user.rewardDept;
        user.pendingReward = (luckyReward - luckyRewardDept);
    }
    
    function calculateLuckyReward(address account, uint256 roundId) internal view returns (uint256) {
        uint256 luckyReward;
        uint256 totalLuckyRevenuePerDay = getTotalLuckyRewardPerDay(roundId);
        if (totalLuckyRevenuePerDay == 0) {
            return 0;
        }
        for (uint256 i = 1; i <= MAX_DATE[roundId]; i++) {
            uint256 amount = stakeAmount[roundId][i][account];
            if (amount == 0) continue;
            uint256 _totalStake = totalStake[roundId][i];
            uint256 userSharesPerDay = (amount * 1e18) / _totalStake;
            luckyReward += (totalLuckyRevenuePerDay * userSharesPerDay) / 1e18;
        }
        return luckyReward;
    }
    
    function calculateTotalLuckyReward(address _address) internal view returns (uint256) {
        uint256 totalLuckyReward = 0;
        uint256 roundId = getCurrentRoundId();
        for (uint256 i = 0; i < roundId; i++) { 
            totalLuckyReward += calculateLuckyReward(_address, i);
        }
        return totalLuckyReward;
    }
    
    //-------------------------Getter Functions -------------------------//
    
   function isStakeholder(address _address) public view returns(bool, uint256) {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
    }
   
    // return current round id
    function getCurrentRoundId() public view returns (uint256) {
        return _roundId.current();
    }
    
    // return user stake amount of specific round and date
    function getStakeAmount(uint256 roundId, uint256 day, address _address) external view returns (uint256) {
        return stakeAmount[roundId][day][_address];
    }
     
    // Get past time (in seconds) since start round
    function getRoundPastTime() external view returns (uint256) {
        return (block.timestamp - START_ROUND_DATE);
    }
    
    // check deposit date of msg.sender (date range: 1 - MAX_DATE)
    function getDepositDate() internal view returns (uint256) {
        require(block.timestamp >= START_ROUND_DATE, "Can not stake before round start!");
        uint256 roundId = getCurrentRoundId();

        if (block.timestamp > START_ROUND_DATE + (MAX_DATE[roundId] * 5 minutes)) return MAX_DATE[roundId];

        for (uint256 i = 1; i <= MAX_DATE[roundId]; i++) { 
            if (block.timestamp <= START_ROUND_DATE + (i * 5 minutes)) { 
                return i;
            }
        }
    }
    
    // return total LUCKY reward per day of specific round
    function getTotalLuckyRewardPerDay(uint256 roundId) public view returns (uint256) {
        return (totalLuckyRevenue[roundId] / MAX_DATE[roundId]);
    }
    
    // return total LUCKY-BUSD LP balance in this contract
    function getLuckyBusdBalance() external view returns (uint256) {
        return luckyBusd.balanceOf(address(this));
    }
     
    // return unclaimed LUCKY reward of msg.sender
    function getPendingReward(address _address) external view returns (uint256) {
        UserInfo storage user = userInfo[_address];
        if (user.amount == 0) {
            return user.pendingReward;
        }
        uint256 luckyReward = calculateTotalLuckyReward(_address);
        uint256 luckyRewardDept = user.rewardDept;
        return (luckyReward - luckyRewardDept);
    }
    
    function getLuckyRewardPerRound(uint256 roundId, address _address) external view returns (uint256){
	    uint256 luckyReward = calculateLuckyReward(_address, roundId);
	    return luckyReward;
    }
    
    // checking whether user reward is up-to-date or not
    function isStakeUpToDate(uint256 currentRoundId) internal view returns (bool) {
        return (userInfo[msg.sender].lastUpdateRoundId == currentRoundId);
    }
    
    //-------------------------Deposit Revenue Functions -------------------------//
    
    // for owner to deposit revenue (any tokens) to RevenueSharingPool contract
    function depositRevenue(
        string memory symbol,
        uint256 amount,
        uint256 winLoss,
        uint256 TPV,
        uint256 percentOfRevshare
    ) external isWhitelisted(msg.sender) {
        uint256 roundId = getCurrentRoundId();
        totalLuckyRevenue[roundId] += amount;
        updatePoolInfo(winLoss, TPV, symbol, amount, percentOfRevshare, roundId); // update round pool info
        START_ROUND_DATE = block.timestamp;
        updateRoundId();
        uint256 currentRoundId = getCurrentRoundId();
        MAX_DATE[currentRoundId] = numberOfDate;
        updateTotalStake(currentRoundId); // update new round total stake
        emit DistributeLuckyRevenue(msg.sender, address(this), amount);
    }
}