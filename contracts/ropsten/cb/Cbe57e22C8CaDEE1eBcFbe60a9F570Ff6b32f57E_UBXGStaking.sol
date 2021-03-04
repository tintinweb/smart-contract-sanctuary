/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


// 
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
    * @dev Indicates that the contract has been initialized.
    */
    bool private initialized;

    /**
    * @dev Indicates that the contract is in the process of being initialized.
    */
    bool private initializing;

    /**
    * @dev Modifier to use in the initializer function of a contract.
    */
    modifier initializer() {
      require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

      bool isTopLevelCall = !initializing;
      if (isTopLevelCall) {
        initializing = true;
        initialized = true;
      }

      _;

      if (isTopLevelCall) {
        initializing = false;
      }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
      // extcodesize checks the size of the code stored in an address, and
      // address returns the current address. Since the code is still not
      // deployed when running a constructor, any checks on its code size will
      // yield zero, making it an effective way to detect if a contract is
      // under construction or not.
      address self = address(this);
      uint256 cs;
      assembly { cs := extcodesize(self) }
      return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function init(address sender) public initializer {
      _owner = sender;
    }

    /**
    * @return the address of the owner.
    */
    function owner() public view returns(address) {
      return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
      require(isOwner());
      _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns(bool) {
      return msg.sender == _owner;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
      emit OwnershipRenounced(_owner);
      _owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0));
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }

    uint256[50] private ______gap;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface SIERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);

    /**
    * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns(uint256);

    /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns(bool);

    /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
    function allowance(address owner, address spender) external view returns(uint256);

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
    function approve(address spender, uint256 amount) external returns(bool);

    /**
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function mint(address account, uint256 amount) external returns(bool);

    function cap() external view returns(uint256);

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

// 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
 * To use this library you can add a `using SafeERC20 for SIERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(SIERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(SIERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {SIERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(SIERC20 token, address spender, uint256 value) internal {        
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(SIERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract UBXGStaking is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for SIERC20;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event Emergency();

    // notice A User Info for user staked amount
    struct UserInfo 
    {
        uint256 amountStaked;
        uint256 rewardDebt;
        uint256 rewardUBXTDebt;
    }

    // notice A Pool Info to save pool details
    struct PoolInfo 
    {
        SIERC20 token;
        bool lockStatus;
        bool ubxtDistributeStatus;
        uint256 allocationPoints;
        uint256 lastTotalReward;
        uint256 lastUBXTTotalReward;
        uint256 accRewardPerShare;
        uint256 ubxtAccRewardPerShare;
    }

    // notice distributed UBXG token
    SIERC20 public rewardToken;
    // notice distributed UBXT token
    SIERC20 public ubxtToken;

    // notice Info of each pool
    PoolInfo[] public poolInfo;
    // notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // notice Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocationPoints;

    // notice The status of add pool info of each pool
    mapping (SIERC20 => bool) existingPools;
    // notice The status of updated pool info by owner
    mapping (uint256 => bool) ownerPoolInfoUpdate;
    // notice The status of updated pool info by epoch
    mapping (uint256 => bool) poolInfoChangeStatus;
    // notice The total UBXG staked
    uint256 public totalStakedUbxg;
    // notice The total UBXT staked
    uint256 public totalStakedUBXT;
    // notice Max lp tokens added into the pool
    uint256 constant maxPoolCount = 20; // to simplify things and ensure massUpdatePools is safe
    // notice total UBXG rewards for distribution
    uint256 totalReward;
    // notice last UBXG rewards balance
    uint256 lastRewardBalance;
    // notice total UBXT rewards for distribution
    uint256 totalUBXTReward;
    // notice last UBXT rewards balance
    uint256 lastUBXTRewardBalance;
    // notice minimum time interval to call epoch
    uint256 public minEpochTimeIntervalSec;
    // notice to call epoch at fixed time in a day 
    uint256 public epochWindowOffsetSec;
    // notice seconds for epoch active
    uint256 public epochWindowLengthSec;
    // notice last epoch call time
    uint256 public lastEpochTimestampSec;
    // notice minted reward tokens for week
    uint256 public mintedRewardToken;
    // notice epoch count
    uint256 public epoch;
    // notice emergey time recovery time
    uint256 public emergencyRecoveryTimestamp;

    constructor() public
    { }
    
    function initialize(address _rewardToken, address _ubxtToken, address _owner) public initializer {
        Ownable.init(_owner);
        rewardToken = SIERC20(_rewardToken);
        ubxtToken = SIERC20(_ubxtToken);
        
        minEpochTimeIntervalSec = 43200;  // 43200
        epochWindowOffsetSec = 0;
        epochWindowLengthSec = 30 minutes;  // 30 minutes
        lastEpochTimestampSec = 0;
    }

    /**
     * @return Total added pool count
     */
    function poolInfoCount() external view returns (uint256) 
    {
        return poolInfo.length;
    }
    
    /**
     * @return If the latest block timestamp is within the Epoch time window it, returns true.
     *         Otherwise, returns false.
     */
    function inEpochWindow() public view returns (bool) {
        return (
            now.mod(minEpochTimeIntervalSec) >= epochWindowOffsetSec &&
            now.mod(minEpochTimeIntervalSec) < (epochWindowOffsetSec.add(epochWindowLengthSec))
        );
    }
    
    /**
     * @notice Sets the parameters which control the timing and frequency of
     *         Epoch operations.
     *         a) the minimum time period that must elapse between Epoch cycles.
     *         b) the Epoch window offset parameter.
     *         c) the Epoch window length parameter.
     * @param minEpochTimeIntervalSec_ More than this much time must pass between Epoch
     *        operations, in seconds.
     * @param EpochWindowOffsetSec_ The number of seconds from the beginning of
              the Epoch interval, where the Epoch window begins.
     * @param EpochWindowLengthSec_ The length of the Epoch window in seconds.
     */
    function setEpochTimingParameters(
        uint256 minEpochTimeIntervalSec_,
        uint256 EpochWindowOffsetSec_,
        uint256 EpochWindowLengthSec_)
        external
        onlyOwner
    {
        require(minEpochTimeIntervalSec_ > 0);
        require(EpochWindowOffsetSec_ < minEpochTimeIntervalSec_);

        minEpochTimeIntervalSec = minEpochTimeIntervalSec_;
        epochWindowOffsetSec = EpochWindowOffsetSec_;
        epochWindowLengthSec = EpochWindowLengthSec_;
    }

    /**
     * @notice Add Pool details for staking
     * @param _allocationPoints Weight of stake token to get reward
     * @param _lockStatus Represent status of stake token false for lock staking
     * @param _ubxtDistributeStatus When false pool will not get UBXT rewards tokens and true to get UBXT rewards tokens.
     * @param _token stake/lp token address
     */
    function addPool(uint256 _allocationPoints, bool _lockStatus, bool _ubxtDistributeStatus, SIERC20 _token) public onlyOwner
    {
        require (!existingPools[_token], "Pool exists");
        require (poolInfo.length < maxPoolCount, "Too many pools");
        existingPools[_token] = true;
        massUpdatePools();
        totalAllocationPoints = totalAllocationPoints.add(_allocationPoints);
        poolInfo.push(PoolInfo({
            token: _token,
            allocationPoints: _allocationPoints,
            lastTotalReward: totalReward,
            lastUBXTTotalReward: totalUBXTReward,
            lockStatus: _lockStatus,
            ubxtDistributeStatus: _ubxtDistributeStatus,
            accRewardPerShare: 0,
            ubxtAccRewardPerShare: 0
        }));
    }
    
    /**
     * @notice Call epoch to mint new rewards token and update pool info 
     * this method will call in every 12 hours at fixed time
     */
    function mintDistributeRewards() public {
        require(inEpochWindow(), "Can not call epoch that time");

        // This comparison also ensures there is no reentrancy.
        require(lastEpochTimestampSec.add(minEpochTimeIntervalSec) < now, "Epoch will call after some time");

        // Snap the Epoch time to the start of this window.
        lastEpochTimestampSec = now.sub(
            now.mod(minEpochTimeIntervalSec)).add(epochWindowOffsetSec);
            
        if (mintedRewardToken == 0) {
            mintedRewardToken = (rewardToken.cap()).mul(45).div(1000);
        }
        
        uint256 epochStatus = epoch.mod(14); // 14
        uint256 decreaseAmount = 0;
        if (epochStatus == 0 && epoch != 0) {
            decreaseAmount = mintedRewardToken.mul(4461).div(100000);
        }
        
        mintedRewardToken = mintedRewardToken.sub(decreaseAmount);
        rewardToken.mint(address(this), mintedRewardToken.div(14));
        
        epoch = epoch.add(1);

        if (epoch == 2 && poolInfoChangeStatus[epoch] == false && ownerPoolInfoUpdate[epoch] == false) {
            poolInfoChangeStatus[epoch] = true;
            
            uint256[] memory _pid = new uint256[](3);
            _pid[0] = 0; _pid[1] = 1; _pid[2] = 2;
            
            uint256[] memory _allocationPoints = new uint256[](3);
            _allocationPoints[0] = 45; _allocationPoints[1] = 35; _allocationPoints[2] = 20;
            
            bool[] memory lockStatus = new bool[](3);
            lockStatus[0] = false; lockStatus[1] = false; lockStatus[2] = false;
            
            bool[] memory ubxtDistributeStatus = new bool[](3);
            ubxtDistributeStatus[0] = false; ubxtDistributeStatus[1] = true; ubxtDistributeStatus[2] = false;
            
            for(uint256 i=0; i < _pid.length; i++)
            updatePoolAllocationPoints(_pid[i], _allocationPoints[i], lockStatus[i], ubxtDistributeStatus[i]);
        }
    }
    
    function updatePoolAllocationPoints(uint256 _poolId, uint256 _allocationPoints, bool _lockStatus, bool _ubxtDistributeStatus) internal
    { 
        require (emergencyRecoveryTimestamp == 0);
        massUpdatePools();
        totalAllocationPoints = totalAllocationPoints.sub(poolInfo[_poolId].allocationPoints).add(_allocationPoints);
        poolInfo[_poolId].allocationPoints = _allocationPoints;
        poolInfo[_poolId].lockStatus = _lockStatus;
        poolInfo[_poolId].ubxtDistributeStatus = _ubxtDistributeStatus;
    }

    /**
     * @notice Update added pool info by owner
     * @param _poolId pid of pool
     * @param _allocationPoints Weight of stake token to get reward
     * @param _lockStatus Represent status of stake token false for lock staking
     * @param _ubxtDistributeStatus When false pool will not get UBXT rewards tokens and true to get UBXT rewards tokens.
     * @param _epoch epoch number
     */
    function setPoolAllocationPoints(uint256[] memory _poolId, uint256[] memory _allocationPoints, bool[] memory _lockStatus, bool[] memory _ubxtDistributeStatus, uint256 _epoch) public onlyOwner
    { 
        require (_poolId.length == _allocationPoints.length, "Invalid data");
        require (_poolId.length == _lockStatus.length, "Invalid data");
        require (_poolId.length == _ubxtDistributeStatus.length, "Invalid data");
        require (emergencyRecoveryTimestamp == 0);

        ownerPoolInfoUpdate[_epoch] = true;
        massUpdatePools();
        for(uint256 i=0; i < _poolId.length; i++) {
        totalAllocationPoints = totalAllocationPoints.sub(poolInfo[_poolId[i]].allocationPoints).add(_allocationPoints[i]);
        poolInfo[_poolId[i]].allocationPoints = _allocationPoints[i];
        poolInfo[_poolId[i]].lockStatus = _lockStatus[i];
        poolInfo[_poolId[i]].ubxtDistributeStatus = _ubxtDistributeStatus[i];
        }
    }

    /**
     * @return Return total earned UBXG token for staked time period
     * @param _poolId pid of pool
     * @param _user User address
     */
    function pendingReward(uint256 _poolId, address _user) external view returns (uint256) 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 supply;
        if (_poolId == 1)
            supply = totalStakedUbxg;
        else if (_poolId == 0)
            supply = totalStakedUBXT;
        else
            supply = pool.token.balanceOf(address(this));
        uint256 balance = rewardToken.balanceOf(address(this)).sub(totalStakedUbxg);
        uint256 _totalReward = totalReward;
        if (balance > lastRewardBalance) {
            _totalReward = _totalReward.add(balance.sub(lastRewardBalance));
        }
        if (_totalReward > pool.lastTotalReward && supply != 0) {
            uint256 reward = _totalReward.sub(pool.lastTotalReward).mul(pool.allocationPoints).div(totalAllocationPoints);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(supply));
        }
        return user.amountStaked.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }
    
    /**
     * @return Return total earned UBXT token for staked time period
     * @param _poolId pid of pool
     * @param _user User address
     */
    function pendingUBXTReward(uint256 _poolId, address _user) external view returns (uint256) 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];
        uint256 accRewardPerShare = pool.ubxtAccRewardPerShare;
        uint256 supply;
        if (_poolId == 1)
            supply = totalStakedUbxg;
        else if (_poolId == 0)
            supply = totalStakedUBXT;
        else
            supply = pool.token.balanceOf(address(this));
        uint256 balance = ubxtToken.balanceOf(address(this)).sub(totalStakedUBXT);
        uint256 _totalReward = totalUBXTReward;
        if (balance > lastUBXTRewardBalance) {
            _totalReward = _totalReward.add(balance.sub(lastUBXTRewardBalance));
        }
        if (_totalReward > pool.lastUBXTTotalReward && supply != 0) {
            uint256 reward = _totalReward.sub(pool.lastUBXTTotalReward).mul(100).div(100);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(supply));
        }
        if(_poolId != 1)
            accRewardPerShare = 0;
        return user.amountStaked.mul(accRewardPerShare).div(1e12).sub(user.rewardUBXTDebt);
    }

    /**
     * @notice Sync all pool info and variables
     */
    function massUpdatePools() public 
    {
        uint256 length = poolInfo.length;
        for (uint256 poolId = 0; poolId < length; ++poolId) {
            updatePool(poolId);
        }
    }

    /**
     * @notice Sync pool info and variables
     * @param _poolId PID of pool
     */
    function updatePool(uint256 _poolId) public 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        uint256 rewardBalance = rewardToken.balanceOf(address(this)).sub(totalStakedUbxg);
        uint256 ubxtRewardBalance = ubxtToken.balanceOf(address(this)).sub(totalStakedUBXT);
        uint256 _totalReward = totalReward.add(rewardBalance.sub(lastRewardBalance));
        uint256 _totalUBXTReward = totalUBXTReward.add(ubxtRewardBalance.sub(lastUBXTRewardBalance));
        lastUBXTRewardBalance = ubxtRewardBalance;
        lastRewardBalance = rewardBalance;
        totalReward = _totalReward;
        totalUBXTReward = _totalUBXTReward;
        uint256 supply;
        if (_poolId == 1)
            supply = totalStakedUbxg;
        else if (_poolId == 0)
            supply = totalStakedUBXT;
        else
            supply = pool.token.balanceOf(address(this));
        if (supply == 0) {
            pool.lastTotalReward = _totalReward;
            pool.lastUBXTTotalReward = _totalUBXTReward;
            return;
        }
        uint256 reward = _totalReward.sub(pool.lastTotalReward).mul(pool.allocationPoints).div(totalAllocationPoints);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(supply));
        pool.lastTotalReward = _totalReward;
        
        if(_poolId == 1) {
            uint256 ubxtReward = _totalUBXTReward.sub(pool.lastUBXTTotalReward).mul(100).div(100);
            pool.ubxtAccRewardPerShare = pool.ubxtAccRewardPerShare.add(ubxtReward.mul(1e12).div(supply));
            pool.lastUBXTTotalReward = _totalUBXTReward;
        } else {
            pool.ubxtAccRewardPerShare = 0;
            pool.lastUBXTTotalReward = 0;
        }
    }

    /**
     * @notice Stake and Claim lp tokens
     * @param _poolId PID of pool
     * @param _amount stake amount
     * Calim reward token will happen when amount equals to 0 otherwise staking will happen 
     */
    function deposit(uint256 _poolId, uint256 _amount) public 
    {
        require (emergencyRecoveryTimestamp == 0, "Withdraw only");
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        require (pool.lockStatus == false, "can not stake right now");
        updatePool(_poolId);
        
        if (user.amountStaked > 0) {
            uint256 pending = user.amountStaked.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            uint256 ubxtPending = user.amountStaked.mul(pool.ubxtAccRewardPerShare).div(1e12).sub(user.rewardUBXTDebt);
            if (pending > 0) {
                safeRewardTransfer(msg.sender, pending);                
            }
            
            if (ubxtPending > 0 && _poolId == 1) {
                safeUBXTRewardTransfer(msg.sender, ubxtPending);                
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amountStaked = user.amountStaked.add(_amount);
            if (_poolId == 1)
            totalStakedUbxg = totalStakedUbxg.add(_amount);
            if (_poolId == 0)
            totalStakedUBXT = totalStakedUBXT.add(_amount);
        }
        user.rewardDebt = user.amountStaked.mul(pool.accRewardPerShare).div(1e12);
        user.rewardUBXTDebt = user.amountStaked.mul(pool.ubxtAccRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _poolId, _amount);
    }

    /**
     * @notice Unstake/Withdraw LP tokens from pool
     * @param _poolId PID of pool
     * @param _amount un-stake amount
     */
    function withdraw(uint256 _poolId, uint256 _amount) public 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        require(user.amountStaked >= _amount, "Amount more than staked");
        updatePool(_poolId);
        uint256 pending = user.amountStaked.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        uint256 ubxtPending = user.amountStaked.mul(pool.ubxtAccRewardPerShare).div(1e12).sub(user.rewardUBXTDebt);
        if (pending > 0) {
            safeRewardTransfer(msg.sender, pending);
        }
        if (ubxtPending > 0 && _poolId == 1) {
                safeUBXTRewardTransfer(msg.sender, ubxtPending);                
        }
        if (_amount > 0) {
            user.amountStaked = user.amountStaked.sub(_amount);
            pool.token.safeTransfer(address(msg.sender), _amount);
            if (_poolId == 1)
            totalStakedUbxg = totalStakedUbxg.sub(_amount);
            if (_poolId == 0)
            totalStakedUBXT = totalStakedUBXT.sub(_amount);
        }
        user.rewardDebt = user.amountStaked.mul(pool.accRewardPerShare).div(1e12);
        user.rewardUBXTDebt = user.amountStaked.mul(pool.ubxtAccRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _poolId, _amount);
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _poolId PID of pool
     */
    function emergencyWithdraw(uint256 _poolId) public 
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        uint256 amount = user.amountStaked;
        user.amountStaked = 0;
        user.rewardDebt = 0;
        user.rewardUBXTDebt = 0;
        pool.token.safeTransfer(address(msg.sender), amount);
        if (_poolId == 1)
        totalStakedUbxg = totalStakedUbxg.sub(amount);
        if (_poolId == 0)
        totalStakedUBXT = totalStakedUBXT.sub(amount);
        emit EmergencyWithdraw(msg.sender, _poolId, amount);
    }
    
    // emergency ubxg transfer function, just in case if rounding error causes pool to not have enough UBXGs.
    function emergencyUBXGTransfer(address _to) external onlyOwner {
        uint256 ubxgBal = rewardToken.balanceOf(address(this)).sub(totalStakedUbxg);
        safeRewardTransfer(_to, ubxgBal);
    }
    
    // emergency ubxt transfer function, just in case if rounding error causes pool to not have enough UBXGs.
    function emergencyUBXTTransfer(address _to) external onlyOwner {
        uint256 ubxtBal = rewardToken.balanceOf(address(this));
        safeUBXTRewardTransfer(_to, ubxtBal);
    }

    // Safe UBXG transfer function, just in case if rounding error causes pool to not have enough UBXGs.
    function safeRewardTransfer(address _to, uint256 _amount) internal 
    {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(_to, _amount > balance ? balance : _amount);
        lastRewardBalance = rewardToken.balanceOf(address(this)).sub(totalStakedUbxg);
    }
    
    // Safe UBXT transfer function, just in case if rounding error causes pool to not have enough UBXTs.
    function safeUBXTRewardTransfer(address _to, uint256 _amount) internal 
    {
        uint256 balance = ubxtToken.balanceOf(address(this));
        ubxtToken.safeTransfer(_to, _amount > balance ? balance : _amount);
        lastUBXTRewardBalance = ubxtToken.balanceOf(address(this)).sub(totalStakedUBXT);
    }

    function declareEmergency() public onlyOwner 
    {
        // Funds will be recoverable 3 days after an emergency is declared
        // By then, everyone should have withdrawn whatever they can
        // Failing that (which is probably why there's an emergency) we can recover for them
        emergencyRecoveryTimestamp = block.timestamp + 60*60*24*3;
        emit Emergency();
    }

    function canRecoverTokens(SIERC20 token) internal view returns (bool) 
    { 
        if (emergencyRecoveryTimestamp != 0 && block.timestamp > emergencyRecoveryTimestamp) {
            return true;
        }
        else {
            return token != rewardToken && !existingPools[token];
        }
    }
}