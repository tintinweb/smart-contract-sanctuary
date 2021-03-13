/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity ^0.5.0;

interface ICourtStake{

    function lockedStake(uint256 amount, address beneficiar,  uint256 StartReleasingTime, uint256 batchCount, uint256 batchPeriod) external;

}

interface IMERC20 {
    function mint(address account, uint amount) external;
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract CourtFarming_HTStake {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IERC20 public constant stakedToken = IERC20(0x6f259637dcD74C767781E37Bc6133cd6A68aa161);

    IMERC20 public constant courtToken = IMERC20(0x0538A9b4f4dcB0CB01A7fA34e17C0AC947c22553);

    uint256 private _totalStaked;
    mapping(address => uint256) private _balances;

    // last updated block number
    uint256 private _lastUpdateBlock;

    // incentive rewards
    uint256 public incvFinishBlock; //  finish incentive rewarding block number
    uint256 private _incvRewardPerBlock; // incentive reward per block
    uint256 private _incvAccRewardPerToken; // accumulative reward per token
    mapping(address => uint256) private _incvRewards; // reward balances
    mapping(address => uint256) private _incvPrevAccRewardPerToken;// previous accumulative reward per token (for a user)

    uint256 public incvStartReleasingTime;  // incentive releasing time
    uint256 public incvBatchPeriod; // incentive batch period
    uint256 public incvBatchCount; // incentive batch count
    mapping(address => uint256) public  incvWithdrawn;

    address public owner;

    enum TransferRewardState {
        Succeeded,
        RewardsStillLocked
    }


    address public courtStakeAddress;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 reward);
    event ClaimIncentiveReward(address indexed user, uint256 reward);
    event StakeRewards(address indexed user, uint256 amount, uint256 lockTime);
    event CourtStakeChanged(address oldAddress, address newAddress);
    event StakeParametersChanged(uint256 incvRewardPerBlock, uint256 incvRewardFinsishBlock, uint256 incvLockTime);

    constructor () public {

        owner = msg.sender;

        uint256 incvRewardsPerBlock = 8267195767195767;
        uint256 incvRewardsPeriodInDays = 90;
		
        incvStartReleasingTime = 1620914400; // 13/05/2021 // check https://www.epochconverter.com/ for timestamp
        incvBatchPeriod = 1 days;
        incvBatchCount = 1;

         _stakeParametrsCalculation(incvRewardsPerBlock, incvRewardsPeriodInDays, incvStartReleasingTime);

        _lastUpdateBlock = blockNumber();
    }

    function _stakeParametrsCalculation(uint256 incvRewardsPerBlock, uint256 incvRewardsPeriodInDays, uint256 iLockTime) internal{


        uint256 incvRewardBlockCount = incvRewardsPeriodInDays * 5760;
        uint256 incvRewardPerBlock = incvRewardsPerBlock;

        _incvRewardPerBlock = incvRewardPerBlock * (1e18);
        incvFinishBlock = blockNumber().add(incvRewardBlockCount);

        incvStartReleasingTime = iLockTime;
    }

    function changeStakeParameters( uint256 incvRewardsPerBlock, uint256 incvRewardsPeriodInDays, uint256 iLockTime) public {

        require(msg.sender == owner, "can be called by owner only");
        updateReward(address(0));

        _stakeParametrsCalculation(incvRewardsPerBlock, incvRewardsPeriodInDays, iLockTime);

        emit StakeParametersChanged( _incvRewardPerBlock, incvFinishBlock, incvStartReleasingTime);
    }

