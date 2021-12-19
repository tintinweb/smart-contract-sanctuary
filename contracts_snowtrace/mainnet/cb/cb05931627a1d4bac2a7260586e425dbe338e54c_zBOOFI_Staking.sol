/**
 *Submitted for verification at snowtrace.io on 2021-12-19
*/

// File @openzeppelin/contracts/token/ERC20/[email protected]
// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/interfaces/IERC20WithPermit.sol
pragma solidity >=0.5.0;

interface IERC20WithPermit is IERC20Metadata {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}


// File contracts/interfaces/IBOOFI_Distributor.sol
pragma solidity >=0.5.0;

interface IBOOFI_Distributor {
    function bips(uint256 arrayIndex) external view returns (uint256);
    function recoverERC20(address token, address to) external;
    function distributeBOOFI() external;
    function checkStakingReward() external view returns (uint256);
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


// File contracts/zBOOFI_Staking.sol
pragma solidity ^0.8.6;




contract zBOOFI_Staking is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable ZBOOFI;
    IERC20 public immutable BOOFI;
    IBOOFI_Distributor public boofiDistributor;

    //sum of all user deposits of zBOOFI
    uint256 public totalShares;
    //scaled up by ACC_BOOFI_PRECISION
    uint256 public boofiPerShare;
    uint256 public constant ACC_BOOFI_PRECISION = 1e18;
    uint256 public constant MAX_BIPS = 10000;
    uint256 public constant NUMBER_TOP_HARVESTERS = 10;
    uint256 public constant SECONDS_PER_DAY = 86400;

    //sum of all BOOFI harvested by all users of the contract, over all time
    uint256 public totalHarvested;

    //stored BOOFI balance
    uint256 public storedBoofiBalance;

    //for leaderboard tracking
    address[NUMBER_TOP_HARVESTERS] public topHarvesters;
    uint256[NUMBER_TOP_HARVESTERS] public largestAmountsHarvested;

    //for tracking of statistics in trailing 24 hour period
    uint256 public rollingStartTimestamp;
    uint256 public numStoredDailyData;
    uint256[] public historicBoofiPerShare;
    uint256[] public historicTimestamps;

    //total amount harvested by each user
    mapping(address => uint256) public harvested;
    //shares are earned by depositing zBOOFI
    mapping(address => uint256) public shares;
    //pending reward = (user.amount * boofiPerShare) / ACC_BOOFI_PRECISION - user.rewardDebt
    mapping(address => uint256) public rewardDebt;

    event Deposit(address indexed caller, address indexed to, uint256 amount);
    event Withdraw(address indexed caller, address indexed to, uint256 amount);
    event Harvest(address indexed caller, address indexed to, uint256 amount, uint256 indexed totalAmountHarvested);
    event DailyUpdate(uint256 indexed dayNumber, uint256 indexed timestamp, uint256 indexed boofiPerShare);

    constructor(IERC20 _ZBOOFI, IERC20 _BOOFI, IBOOFI_Distributor _boofiDistributor) {
        ZBOOFI = _ZBOOFI;
        BOOFI = _BOOFI;
        boofiDistributor = _boofiDistributor;
        //initiate topHarvesters array with burn address
        for (uint256 i = 0; i < NUMBER_TOP_HARVESTERS; i++) {
            topHarvesters[i] = 0x000000000000000000000000000000000000dEaD;
        }
        //push first "day" of historical data
        numStoredDailyData = 1;
        historicBoofiPerShare.push(boofiPerShare);
        historicTimestamps.push(block.timestamp);
        rollingStartTimestamp = block.timestamp;
        emit DailyUpdate(1, block.timestamp, 0);
    }

    //unclaimed rewards from the distributor contract
    function checkReward() public view returns (uint256) {
        return boofiDistributor.checkStakingReward();
    }

    //returns amount of BOOFI that 'user' can currently harvest
    function pendingBOOFI(address user) public view returns (uint256) {
        uint256 unclaimedRewards = checkReward();
        uint256 multiplier =  boofiPerShare;
        if(totalShares > 0) {
            multiplier = multiplier + ((unclaimedRewards * ACC_BOOFI_PRECISION) / totalShares);
        }
        uint256 rewardsOfShares = (shares[user] * multiplier) / ACC_BOOFI_PRECISION;
        return (rewardsOfShares - rewardDebt[user]);
    }

    function getTopHarvesters() public view returns (address[NUMBER_TOP_HARVESTERS] memory) {
        return topHarvesters;
    }

