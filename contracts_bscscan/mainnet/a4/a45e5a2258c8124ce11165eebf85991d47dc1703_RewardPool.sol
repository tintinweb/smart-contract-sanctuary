/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;
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
    address private _owner;

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
    function owner() external view returns (address) {
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

contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward1, uint256 reward2,uint256 reward3) external;

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            "Caller is not reward distribution"
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        require(
            _rewardDistribution != address(0),
            "Reward Distribution is the zero address"
        );
        rewardDistribution = _rewardDistribution;
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

contract TokenWrapper is Ownable{
    using SafeMath for uint256;

    IERC20 public LPToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setLPToken(IERC20 _lpToken)external onlyOwner{
        LPToken = _lpToken;
    }

    function stake(uint256 amount) public {
        require(LPToken.transferFrom(msg.sender, address(this), amount), "stake transfer failed");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }

    function withdraw(uint256 amount) public {
        require(LPToken.transfer(msg.sender, amount),'Withdraw failed');

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
    }
}

contract RewardPool is TokenWrapper, IRewardDistributionRecipient {
    IERC20 public MainToken;
    IERC20 public MainToken2;
    IERC20 public MainToken3;

    uint256 public DURATION;
    uint256 public startingBlock;
    uint256 public periodFinish = 0;
    
    uint256 public rewardRate = 0;
    uint256 public rewardRate2 = 0;
    uint256 public rewardRate3 = 0;

    uint256 public lastUpdateTime;
    uint256 public lastUpdateTime2;
    uint256 public lastUpdateTime3;    
    
    uint256 public rewardPerTokenStored;
    uint256 public rewardPerTokenStored2;
    uint256 public rewardPerTokenStored3;
  
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public userRewardPerTokenPaid3;
  
    
    mapping(address => uint256) public rewards;
    mapping(address=>uint256) public rewards2;
    mapping(address=>uint256) public rewards3;

    mapping(address => uint256) public _stakedTime;
    uint256 public delayToWithdraw = 7 days;

    event RewardAdded(uint256 reward1,uint256 reward2,uint256 reward3);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

  modifier startingCheck(){
         require(block.number> startingBlock, 'Staking not started');_;
  }
//////////////////////////////////////////////////////////////////////////
    modifier updateReward(address account) {
     
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    modifier updateReward2(address account) {
     
        rewardPerTokenStored2 = rewardPerToken2();
        lastUpdateTime2 = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid2[account] = rewardPerTokenStored2;
        }
        _;
    }

    modifier updateReward3(address account) {
     
        rewardPerTokenStored3 = rewardPerToken3();
        lastUpdateTime3 = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards3[account] = earned3(account);
            userRewardPerTokenPaid3[account] = rewardPerTokenStored3;
        }
        _;
    }

////////////////////////////////////////////////////////////////////////////
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }
/////////////////////////////////////////////////////////////////////////////
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e8)
                    .div(totalSupply())
            );
    }
    function rewardPerToken2() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored2;
        }
        return
            rewardPerTokenStored2.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime2)
                    .mul(rewardRate2)
                    .mul(1e8)
                    .div(totalSupply())
            );
    }

    function rewardPerToken3() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored3;
        }
        return
            rewardPerTokenStored3.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime3)
                    .mul(rewardRate3)
                    .mul(1e8)
                    .div(totalSupply())
            );
    }
/////////////////////////////////////////////////////////////////////////////
    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e8)
                .add(rewards[account]);
    }
    
    function earned2(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account]))
                .div(1e8)
                .add(rewards2[account]);
    }

    function earned3(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken3().sub(userRewardPerTokenPaid3[account]))
                .div(1e8)
                .add(rewards3[account]);
    }

///////////////////////////////////////////////////////////////////////////
    function earnedTotal(address account) public view returns( uint256 [] memory total){
        
        total = new uint[](3);
        total[0] = earned(account);
        total[1] = earned2(account);
        total[2] = earned3(account);
            
    }
    