    function updateReward(address account) public {
        // reward algorithm
        // in general: rewards = (reward per token ber block) user balances
        uint256 cnBlock = blockNumber();

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (_totalStaked > 0) {
            uint256 incvlastRewardBlock = cnBlock < incvFinishBlock ? cnBlock : incvFinishBlock;
            if (incvlastRewardBlock > _lastUpdateBlock) {
                _incvAccRewardPerToken = incvlastRewardBlock.sub(_lastUpdateBlock)
                .mul(_incvRewardPerBlock).div(_totalStaked)
                .add(_incvAccRewardPerToken);
            }
        }

        _lastUpdateBlock = cnBlock;

        if (account != address(0)) {

            uint256 incAccRewardPerTokenForUser = _incvAccRewardPerToken.sub(_incvPrevAccRewardPerToken[account]);

            if (incAccRewardPerTokenForUser > 0) {
                _incvRewards[account] =
                _balances[account]
                .mul(incAccRewardPerTokenForUser)
                .div(1e18)
                .add(_incvRewards[account]);

                _incvPrevAccRewardPerToken[account] = _incvAccRewardPerToken;
            }
        }
    }

    function stake(uint256 amount) public {
        updateReward(msg.sender);

        if (amount > 0) {
            _totalStaked = _totalStaked.add(amount);
            _balances[msg.sender] = _balances[msg.sender].add(amount);
            stakedToken.safeTransferFrom(msg.sender, address(this), amount);
            emit Staked(msg.sender, amount);
        }
    }

    function unstake(uint256 amount, bool claim) public {
        updateReward(msg.sender);

        if (amount > 0) {
            _totalStaked = _totalStaked.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            stakedToken.safeTransfer(msg.sender, amount);
            emit Unstaked(msg.sender, amount);
        }
        claim = false;
    }


    function stakeIncvRewards(uint256 amount) public returns (bool) {
        updateReward(msg.sender);
        uint256 incvReward = _incvRewards[msg.sender];


        if (amount > incvReward || courtStakeAddress == address(0)) {
            return false;
        }

        _incvRewards[msg.sender] -= amount;  // no need to use safe math sub, since there is check for amount > reward

        courtToken.mint(address(this), amount);

        ICourtStake courtStake = ICourtStake(courtStakeAddress);
        courtStake.lockedStake(amount,  msg.sender, incvStartReleasingTime, incvBatchCount, incvBatchPeriod);
        emit StakeRewards(msg.sender, amount, incvStartReleasingTime);
    }

