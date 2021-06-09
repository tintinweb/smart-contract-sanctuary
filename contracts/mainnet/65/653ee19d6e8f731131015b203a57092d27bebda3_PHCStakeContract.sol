/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.6.0;

// "SPDX-License-Identifier: MIT"


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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

contract PHCStakeContract is Ownable, Pausable {
    // Library for safely handling uint256
    using SafeMath for uint256;

    uint256 ONE_DAY;
    uint256 public stakeDays;
    uint256 public maxStakedQuantity;
    address public PhuketTokenAddress;
    uint256 public ratio;
    uint256 public totalStakedTokens;
    uint256 public FEE;
    address public fee_address;
    

    mapping(address => uint256) public stakerBalance;
    mapping(uint256 => StakerData) public stakerData;
    
    mapping (address => Storetime)  Storetimes; 
    mapping(address=>uint256) public laststake;
    
    struct Storetime {
        uint256[] invTime;
    }

    struct StakerData {
        uint256 altQuantity;
        uint256 initiationTimestamp;
        uint256 durationTimestamp;
        uint256 endTime;
        uint256 rewardAmount;
        address staker;
        uint256 exactdate;
        uint256 withdrawable;
        uint256 rewardAmountdata;
        bool isCompleted;
    }
    event StakeCompleted(
        uint256 altQuantity,
        uint256 initiationTimestamp,
        uint256 durationTimestamp,
        uint256 rewardAmount,
        address staker,
        address PhuketTokenAddress,
        address portalAddress
    );

    event Unstake(
        address staker,
        address stakedToken,
        address portalAddress,
        uint256 altQuantity,
        uint256 durationTimestamp,
        uint256 rewardAmount
    ); // When ERC20s are withdrawn
    event BaseInterestUpdated(uint256 _newRate, uint256 _oldRate);

    constructor(uint256 _ratio,address _phuketToken,uint256 _maxStkQty, address _feeaddress) public {
        ratio = _ratio;
        PhuketTokenAddress = _phuketToken;
        maxStakedQuantity = _maxStkQty;
        stakeDays = 365;
        ONE_DAY = 86400;
        FEE = 300;
        fee_address = _feeaddress;
    }
    
    function userInvesmentData(address _address) public view returns(uint256[] memory UserInv)
    {
        return Storetimes[_address].invTime;
    }
    
    function earnedReward(uint256 _id) public view returns(uint256)
    {
        uint256 rewardAmount;
         if(stakerData[_id].endTime <= block.timestamp){
             uint256 exactDays = (stakerData[_id].exactdate).mul(ONE_DAY);
              rewardAmount = _calculateReward(stakerData[_id].altQuantity, ratio, exactDays);
         }
         else
         {
             uint256 days_remaining = (block.timestamp).sub(stakerData[_id].initiationTimestamp);
             rewardAmount = _calculateReward(stakerData[_id].altQuantity, ratio, days_remaining);
         }
         return rewardAmount;
    }

    /* @dev stake function which enable the user to stake Phuket Tokens.
     *  @param _altQuantity, Phuket amount to be staked.
     *  @param _days, how many days Phuket tokens are staked for (in days)
     */
    function stakeALT(uint256 _altQuantity, uint256 _days)
        public
        whenNotPaused
        returns (uint256 rewardAmount)
    {
        require(_days <= stakeDays && _days > 0, "Invalid Days"); // To check days
        require(
            _altQuantity <= maxStakedQuantity && _altQuantity > 0,
            "Invalid Phuket quantity"
        ); // To verify Phuket quantity

        IERC20(PhuketTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _altQuantity
        );

        rewardAmount = 0;

        uint256 _timestamp = block.timestamp;

        if (stakerData[_timestamp].staker != address(0)) {
            _timestamp = _timestamp.add(1);
        }

        stakerData[_timestamp] = StakerData(
            _altQuantity,
            _timestamp,
            _days.mul(ONE_DAY),
            (_days.mul(ONE_DAY)).add(_timestamp),
            rewardAmount,
            msg.sender,
            _days.mul(1e18),
            0,
            0,
            false
        );

        stakerBalance[msg.sender] = stakerBalance[msg.sender].add(_altQuantity);

        totalStakedTokens = totalStakedTokens.add(_altQuantity);

        Storetimes[msg.sender].invTime.push(_timestamp);
        
        laststake[msg.sender]=_timestamp;

        emit StakeCompleted(
            _altQuantity,
            _timestamp,
            _days.mul(ONE_DAY),
            rewardAmount,
            msg.sender,
            PhuketTokenAddress,
            address(this)
        );
    }

    /*  @dev unStake function which enable the user to withdraw his Phuket Tokens.
     *  @param _expiredTimestamps, time when Phuket tokens are unlocked.
     *  @param _amount, amount to be withdrawn by the user.
     */
    function unstakeALT(uint256[] calldata _expiredTimestamps)
        external
        whenNotPaused
        returns (bool)
    {
    
        for (uint256 i = 0; i < _expiredTimestamps.length; i = i.add(1)) {
            
                uint256 withdrawAmount = 0;
                uint256 rewardAmount=0;
                uint256 timestamp = block.timestamp;
               
                 require(!(stakerData[_expiredTimestamps[i]].isCompleted),"Already Unstaked");
                 withdrawAmount =  stakerData[_expiredTimestamps[i]].altQuantity;
                 uint256 initiate_time = stakerData[_expiredTimestamps[i]].initiationTimestamp;
                  
             uint256 exactDays = (timestamp).sub(initiate_time);
             
               
        
                 rewardAmount = _calculateReward(withdrawAmount, ratio, exactDays);
                IERC20(PhuketTokenAddress).transfer(msg.sender, rewardAmount);
          

          stakerData[_expiredTimestamps[i]].withdrawable=withdrawAmount;
          
            stakerBalance[msg.sender] = stakerBalance[msg.sender].sub(withdrawAmount);

        totalStakedTokens = totalStakedTokens.sub(withdrawAmount);

        IERC20(PhuketTokenAddress).transfer(msg.sender, withdrawAmount);
                    
     
         emit Unstake( msg.sender,
                            PhuketTokenAddress,
                            address(this),
                            stakerData[_expiredTimestamps[i]].altQuantity,
                            _expiredTimestamps[i],
                            rewardAmount
                        );
        
        stakerData[_expiredTimestamps[i]].rewardAmountdata=rewardAmount;
        stakerData[_expiredTimestamps[i]].isCompleted=true;
    
    }
       
        
        return true;
    }

    /* @dev to calculate reward Amount
     *  @param _altQuantity , amount of ALT tokens staked.
     *@param _baseInterest rate
     */
    function _calculateReward(
        uint256 _altQuantity,
        uint256 _ratio,
        uint256 _days
    ) public view returns (uint256 rewardAmount) {
        rewardAmount = (_altQuantity.mul(_ratio).mul(_days)).div(1e18);
        rewardAmount = rewardAmount.div(ONE_DAY);
    }

   

    /* @dev to set base interest rate. Can only be called by owner
     *  @param _rate, interest rate (in wei)
     */
    function updateRatio(uint256 _rate) public onlyOwner whenNotPaused {
        ratio = _rate;
    }

    function updateTime(uint256 _time) public onlyOwner whenNotPaused {
        ONE_DAY = _time;
    }
    
    
     function updateFEE(uint256 _fee) public onlyOwner whenNotPaused {
        FEE = _fee;
    }
    
     function updateFeeaddress(address _feeaddress) public onlyOwner whenNotPaused {
        fee_address = _feeaddress;
    }

    function updateQuantity(uint256 _quantity) public onlyOwner whenNotPaused {
        maxStakedQuantity = _quantity;
    }

    /* @dev function to update stakeDays.
     *@param _stakeDays, updated Days .
     */
    function updatestakeDays(uint256 _stakeDays) public onlyOwner {
        stakeDays = _stakeDays;
    }

    /* @dev Funtion to withdraw all Phuket from contract incase of emergency, can only be called by owner.*/
    function withdrawTokens() public onlyOwner {
        IERC20(PhuketTokenAddress).transfer(
            owner(),
            IERC20(PhuketTokenAddress).balanceOf(address(this))
        );
        pause();
    }

    function getTotalrewardTokens() external view returns(uint256){
        return IERC20(PhuketTokenAddress).balanceOf(address(this)).sub(totalStakedTokens);
    }

    /* @dev function to update Phuket contract address.
     *@param _address, new address of the contract.
     */
    function setPhuketTokenAddress(address _address) public onlyOwner {
        PhuketTokenAddress = _address;
    }

    /* @dev function which restricts the user from stakng Phuket tokens. */
    function pause() public onlyOwner {
        _pause();
    }

    /* @dev function which disables the Pause function. */
    function unPause() public onlyOwner {
        _unpause();
    }
}