    function getLargestAmountsHarvested()  public view returns (uint256[NUMBER_TOP_HARVESTERS] memory) {
        return largestAmountsHarvested;
    }

    //returns most recent stored boofiPerShare and the time at which it was stored
    function getLatestStoredBoofiPerShare() public view returns(uint256, uint256) {
        return (historicBoofiPerShare[numStoredDailyData - 1], historicTimestamps[numStoredDailyData - 1]);
    }

    //returns last amountDays of stored boofiPerShare datas
    function getBoofiPerShareHistory(uint256 amountDays) public view returns(uint256[] memory, uint256[] memory) {
        uint256 endIndex = numStoredDailyData - 1;
        uint256 startIndex = (amountDays > endIndex) ? 0 : (endIndex - amountDays + 1);
        uint256 length = endIndex - startIndex + 1;
        uint256[] memory boofiPerShares = new uint256[](length);
        uint256[] memory timestamps = new uint256[](length);
        for(uint256 i = startIndex; i <= endIndex; i++) {
            boofiPerShares[i - startIndex] = historicBoofiPerShare[i];
            timestamps[i - startIndex] = historicTimestamps[i];            
        }
        return (boofiPerShares, timestamps);
    }

    function timeSinceLastDailyUpdate() public view returns(uint256) {
        return (block.timestamp - rollingStartTimestamp);
    }

    //EXTERNAL FUNCTIONS
    //harvest rewards for message sender
    function harvest() external {
        _claimRewards();
        _harvest(msg.sender);
    }

    //harvest rewards for message sender and send them to 'to'
    function harvestTo(address to) external {
        _claimRewards();
        _harvest(to);
    }

    //deposit 'amount' of zBOOFI and credit them to message sender
    function deposit(uint256 amount) external {
        _deposit(msg.sender, amount);
    }

    //deposit 'amount' of zBOOFI and credit them to 'to'
    function depositTo(address to, uint256 amount) external {
        _deposit(to, amount);
    }

    //approve this contract to transfer 'value' zBOOFI, then deposit 'amount' of zBOOFI and credit them to message sender
    function depositWithPermit(uint256 amount, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20WithPermit(address(ZBOOFI)).permit(msg.sender, address(this), value, deadline, v, r, s);
        _deposit(msg.sender, amount);
    }

    //approve this contract to transfer 'value' zBOOFI, then deposit 'amount' of zBOOFI and credit them to 'to'
    function depositToWithPermit(address to, uint256 amount, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20WithPermit(address(ZBOOFI)).permit(msg.sender, address(this), value, deadline, v, r, s);
        _deposit(to, amount);
    }

    //withdraw funds and send them to message sender
    function withdraw(uint256 amount) external {
        _withdraw(msg.sender, amount);
    }

    //withdraw funds and send them to 'to'
    function withdrawTo(address to, uint256 amount) external {
        _withdraw(to, amount);
    }

    //OWNER-ONLY FUNCTIONS
    //in case the boofiDistributor needs to be changed
    function setBoofiDistributor(IBOOFI_Distributor _boofiDistributor) external onlyOwner {
        boofiDistributor = _boofiDistributor;
    }

    //recover ERC20 tokens other than BOOFI that have been sent mistakenly to the boofiDistributor address
    function recoverERC20FromDistributor(address token, address to) external onlyOwner {
        require(token != address(BOOFI));
        boofiDistributor.recoverERC20(token, to);
    }

