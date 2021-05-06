/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.8.4;

abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    uint256[49] private __gap;
}

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract MbnStaking is Initializable, OwnableUpgradeable {
    using SafeMath for uint;

    uint private constant TIME_UNIT = 86400; //one day in seconds

    struct Package {
        uint daysLocked;
        uint daysBlocked;
        uint interest;
    }

    struct Stake {
        uint amount;
        uint timestamp;
        bytes32 packageName;
        uint withdrawnTimestamp;
    }

    struct Staker {
        Stake[] stakes;
        uint totalStakedBalance;
    }

    bool public paused;
    uint public totalStakedFunds;
    IERC20 public tokenContract;
    bytes32[] public packageNames;
    address[] public stakerAddresses;

    mapping(bytes32 => Package) public packages;
    mapping(address => Staker) public stakers;

    uint private rewardPool;

    event Paused();
    event Unpaused();
    event RewardAdded(address indexed _from, uint256 _amount);
    event RewardRemoved(address indexed _to, uint256 _val);
    event Unstaked(address indexed _staker, uint _stakeIndex);
    event ForcedUnstake(address indexed _staker, uint _stakeIndex);
    event StakeAdded(
        address indexed _staker, 
        bytes32 _packageName, 
        uint _amount, 
        uint _stakeIndex
    );

    // pseudo-constructor
    function initialize(address _tokenAddress) public initializer 
    {
        __Ownable_init();

        tokenContract = IERC20(_tokenAddress);

        createPackage("Silver Package", 30, 15, 8);
        createPackage("Gold Package", 60, 30, 18); 
        createPackage("Platinum Package", 90, 45, 30); 
    }

    function packageLength() external view returns (uint) {
        return packageNames.length;
    }

    function stakesLength(address _address) external view returns (uint) {
        return stakers[_address].stakes.length;
    }

    function renounceOwnership() public override onlyOwner {}

    function addTokensToRewardPool(uint256 _amount) public
    {
        rewardPool = rewardPool.add(_amount);
        tokenContract.transferFrom(msg.sender, address(this), _amount);

        emit RewardAdded(msg.sender, _amount);
    }

    function removeTokensFromRewardPool(uint256 _amount) public onlyOwner
    {
        require(_amount <= rewardPool, "You cannot withdraw more than reward pool size");

        rewardPool = rewardPool.sub(_amount);
        tokenContract.transfer(msg.sender, _amount);

        emit RewardRemoved(msg.sender, _amount);
    }

    function stakeTokens(uint _amount, bytes32 _packageName) public {
        require(paused == false, "Staking is paused");

        require(
            packages[_packageName].daysBlocked > 0,
            "there is no active staking package with that name"
        );

        if (stakers[msg.sender].stakes.length > 0) {
            stakerAddresses.push(msg.sender);
        }

        stakers[msg.sender].totalStakedBalance = 
            stakers[msg.sender].totalStakedBalance.add(_amount);

        Stake memory _newStake;
        _newStake.amount = _amount;
        _newStake.packageName = _packageName;
        _newStake.timestamp = block.timestamp;
        _newStake.withdrawnTimestamp = 0;

        stakers[msg.sender].stakes.push(_newStake);

        totalStakedFunds = totalStakedFunds.add(_amount);

        tokenContract.transferFrom(msg.sender, address(this), _amount);

        emit StakeAdded(
            msg.sender, 
            _packageName, 
            _amount, 
            stakers[msg.sender].stakes.length - 1
        );
    }

    function unstake(uint _stakeIndex) public {
        Stake storage _stake = getStakeForWithdrawal(_stakeIndex);

        uint _reward = checkReward(msg.sender, _stakeIndex);

        require(
            rewardPool >= _reward,
            "Token creators did not place enough liquidity in the contract for your reward to be paid"
        );

        totalStakedFunds = totalStakedFunds.sub(_stake.amount);

        stakers[msg.sender].totalStakedBalance = 
            stakers[msg.sender].totalStakedBalance.sub(_stake.amount);

        _stake.withdrawnTimestamp = block.timestamp;


        rewardPool = rewardPool.sub(_reward);

        uint _totalStake = _stake.amount.add(_reward);

        tokenContract.transfer(msg.sender, _totalStake);
        
        emit Unstaked(msg.sender, _stakeIndex);
    }

    function forceUnstake(uint _stakeIndex) public {
        Stake storage _stake = getStakeForWithdrawal(_stakeIndex);

        _stake.withdrawnTimestamp = block.timestamp;
        totalStakedFunds = totalStakedFunds.sub(_stake.amount);
        stakers[msg.sender].totalStakedBalance = 
            stakers[msg.sender].totalStakedBalance.sub(_stake.amount);

        tokenContract.transfer(msg.sender, _stake.amount);

        emit ForcedUnstake(msg.sender, _stakeIndex);
    }

    function pauseStaking() public onlyOwner 
    {
        if (!paused) {
            paused = true;
            emit Paused();
        }
    }

    function unpauseStaking() public onlyOwner 
    {
        if (paused) {
            paused = false;
            emit Unpaused();
        }
    }

    function checkReward(address _address, uint _stakeIndex)
        public
        view
        returns (uint _reward)
    {
        uint _currentTime = block.timestamp;
        Stake storage _stake = stakers[_address].stakes[_stakeIndex];
        Package storage _package = packages[_stake.packageName];

        if (_stake.withdrawnTimestamp != 0) {
            _currentTime = _stake.withdrawnTimestamp;
        }

        uint _stakingPeriod = _currentTime.sub(_stake.timestamp).div(TIME_UNIT);
        uint _packagePeriods = _stakingPeriod.div(_package.daysLocked);

        //this formula calculates the reward of the stake
        //I multiplied some variables with 1000 in order to have much more precision
        _reward = (_stake.amount * (1000 + 10 * _package.interest)**_packagePeriods).div(1000**_packagePeriods) - _stake.amount;
    }
    function createPackage(
        bytes32 _name,
        uint _days,
        uint _daysBlocked,
        uint _interest
    ) private {
        Package memory package;
        package.daysLocked = _days;
        package.interest = _interest;        
        package.daysBlocked = _daysBlocked;

        packages[_name] = package;
        packageNames.push(_name);
    }

    function getStakeForWithdrawal(uint _stakeIndex) private view
    returns (Stake storage  _stake) {
        require(
            _stakeIndex < stakers[msg.sender].stakes.length,
            "Undifened stake index"
        );

        _stake = stakers[msg.sender].stakes[_stakeIndex];

        require(_stake.withdrawnTimestamp == 0, "Stake already withdrawn");

        require(
            block.timestamp.sub(_stake.timestamp).div(TIME_UNIT) >
                packages[_stake.packageName].daysBlocked,
            "Cannot unstake sooner than the blocked time"
        );
    }
}