////////////////////////////////////////////////////////////////////////////
    function setMainToken(IERC20 _mainToken) external onlyOwner{
        require(_mainToken!=LPToken,"!Allowed");
        MainToken = _mainToken;
    }
    function setMainToken2(IERC20 _mainToken2) external onlyOwner{
        require(_mainToken2!=LPToken,"!Allowed");
        MainToken2 = _mainToken2;
    }  
    function setMainToken3(IERC20 _mainToken3) external onlyOwner{
        require(_mainToken3!=LPToken,"!Allowed");
        MainToken3 = _mainToken3;
    }  
//////////////////////////////////////////////////////////////////////////
      function setDuration(uint256 _days) external onlyOwner{
        DURATION = _days*24*60*60;
    }
    

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public startingCheck updateReward(msg.sender) updateReward2(msg.sender) updateReward3(msg.sender){
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
       _stakedTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) updateReward2(msg.sender) updateReward3(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(canWithdraw(msg.sender), 'trying to withdraw earlier');
        super.withdraw(amount);        

        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function withdrawAmount(uint256 amount) external {
        withdraw(amount);
        getReward();
    }

    function setStartingBlock(uint256 _block) external onlyOwner {
        startingBlock = _block;
    }

    function getReward() public updateReward(msg.sender) updateReward2(msg.sender) updateReward3(msg.sender){
        uint256 reward = earned(msg.sender);
        uint256 reward2 = earned2(msg.sender);
        uint256 reward3 = earned3(msg.sender);

        if (reward > 0) {
            rewards[msg.sender] = 0;
            MainToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            MainToken2.transfer(msg.sender, reward2);
            emit RewardPaid(msg.sender, reward2);
        }
        if (reward3 > 0) {
            rewards3[msg.sender] = 0;
            MainToken3.transfer(msg.sender, reward3);
            emit RewardPaid(msg.sender, reward3);
        }
    }

    function notifyRewardAmount(uint256 reward, uint256 reward2,uint256 reward3)
        external
        onlyRewardDistribution
        updateReward(address(0))
        updateReward2(address(0))
        updateReward3(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
            rewardRate2 = reward2.div(DURATION);
            rewardRate3 = reward3.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            uint256 leftover2 = remaining.mul(rewardRate2);
            uint256 leftover3 = remaining.mul(rewardRate3);
            rewardRate = reward.add(leftover).div(DURATION);
            rewardRate2 = reward2.add(leftover2).div(DURATION);
            rewardRate3 = reward3.add(leftover3).div(DURATION);


        }
        lastUpdateTime = block.timestamp;
        lastUpdateTime2 = block.timestamp;
        lastUpdateTime3 = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward,reward2,reward3);
    }

    // only when emergency withdraw
    function withdrawMainToken(uint256 amount) external onlyRewardDistribution {
        require(MainToken.balanceOf(address(this)) > amount, "amount exceeds");
        rewardRate = 0;
        periodFinish = 0;
        MainToken.transfer(msg.sender, amount);
    }
        // only when emergency withdraw
    function withdrawMainToken2(uint256 amount) external onlyRewardDistribution {
        require(MainToken2.balanceOf(address(this)) > amount, "amount exceeds");
        rewardRate2 = 0;
        periodFinish = 0;
        MainToken2.transfer(msg.sender, amount);
    }
        function withdrawMainToken3(uint256 amount) external onlyRewardDistribution {
        require(MainToken3.balanceOf(address(this)) > amount, "amount exceeds");
        rewardRate3 = 0;
        periodFinish = 0;
        MainToken3.transfer(msg.sender, amount);
    }

    function stakedTime(address account) public view returns (uint256) {
        return _stakedTime[account];
    }

    function canWithdraw(address account) public view returns (bool) {
        if(_stakedTime[account]==0){
            return false;
        }
        else if(_stakedTime[account]+ delayToWithdraw < block.timestamp){
            return true;
        }
        return false;
    }

    function setDelayToWithdraw(uint256 _delayToWithdraw)external onlyOwner{
        delayToWithdraw = _delayToWithdraw;
    }
}