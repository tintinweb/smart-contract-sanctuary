/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity 0.5.16;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/GSN/Context.sol
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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



// File: @openzeppelin/contracts/math/SafeMath.sol

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash =
        0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
    internal
    pure
    returns (address payable)
    {
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}



contract MEYield    is Context, Ownable {
    using SafeMath for uint256;
    IERC20 public EarnToken ;
    IERC20 public StakeToken ;
    uint256 public minStake =0;
    uint256 public ReleasedTotal = 310*10000*(1e18);
    uint256 public ReleaseToday = 12530*(1e18);
    uint256 public PRECISION_FACTOR = 1e18;


    uint256 public Period = 28800;  // 1day eaual 86400secs or 28800 blocks
    uint256 public Withdraw7 = 0;           //7days equal to 604800    seconds
    uint256 public Withdraw30 = 0;         //30days equal to 2592000  seconds
    uint256 public Withdraw90 = 0;         //90days equal to 7776000  seconds
    uint256 public Withdraw360 = 0;      //360days equal to 31104000 seconds
    
    uint256 public lastRewardBlock7days = 0 ;
    uint256 public lastRewardBlock30days = 0 ;
    uint256 public lastRewardBlock90days = 0 ;
    uint256 public lastRewardBlock360days = 0 ;

    uint256 public accTokenPerShare7 = 0;
    uint256 public accTokenPerShare30 = 0;
    uint256 public accTokenPerShare90 = 0;
    uint256 public accTokenPerShare360 = 0;
    
    uint256 public totalStaked7days=0;
    uint256 public totalStaked30days=0;
    uint256 public totalStaked90days=0;
    uint256 public totalStaked360days=0;
    uint256 stakedTokenSupply = totalStaked7days.add(totalStaked30days).add(totalStaked90days).add(totalStaked360days);

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;


    struct UserInfo {
        uint256 amount7;// How many staked tokens the user has provided
        uint256 amount30;
        uint256 amount90;
        uint256 amount360;
        

        uint256 earned7;
        uint256 earned30;
        uint256 earned90;
        uint256 earned360;

        uint256 rewardDebt7; // Reward debt 7 days
        uint256 rewardDebt30; // Reward debt 30 days
        uint256 rewardDebt90; // Reward debt 90 days
        uint256 rewardDebt360; // Reward debt 360 days

    }
    
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);



    constructor(IERC20 _mainToken, IERC20 _lpToken, uint256 _minStake) public  {
        StakeToken = _lpToken;
        EarnToken = _mainToken;
        minStake = _minStake*(1e18);

    }


    modifier checkMinStake(uint256 amount) {
        require(amount >= minStake, "Is Not Correct Value");
        _;
    }


    function SetReleaseToday(uint256 _ReleaseToday) public onlyOwner{
        ReleaseToday = _ReleaseToday;
    }

    function SetMinStake(uint256 _minStake) public onlyOwner{
        minStake = _minStake.mul(1e18);
    }

    function GetTotalStakedTokenSupply() public view returns(uint256){
        
        return (totalStaked7days.add(totalStaked30days).add(totalStaked90days).add(totalStaked360days)); 
}

    function _getMultiplier(uint256 _from, uint256 _to) internal pure  returns (uint256) {
        return _to.sub(_from);
    }
    

    function GetRewardPerBlock7days() public view returns (uint256) {
        return (ReleaseToday.mul(100).div(630).div(28800));
    }
    
    function GetRewardPerBlock30days() public view returns (uint256) {
        return (ReleaseToday.mul(110).div(630).div(28800));
    }

    function GetRewardPerBlock90days() public view returns (uint256) {
        return (ReleaseToday.mul(120).div(630).div(28800));
    }
    
    function GetRewardPerBlock360days() public view returns (uint256) {
        return (ReleaseToday.mul(300).div(630).div(28800));
    }
    
    
     /*
     * @notice 7days Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool7days()  internal{

        
        uint256 multiplier = _getMultiplier(lastRewardBlock7days, block.number);
        uint256 EarnTokenReward = multiplier.mul(GetRewardPerBlock7days());
        //multiple 10000times to avoid the stake number is too small to count.

        accTokenPerShare7 = accTokenPerShare7.add(EarnTokenReward.mul(PRECISION_FACTOR).div(totalStaked7days));
//        accTokenPerShare30 = accTokenPerShare30.add(
//        accTokenPerShare90 = accTokenPerShare30.add(
//        accTokenPerShare360 = accTokenPerShare30.add(
        lastRewardBlock7days = block.number;
    }
  
     /*
     * @notice 30days Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool30days() internal {

        uint256 multiplier = _getMultiplier(lastRewardBlock30days, block.number);
        uint256 EarnTokenReward = multiplier.mul(GetRewardPerBlock30days());
        accTokenPerShare30 = accTokenPerShare30.add(EarnTokenReward.mul(PRECISION_FACTOR).div(totalStaked30days));
        lastRewardBlock30days = block.number;
    }
    
    /*
     * @notice 90days Update reward variables of the given pool to be up-to-date.
     */  
    function _updatePool90days() internal {
        uint256 multiplier = _getMultiplier(lastRewardBlock90days, block.number);
        uint256 EarnTokenReward = multiplier.mul(GetRewardPerBlock90days());
        accTokenPerShare90 = accTokenPerShare90.add(EarnTokenReward.mul(PRECISION_FACTOR).div(totalStaked90days));
        lastRewardBlock90days = block.number;
    }
    
    
    /*
     * @notice 360days Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool360days() internal {

        uint256 multiplier = _getMultiplier(lastRewardBlock360days, block.number);
        uint256 EarnTokenReward = multiplier.mul(GetRewardPerBlock360days());
        accTokenPerShare360 = accTokenPerShare360.add(EarnTokenReward.mul(PRECISION_FACTOR).div(totalStaked360days));
        lastRewardBlock360days = block.number;
    }  
    
    
    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function stake7(uint256 _amount) public checkMinStake(_amount) {
        require(_amount > 0, "Cannot stake 0");
        UserInfo storage user = userInfo[msg.sender];
        _updatePool7days();
        totalStaked7days = totalStaked7days.add(_amount);

        if (user.amount7 > 0) {
            uint256 pending = user.amount7.mul(accTokenPerShare7).div(PRECISION_FACTOR).sub(user.rewardDebt7);
            //already earned before this stake.
            if (pending > 0) {
                user.earned7 = pending.add(user.earned7);
            }
        }       
        

        user.amount7 = user.amount7.add(_amount);
        user.rewardDebt7 = user.amount7.mul(accTokenPerShare7).div(PRECISION_FACTOR);
        StakeToken.transferFrom(msg.sender, address(this), _amount);        
        emit Staked(msg.sender, _amount);
    }

    function stake30(uint256 _amount) public checkMinStake(_amount) {
        require(_amount > 0, "Cannot stake 0");
        UserInfo storage user = userInfo[msg.sender];
        _updatePool30days();
        totalStaked30days = totalStaked30days.add(_amount);

        if (user.amount30 > 0) {
            uint256 pending = user.amount30.mul(accTokenPerShare30).div(PRECISION_FACTOR).sub(user.rewardDebt30);
            //already earned before this stake.
            if (pending > 0) {
                user.earned30 = pending.add(user.earned30);
            }
        }       
        

        user.amount30 = user.amount30.add(_amount);
        user.rewardDebt30 = user.amount30.mul(accTokenPerShare30).div(PRECISION_FACTOR);
        StakeToken.transferFrom(msg.sender, address(this), _amount);        
        emit Staked(msg.sender, _amount);
    }    

    
    function stake90(uint256 _amount) public checkMinStake(_amount) {
        require(_amount > 0, "Cannot stake 0");
        UserInfo storage user = userInfo[msg.sender];
        _updatePool90days();
        totalStaked90days = totalStaked90days.add(_amount);

        if (user.amount90 > 0) {
            uint256 pending = user.amount90.mul(accTokenPerShare90).div(PRECISION_FACTOR).sub(user.rewardDebt90);
            //already earned before this stake.
            if (pending > 0) {
                user.earned90 = pending.add(user.earned90);
            }
        }  
        
        user.amount90 = user.amount90.add(_amount);
        user.rewardDebt90 = user.amount90.mul(accTokenPerShare90).div(PRECISION_FACTOR);

        StakeToken.transferFrom(msg.sender, address(this), _amount);        
        emit Staked(msg.sender, _amount);
    }
    
    function stake360(uint256 _amount) public checkMinStake(_amount) {
        require(_amount > 0, "Cannot stake 0");
        UserInfo storage user = userInfo[msg.sender];
        _updatePool360days();
        totalStaked360days = totalStaked360days.add(_amount);

        if (user.amount360 > 0) {
            user.earned360 = user.amount360.mul(accTokenPerShare360).div(PRECISION_FACTOR).sub(user.rewardDebt360).add(user.earned360);
            //already earned before this stake.
        }  
        user.amount360 = user.amount360.add(_amount);
        user.rewardDebt360 = user.amount360.mul(accTokenPerShare360).div(PRECISION_FACTOR);

        StakeToken.transferFrom(msg.sender, address(this), _amount);        
        emit Staked(msg.sender, _amount);
    }
    
     /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function SetWithdrawPeriod7(uint256 _from) public onlyOwner{
        Withdraw7 = _from;
    }
    
    function SetWithdrawPeriod30(uint256 _from) public onlyOwner{
        Withdraw30 = _from;
    }
    
    function SetWithdrawPeriod90(uint256 _from) public onlyOwner{
        Withdraw90 = _from;
    }
    function SetWithdrawPeriod360(uint256 _from) public onlyOwner{
        Withdraw360 = _from;
    }
    
    function withdraw7() external {
        UserInfo storage user = userInfo[msg.sender];
        require(Withdraw7 < block.timestamp, "still in lock time");
        require(Withdraw7.add(86400) > block.timestamp, "still in lock time");
        require(user.amount7 > 0, "no 7days pool stake");
        _updatePool7days();
      
    
        uint256 pending = user.amount7.mul(accTokenPerShare7).div(PRECISION_FACTOR).sub(user.rewardDebt7).add(user.earned7);
        StakeToken.transfer(address(msg.sender), user.amount7);
        EarnToken.transfer(address(msg.sender), pending);
        
        totalStaked7days = totalStaked7days.sub(user.amount7);
        user.amount7 = 0;
        user.earned7 = 0;
        user.rewardDebt7 = 0;
        emit Withdrawn(msg.sender, user.amount7);
        emit RewardPaid(msg.sender, pending);

    }
    



    function withdraw30() external {
        UserInfo storage user = userInfo[msg.sender];
        require(Withdraw30 < block.timestamp, "still in lock time");
        require(Withdraw30.add(86400) > block.timestamp, "still in lock time");
        require(user.amount30 > 0, "no 30days pool stake");
        _updatePool30days();
      
    
        uint256 pending = user.amount30.mul(accTokenPerShare30).div(PRECISION_FACTOR).sub(user.rewardDebt30).add(user.earned30);
        StakeToken.transfer(address(msg.sender), user.amount30);
        EarnToken.transfer(address(msg.sender), pending);
        
        totalStaked30days = totalStaked30days.sub(user.amount30);
        user.amount30 = 0;
        user.earned30 = 0;
        user.rewardDebt30 = 0;
        emit Withdrawn(msg.sender, user.amount30);
        emit RewardPaid(msg.sender, pending);

    }
    
    function withdraw90() external {
        UserInfo storage user = userInfo[msg.sender];

        require(Withdraw90 < block.timestamp, "still in lock time");
        require(Withdraw90.add(86400) > block.timestamp, "still in lock time");
        require(user.amount90 > 0, "no 90days pool stake");
        _updatePool90days();
      
    
        uint256 pending = user.amount90.mul(accTokenPerShare90).div(PRECISION_FACTOR).sub(user.rewardDebt90).add(user.earned90);
        StakeToken.transfer(address(msg.sender), user.amount90);
        EarnToken.transfer(address(msg.sender), pending);
        
        totalStaked90days = totalStaked90days.sub(user.amount90);
        user.amount90 = 0;
        user.earned90 = 0;
        user.rewardDebt90 = 0;
        emit Withdrawn(msg.sender, user.amount90);
        emit RewardPaid(msg.sender, pending);

    }
    function withdraw360() external {
        UserInfo storage user = userInfo[msg.sender];

        require(Withdraw360 < block.timestamp, "still in lock time");
        require(Withdraw360.add(86400) > block.timestamp, "still in lock time");
        require(user.amount360 > 0, "no 360days pool stake");
        _updatePool360days();
      
    
        uint256 pending = user.amount360.mul(accTokenPerShare360).div(PRECISION_FACTOR).sub(user.rewardDebt360).add(user.earned360);
        StakeToken.transfer(address(msg.sender), user.amount360);
        EarnToken.transfer(address(msg.sender), pending);
        
        totalStaked360days = totalStaked360days.sub(user.amount360);
        user.amount360 = 0;
        user.earned360 = 0;
        user.rewardDebt360 = 0;
        emit Withdrawn(msg.sender, user.amount360);
        emit RewardPaid(msg.sender, pending);

    }
    


    function  pendingreward(address _address) public view returns(uint256,uint256,uint256,uint256){
        UserInfo storage user = userInfo[_address];
        uint256 pending7 = user.amount7.mul(accTokenPerShare7).div(PRECISION_FACTOR).sub(user.rewardDebt7).add(user.earned7);
        uint256 pending30 = user.amount30.mul(accTokenPerShare30).div(PRECISION_FACTOR).sub(user.rewardDebt30).add(user.earned30);
        uint256 pending90 = user.amount90.mul(accTokenPerShare90).div(PRECISION_FACTOR).sub(user.rewardDebt90).add(user.earned90);
        uint256 pending360 = user.amount360.mul(accTokenPerShare360).div(PRECISION_FACTOR).sub(user.rewardDebt360).add(user.earned360);
        return (pending7,pending30,pending90,pending360);
        
    }

    function GetReward7(address _address) public view returns(uint256){

        UserInfo storage user = userInfo[_address];

        uint256 pending7 = user.amount7.mul(accTokenPerShare7).div(PRECISION_FACTOR).sub(user.rewardDebt7).add(user.earned7);
        
        return (pending7);
    }
    
    
    function GetReward30(address _address) public view returns(uint256){
        UserInfo storage user = userInfo[_address];

        uint256 pending30 = user.amount30.mul(accTokenPerShare30).div(PRECISION_FACTOR).sub(user.rewardDebt30).add(user.earned30);

        return (pending30);
    }
    function GetReward90(address _address) public view returns(uint256){
        UserInfo storage user = userInfo[_address];

        uint256 pending90 = user.amount90.mul(accTokenPerShare90).div(PRECISION_FACTOR).sub(user.rewardDebt90).add(user.earned90);

        return (pending90);
    }
    
    
    function GetReward360(address _address) public view returns(uint256){
        UserInfo storage user = userInfo[_address];

        uint256 pending360 = user.amount360.mul(accTokenPerShare360).div(PRECISION_FACTOR).sub(user.rewardDebt360).add(user.earned360);

        return (pending360);
    }
    
    function HarvestReward7() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending7 = user.amount7.mul(accTokenPerShare7).div(PRECISION_FACTOR).sub(user.rewardDebt7).add(user.earned7);

        EarnToken.transfer(address(msg.sender), pending7);
        user.rewardDebt7 = user.amount7.mul(accTokenPerShare7).div(PRECISION_FACTOR);
        user.earned7 = 0;
        emit RewardPaid(msg.sender, pending7);
    }

    function HarvestReward30() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending30 = user.amount30.mul(accTokenPerShare30).div(PRECISION_FACTOR).sub(user.rewardDebt30).add(user.earned30);

        EarnToken.transfer(address(msg.sender), pending30);
        user.rewardDebt30 = user.amount30.mul(accTokenPerShare30).div(PRECISION_FACTOR);
        user.earned30 = 0;
        emit RewardPaid(msg.sender, pending30);
    }  
 
    function HarvestReward90() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending90 = user.amount90.mul(accTokenPerShare90).div(PRECISION_FACTOR).sub(user.rewardDebt90).add(user.earned90);

        EarnToken.transfer(address(msg.sender), pending90);
        user.rewardDebt90 = user.amount90.mul(accTokenPerShare90).div(PRECISION_FACTOR);
        user.earned90 = 0;
        emit RewardPaid(msg.sender, pending90);
    }      
    
    function HarvestReward360() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending360 = user.amount360.mul(accTokenPerShare360).div(PRECISION_FACTOR).sub(user.rewardDebt360).add(user.earned360);

        EarnToken.transfer(address(msg.sender), pending360);
        user.rewardDebt360 = user.amount360.mul(accTokenPerShare360).div(PRECISION_FACTOR);
        user.earned360 = 0;
        emit RewardPaid(msg.sender, pending360);
    }      
    
    function GetMyStake7() public view returns(uint256){
        UserInfo storage user = userInfo[msg.sender];
        return user.amount7;

    }
    function GetMyStake30() public view returns(uint256){
        UserInfo storage user = userInfo[msg.sender];
        return user.amount30;

    }
    function GetMyStake90() public view returns(uint256){
        UserInfo storage user = userInfo[msg.sender];
        return user.amount90;

    } 
    function GetMyStake360() public view returns(uint256){
        UserInfo storage user = userInfo[msg.sender];
        return user.amount360;

    }  
    
    function exit() external onlyOwner {
        EarnToken.transfer(_owner, EarnToken.balanceOf(address(this)));

    }

    function withdrawEarnTokens(uint256 amount) external onlyOwner {
        require(EarnToken.balanceOf(address(this)) >= amount, "amount exceeds");
        EarnToken.transfer(_owner, amount);
    }
    
    
    
}