    //recover ERC20 tokens other than BOOFI or zBOOFI that have been sent mistakenly to this address
    function recoverERC20(address token, address to) external onlyOwner {
        require(token != address(BOOFI) && token != address(ZBOOFI));
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, tokenBalance);
    }

    //INTERNAL FUNCTIONS
    //claim any as-of-yet unclaimed rewards
    function _claimRewards() internal {
        //claim rewards if possible
        uint256 unclaimedRewards = checkReward();
        if (unclaimedRewards > 0 && totalShares > 0) {
            boofiDistributor.distributeBOOFI();
        }
        //update boofiPerShare if the contract's balance has increased since last check
        uint256 bal = BOOFI.balanceOf(address(this));
        if (bal > storedBoofiBalance && totalShares > 0) {
            uint256 balanceDiff = bal - storedBoofiBalance;
            //update stored BOOFI Balance
            storedBoofiBalance = bal;
            boofiPerShare += ((balanceDiff * ACC_BOOFI_PRECISION) / totalShares);
        }
        _dailyUpdate();
    }

    function _harvest(address to) internal {
        uint256 rewardsOfShares = (shares[msg.sender] * boofiPerShare) / ACC_BOOFI_PRECISION;
        uint256 userPendingRewards = (rewardsOfShares - rewardDebt[msg.sender]);
        rewardDebt[msg.sender] = rewardsOfShares;
        if (userPendingRewards > 0) {
            totalHarvested += userPendingRewards;
            harvested[to] += userPendingRewards;
            _updateTopHarvesters(to);
            emit Harvest(msg.sender, to, userPendingRewards, harvested[to]);
            BOOFI.safeTransfer(to, userPendingRewards);
            //update stored BOOFI Balance
            storedBoofiBalance -= userPendingRewards;
        }
    }

    function _deposit(address to, uint256 amount) internal {
        _claimRewards();
        _harvest(to);
        if (amount > 0) {
            shares[to] += amount;
            totalShares += amount;
            rewardDebt[to] += (boofiPerShare * amount) / ACC_BOOFI_PRECISION;
            emit Deposit(msg.sender, to, amount);
            ZBOOFI.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function _withdraw(address to, uint256 amount) internal {
        _claimRewards();
        _harvest(to);
        if (amount > 0) {
            require(shares[msg.sender] >= amount, "cannot withdraw more than staked");
            shares[msg.sender] -= amount;
            totalShares -= amount;
            rewardDebt[msg.sender] -= (boofiPerShare * amount) / ACC_BOOFI_PRECISION;
            emit Withdraw(msg.sender, to, amount);
            ZBOOFI.safeTransfer(to, amount);
        }
    }

    function _updateTopHarvesters(address user) internal {
        uint256 amountHarvested = harvested[user];

        //short-circuit logic to skip steps is user will not be in top harvesters array
        if (largestAmountsHarvested[(NUMBER_TOP_HARVESTERS - 1)] >= amountHarvested) {
            return;
        }

        //check if user already in list -- fetch index if they are
        uint256 i = 0;
        bool alreadyInList;
        for(i; i < NUMBER_TOP_HARVESTERS; i++) {
            if(topHarvesters[i] == user) {
                alreadyInList = true;
                break;
            }
        }   

        //get the index of the new element
        uint256 j = 0;
        for(j; j < NUMBER_TOP_HARVESTERS; j++) {
            if(largestAmountsHarvested[j] < amountHarvested) {
                break;
            }
        }   

        if (!alreadyInList) {
            //shift the array down by one position, as necessary
            for(uint256 k = (NUMBER_TOP_HARVESTERS - 1); k > j; k--) {
                largestAmountsHarvested[k] = largestAmountsHarvested[k - 1];
                topHarvesters[k] = topHarvesters[k - 1];
            //add in the new element, but only if it belongs in the array
            } if(j < (NUMBER_TOP_HARVESTERS - 1)) {
                largestAmountsHarvested[j] =  amountHarvested;
                topHarvesters[j] =  user;
            //update last array item in edge case where new amountHarvested is only larger than the smallest stored value
            } else if (largestAmountsHarvested[(NUMBER_TOP_HARVESTERS - 1)] < amountHarvested) {
                largestAmountsHarvested[j] =  amountHarvested;
                topHarvesters[j] =  user;
            }   

        //case handling for when user already holds a spot
        //check i>=j for the edge case of updates to tied positions
        } else if (i >= j) {
            //shift the array by one position, until the user's previous spot is overwritten
            for(uint256 m = i; m > j; m--) {
                largestAmountsHarvested[m] = largestAmountsHarvested[m - 1];
                topHarvesters[m] = topHarvesters[m - 1];
            }
            //add user back into array, in appropriate position
            largestAmountsHarvested[j] =  amountHarvested;
            topHarvesters[j] =  user;   

        //handle tie edge cases
        } else {
            //just need to update user's amountHarvested in this case
            largestAmountsHarvested[i] = amountHarvested;
        }
    }

    function _dailyUpdate() internal {
        if (timeSinceLastDailyUpdate() >= SECONDS_PER_DAY) {
            //store daily data
            //store boofiPerShare and timestamp
            historicBoofiPerShare.push(boofiPerShare);
            historicTimestamps.push(block.timestamp);
            numStoredDailyData += 1;

            //emit event
            emit DailyUpdate(numStoredDailyData, block.timestamp, boofiPerShare);

            //update rolling data
            rollingStartTimestamp = block.timestamp;
        }
    }
}