    function setCourtStake(address courtStakeAdd) public {
        require(msg.sender == owner, "only contract owner can change");

        address oldAddress = courtStakeAddress;
        courtStakeAddress = courtStakeAdd;

        IERC20 courtTokenERC20 = IERC20(address(courtToken));

        courtTokenERC20.approve(courtStakeAdd, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

        emit CourtStakeChanged(oldAddress, courtStakeAdd);
    }

    function rewards(address account) public view returns (uint256 reward, uint256 incvReward) {
        // read version of update
        uint256 cnBlock = blockNumber();
        
        uint256 incvAccRewardPerToken = _incvAccRewardPerToken;

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (_totalStaked > 0) {
            
            uint256 incvLastRewardBlock = cnBlock < incvFinishBlock ? cnBlock : incvFinishBlock;
            if (incvLastRewardBlock > _lastUpdateBlock) {
                incvAccRewardPerToken = incvLastRewardBlock.sub(_lastUpdateBlock)
                .mul(_incvRewardPerBlock).div(_totalStaked)
                .add(incvAccRewardPerToken);
            }
        }

        incvReward = _balances[account]
        .mul(incvAccRewardPerToken.sub(_incvPrevAccRewardPerToken[account]))
        .div(1e18)
        .add(_incvRewards[account])
        .sub(incvWithdrawn[account]);
        
        reward = 0;
    }

    function incvRewardInfo() external view returns (uint256 cBlockNumber, uint256 incvRewardPerBlock, uint256 incvRewardFinishBlock, uint256 incvRewardFinishTime, uint256 incvRewardLockTime) {
        cBlockNumber = blockNumber();
        incvRewardFinishBlock = incvFinishBlock;
        incvRewardPerBlock = _incvRewardPerBlock.div(1e18);
        if( cBlockNumber < incvFinishBlock){
            incvRewardFinishTime = block.timestamp.add(incvFinishBlock.sub(cBlockNumber).mul(15));
        }else{
            incvRewardFinishTime = block.timestamp.sub(cBlockNumber.sub(incvFinishBlock).mul(15));
        }
        incvRewardLockTime=incvStartReleasingTime;
    }


    // expected reward,
    // please note this is only expectation, because total balance may changed during the day
    function expectedRewardsToday(uint256 amount) external view returns (uint256 reward, uint256 incvReward) {
        reward = 0;
        uint256 totalIncvRewardPerDay = _incvRewardPerBlock * 5760;
        incvReward =  totalIncvRewardPerDay.div(_totalStaked.add(amount)).mul(amount).div(1e18);
    }

    function lastUpdateBlock() external view returns(uint256) {
        return _lastUpdateBlock;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function blockNumber() public view returns (uint256) {
       return block.number;
    }
    
    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    
    function getVestedAmount(uint256 lockedAmount, uint256 time) internal  view returns(uint256){
        
        // if time < StartReleasingTime: then return 0
        if(time < incvStartReleasingTime){
            return 0;
        }

        // if locked amount 0 return 0
        if (lockedAmount == 0){
            return 0;
        }

        // elapsedBatchCount = ((time - startReleasingTime) / batchPeriod) + 1
        uint256 elapsedBatchCount =
        time.sub(incvStartReleasingTime)
        .div(incvBatchPeriod)
        .add(1);

        // vestedAmount = lockedAmount  * elapsedBatchCount / batchCount
        uint256  vestedAmount =
        lockedAmount
        .mul(elapsedBatchCount)
        .div(incvBatchCount);

        if(vestedAmount > lockedAmount){
            vestedAmount = lockedAmount;
        }

        return vestedAmount;
    }
    
    
    function incvRewardClaim() public returns(uint256 amount){
        updateReward(msg.sender);
        amount = getVestedAmount(_incvRewards[msg.sender], getCurrentTime()).sub(incvWithdrawn[msg.sender]);
        
        if(amount > 0){
            incvWithdrawn[msg.sender] = incvWithdrawn[msg.sender].add(amount);

            courtToken.mint(msg.sender, amount);

            emit ClaimIncentiveReward(msg.sender, amount);
        }
    }
    
    function getBeneficiaryInfo(address ibeneficiary) external view
    returns(address beneficiary,
        uint256 totalLocked,
        uint256 withdrawn,
        uint256 releasableAmount,
        uint256 nextBatchTime,
        uint256 currentTime){

        beneficiary = ibeneficiary;
        currentTime = getCurrentTime();
        
        totalLocked = _incvRewards[ibeneficiary];
        withdrawn = incvWithdrawn[ibeneficiary];
        ( , uint256 incvReward) = rewards(ibeneficiary);
        releasableAmount = getVestedAmount(incvReward, getCurrentTime()).sub(incvWithdrawn[beneficiary]);
        nextBatchTime = getIncNextBatchTime(incvReward, ibeneficiary, currentTime);
        
    }
    
    function getIncNextBatchTime(uint256 lockedAmount, address beneficiary, uint256 time) internal view returns(uint256){

        // if total vested equal to total locked then return 0
        if(getVestedAmount(lockedAmount, time) == _incvRewards[beneficiary]){
            return 0;
        }

        // if time less than startReleasingTime: then return sartReleasingTime
        if(time <= incvStartReleasingTime){
            return incvStartReleasingTime;
        }

        // find the next batch time
        uint256 elapsedBatchCount =
        time.sub(incvStartReleasingTime)
        .div(incvBatchPeriod)
        .add(1);

        uint256 nextBatchTime =
        elapsedBatchCount
        .mul(incvBatchPeriod)
        .add(incvStartReleasingTime);

        return nextBatchTime;

    }
    
}