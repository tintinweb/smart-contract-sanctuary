/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.0;

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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

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

// File: contracts\Ownable.sol

pragma solidity ^0.5.10;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\DreamStakePool.sol

pragma solidity ^0.5.10;




interface ITokenRewardPool {
 
    function stake (address account, uint256 amount) external returns (bool);


    function Unstake (address account) external returns (bool);


    function claimReward (address account) external returns (bool);


    function emergencyTokenExit (address account) external returns (bool);


    function totalStakedAmount() external view returns (uint256);


    function stakedAmount(address account) external view returns (uint256);


    function rewardAmount(address account) external view returns (uint256);


    function beginRewardAmount() external view returns (uint256);


    function remainRewardAmount() external view returns (uint256);
	

    function ratePool() external view returns (uint256);


    function IsRunningPool() external view returns (bool);

}

contract TokenRewardPool is ITokenRewardPool{
    using SafeMath for uint256;
    bool private IS_RUNNING_POOL;

    uint256 private TOTAL_STAKED_AMOUNT; 
    uint256 private BEGIN_REWARD; 
    uint256 private REMAIN_REWARD; 
    uint256 private REWARD_RATE; 

    IERC20 private rewardToken; 
    IERC20 private stakeToken; 

    address private TEAM_POOL; 

    mapping (address => uint256) private USER_STAKED_AMOUNT; 
    mapping (address => uint256) private USER_REWARD; 
    mapping (address => bool) private IS_REGISTED;
    address[] private CONTRACT_LIST;
    mapping (address => uint256) private UPDATED_TIMESTAMP;

    event Stake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    mapping (address => uint256) private USER_STAKE_TIME; 

    constructor (
        uint256 _rewardRate, 
        address _rewardToken,
        address _stakeToken, 
        address _teamPool
    ) internal {
        rewardToken = IERC20(_rewardToken);
        stakeToken = IERC20(_stakeToken);
        REWARD_RATE = _rewardRate;
        TEAM_POOL = _teamPool;
        IS_RUNNING_POOL = false;
    }
    
    function stake (address account, uint256 amount) external returns (bool){

        require(IS_RUNNING_POOL == true, "The pool has ended.");
        require(amount > 0, "The pool has ended.");

        _registAddress(account); 
        // _updateReward(account); 
        _updateAllReward();

        if(UPDATED_TIMESTAMP[account] <= 0){
            UPDATED_TIMESTAMP[account] = block.timestamp;
        }
        
        USER_STAKE_TIME[account] = block.timestamp;
        
        stakeToken.transferFrom(account, address(this), amount); 

        USER_STAKED_AMOUNT[account] = USER_STAKED_AMOUNT[account].add(amount);

        TOTAL_STAKED_AMOUNT = TOTAL_STAKED_AMOUNT.add(amount);
        
        emit Stake(account, amount);
    }

    function Unstake (address account) external returns (bool){

        // _updateReward(account);
        _updateAllReward();

        if(USER_REWARD[account] > 0){
            uint256 rewards = USER_REWARD[account];
            USER_REWARD[account] = 0;
            rewardToken.transfer(account, rewards);
        }
        USER_STAKE_TIME[account] = 0;
      
        _stake_token_withdraw(account, USER_STAKED_AMOUNT[account]);
    }

    function claimReward (address account) external returns (bool){
        
        // _updateReward(account);
        _updateAllReward();

        require(USER_REWARD[account] > 0, "Nothing to claim");

        uint256 withrawAmount = USER_REWARD[account];
        USER_REWARD[account] = 0; 

        USER_STAKE_TIME[account] = block.timestamp; 

        rewardToken.transfer(account, withrawAmount);
    }

    function totalStakedAmount() external view returns (uint256){
        return TOTAL_STAKED_AMOUNT;
    }

    function stakedAmount(address account) external view returns (uint256){
        return USER_STAKED_AMOUNT[account];
    }

    function rewardAmount(address account) external view returns (uint256){
        return USER_REWARD[account];
    }

    function beginRewardAmount() external view returns (uint256){
         return BEGIN_REWARD;
    }

    function remainRewardAmount() external view returns (uint256){
         return REMAIN_REWARD;
    }
	
    function ratePool() external view returns (uint256){
        return REWARD_RATE;
    }

    function IsRunningPool() external view returns (bool){
        return IS_RUNNING_POOL;
    }

    function emergencyTokenExit (address account) external returns (bool){
        uint256 amount = USER_STAKED_AMOUNT[account];
        _stake_token_withdraw(account, amount);

        USER_STAKED_AMOUNT[account] = 0;
        USER_REWARD[account] = 0;

        emit EmergencyWithdraw(account, amount);
    }

   function _initPool() internal {

        BEGIN_REWARD = rewardToken.balanceOf(address(this));

        if(BEGIN_REWARD <= 0){
            return;
        }else{
            REMAIN_REWARD = BEGIN_REWARD;

            _setIsRunningPool(true);
        }
    }

    function _setIsRunningPool(bool _isRunningPool) internal {
        IS_RUNNING_POOL = _isRunningPool;
    }

    function _stake_token_withdraw (address host, uint256 amount) internal {

        require(USER_STAKED_AMOUNT[host] >= 0);

        USER_STAKED_AMOUNT[host] = USER_STAKED_AMOUNT[host].sub(amount);

        TOTAL_STAKED_AMOUNT = TOTAL_STAKED_AMOUNT.sub(amount);

        stakeToken.transfer(host, amount);
    }

    function _updateReward (address host) internal {

        uint256 elapsed = _elapsedBlock(UPDATED_TIMESTAMP[host]);
        
        if(elapsed <= 0){
            return;
        }
        
        uint256 stakeAmount = USER_STAKED_AMOUNT[host];
        if(stakeAmount <= 0){
            return;
        }
        UPDATED_TIMESTAMP[host] = block.timestamp;
        uint256 baseEarned = _calculateEarn(elapsed, stakeAmount);

        if(REMAIN_REWARD >= baseEarned){

            USER_REWARD[host] = baseEarned.mul(95).div(100).add(USER_REWARD[host]);
            USER_REWARD[TEAM_POOL] = baseEarned.mul(5).div(100).add(USER_REWARD[TEAM_POOL]);
            REMAIN_REWARD = REMAIN_REWARD.sub(baseEarned);
        }else{
            if(REMAIN_REWARD > 0){
                uint256 remainAll = REMAIN_REWARD;
                REMAIN_REWARD = 0;
                USER_REWARD[host] = remainAll.mul(95).div(100).add(USER_REWARD[host]);
                USER_REWARD[TEAM_POOL] = remainAll.mul(5).div(100).add(USER_REWARD[TEAM_POOL]);
     
            }
            _setIsRunningPool(false);
        }
    }

    function _elapsedBlock (uint256 updated) internal view returns (uint256) {
        uint256 open = updated; 
        uint256 close = block.timestamp; 
        return open >= close ? 0 : close - open;   
    }

    function _registAddress (address host) internal {
        if(IS_REGISTED[host]){return;}

        IS_REGISTED[host] = true;
        CONTRACT_LIST.push(host);
    }

    function _endPool(address owner) internal {
        _updateAllReward();

        //First User Stake & Reward withdraw
        for(uint256 i=0; i<CONTRACT_LIST.length; i++){
            address account = CONTRACT_LIST[i];
            if(USER_REWARD[account] > 0){
                uint256 rewards = USER_REWARD[account];
                USER_REWARD[account] = 0;
                rewardToken.transfer(account, rewards);
            }
            _stake_token_withdraw(account, USER_STAKED_AMOUNT[account]);
        }   

        //Second Team Reward withdraw
        if(TEAM_POOL != address(0)){
            if(USER_REWARD[TEAM_POOL] > 0){
                uint256 rewards = USER_REWARD[TEAM_POOL];
                USER_REWARD[TEAM_POOL] = 0;
                rewardToken.transfer(TEAM_POOL, rewards);
            }
        }

        //Third Owner saved reward withdraw
        uint256 endRewardAmount = rewardToken.balanceOf(address(this));
        if(endRewardAmount > 0){
            rewardToken.transfer(owner, endRewardAmount);
        }

        //Third End
        _setIsRunningPool(false);
    }

    function _updatePool() internal {
        _updateAllReward();
    }


    function rewordForSecond(address account) public view returns (uint256){
        uint256 stakeAmount = USER_STAKED_AMOUNT[account];
        if(stakeAmount <= 0){
            return 0;
        }

        uint256 oneYearReward = stakeAmount.mul(REWARD_RATE).div(100);
        uint256 oneDayReward = oneYearReward.div(365);
        uint256 oneTimesReward = oneDayReward.div(24);
        uint256 oneMinReward = oneTimesReward.div(60);
        uint256 oneSeconReward = oneMinReward.div(60);
        return oneSeconReward;        
    }

    function userReward(address account) public view returns (uint256){
       return USER_REWARD[account];
    }
    
    function teamPoolAddress() public view returns (address){
       return TEAM_POOL;
    }

    function _updateAllReward () internal {
        for(uint256 i=0; i<CONTRACT_LIST.length; i++){
            if(IS_RUNNING_POOL){
                _updateReward(CONTRACT_LIST[i]);
            }
        }
    }

    function _calculateEarn (uint256 elapsed, uint256 staked) internal view returns (uint256) {
        if(staked == 0){return 0;}
        
        if(elapsed <= 0){return 0;}

        uint256 oneYearReward = staked.mul(REWARD_RATE).div(100);
        uint256 oneDayReward = oneYearReward.div(365);
        uint256 oneTimesReward = oneDayReward.div(24);
        uint256 oneMinReward = oneTimesReward.div(60);
        uint256 oneSeconReward = oneMinReward.div(60);
        uint256 secondReward = oneSeconReward.mul(elapsed); // ?꾩옱 珥덈떦?댁옄
     
        return secondReward;
    }

    function _changeRewardRate (uint256 _rate) internal {
        _updateAllReward();
        REWARD_RATE = _rate;
    }

    function contractListCount () external view returns (uint256) {
        return CONTRACT_LIST.length;
    }
    
    function userStakeTime (address account) external view returns (uint256) {
        return USER_STAKE_TIME[account];
    }
    
}

contract FRIStakePool is Ownable, TokenRewardPool{
    
    string private name = "PoolName";
       
    constructor (   
        string memory _name,//Pool Name
        uint256 _rate, 
        address _rewardToken, 
        address _stakeToken, 
        address _teamPool) TokenRewardPool(_rate, _rewardToken, _stakeToken, _teamPool) onlyOwner public{
        name = _name;
    }

    function initTotalReward () public onlyOwner {
        _initPool();
    }

    function endPool() public onlyOwner {
          _endPool(owner());
    }

    function changeRewardRate (uint256 rate) public onlyOwner {
       _changeRewardRate(rate);
    }

    function updatePool () public onlyOwner {
       _updatePool();
    }  
}