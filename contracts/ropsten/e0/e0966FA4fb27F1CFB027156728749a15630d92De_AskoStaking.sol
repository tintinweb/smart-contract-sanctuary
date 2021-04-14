/**
 *Submitted for verification at Etherscan.io on 2020-08-09
 */

pragma solidity 0.5.16;

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
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

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
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
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
contract Context is Initializable {
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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

    uint256[50] private ______gap;
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

library BasisPoints {
    using SafeMath for uint256;

    uint256 private constant BASIS_POINTS = 10000;

    function mulBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function addBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

interface IStakeHandler {
    function handleStake(
        address staker,
        uint256 stakerDeltaValue,
        uint256 stakerFinalValue
    ) external;

    function handleUnstake(
        address staker,
        uint256 stakerDeltaValue,
        uint256 stakerFinalValue
    ) external;
}

contract AskoStaking is Initializable, Ownable {
    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 internal constant DISTRIBUTION_MULTIPLIER = 2**64;

    uint256 public stakingTaxBP;
    uint256 public unstakingTaxBP;
    IERC20 private askoToken;

    mapping(address => uint256) public stakeValue;
    mapping(address => int256) private stakerPayouts;

    uint256 public totalDistributions;
    uint256 public totalStaked;
    uint256 public totalStakers;
    uint256 private profitPerShare;
    uint256 private emptyStakeTokens; //These are tokens given to the contract when there are no stakers.

    IStakeHandler[] public stakeHandlers;
    uint256 public startTime;

    event OnDistribute(address sender, uint256 amountSent);
    event OnStake(address sender, uint256 amount, uint256 tax);
    event OnUnstake(address sender, uint256 amount, uint256 tax);
    event OnReinvest(address sender, uint256 amount, uint256 tax);
    event OnWithdraw(address sender, uint256 amount);

    modifier onlyAskoToken {
        require(
            msg.sender == address(askoToken),
            "Can only be called by AskoToken contract."
        );
        _;
    }

    modifier whenStakingActive {
        require(startTime != 0 && now > startTime, "Staking not yet started.");
        _;
    }

    function initialize(
        uint256 _stakingTaxBP,
        uint256 _ustakingTaxBP,
        address owner,
        IERC20 _askoToken
    ) public initializer {
        Ownable.initialize(msg.sender);
        stakingTaxBP = _stakingTaxBP;
        unstakingTaxBP = _ustakingTaxBP;
        askoToken = _askoToken;
        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function stake(uint256 amount) public whenStakingActive {
        require(amount >= 1e18, "Must stake at least one ASKO.");
        require(
            askoToken.balanceOf(msg.sender) >= amount,
            "Cannot stake more ASKO than you hold unstaked."
        );
        if (stakeValue[msg.sender] == 0) totalStakers = totalStakers.add(1);
        uint256 tax = _addStake(amount);
        require(
            askoToken.transferFrom(msg.sender, address(this), amount),
            "Stake failed due to failed transfer."
        );
        emit OnStake(msg.sender, amount, tax);
    }

    function unstake(uint256 amount) public whenStakingActive {
        require(amount >= 1e18, "Must unstake at least one ASKO.");
        require(
            stakeValue[msg.sender] >= amount,
            "Cannot unstake more ASKO than you have staked."
        );
        uint256 tax = findTaxAmount(amount, unstakingTaxBP);
        uint256 earnings = amount.sub(tax);
        if (stakeValue[msg.sender] == amount)
            totalStakers = totalStakers.sub(1);
        totalStaked = totalStaked.sub(amount);
        stakeValue[msg.sender] = stakeValue[msg.sender].sub(amount);
        uint256 payout =
            profitPerShare.mul(amount).add(tax.mul(DISTRIBUTION_MULTIPLIER));
        stakerPayouts[msg.sender] =
            stakerPayouts[msg.sender] -
            uintToInt(payout);
        for (uint256 i = 0; i < stakeHandlers.length; i++) {
            stakeHandlers[i].handleUnstake(
                msg.sender,
                amount,
                stakeValue[msg.sender]
            );
        }
        _increaseProfitPerShare(tax);
        require(
            askoToken.transferFrom(address(this), msg.sender, earnings),
            "Unstake failed due to failed transfer."
        );
        emit OnUnstake(msg.sender, amount, tax);
    }

    function withdraw(uint256 amount) public whenStakingActive {
        require(
            dividendsOf(msg.sender) >= amount,
            "Cannot withdraw more dividends than you have earned."
        );
        stakerPayouts[msg.sender] =
            stakerPayouts[msg.sender] +
            uintToInt(amount.mul(DISTRIBUTION_MULTIPLIER));
        askoToken.transfer(msg.sender, amount);
        emit OnWithdraw(msg.sender, amount);
    }

    function reinvest(uint256 amount) public whenStakingActive {
        require(
            dividendsOf(msg.sender) >= amount,
            "Cannot reinvest more dividends than you have earned."
        );
        uint256 payout = amount.mul(DISTRIBUTION_MULTIPLIER);
        stakerPayouts[msg.sender] =
            stakerPayouts[msg.sender] +
            uintToInt(payout);
        uint256 tax = _addStake(amount);
        emit OnReinvest(msg.sender, amount, tax);
    }

    function distribute(uint256 amount) public {
        require(
            askoToken.balanceOf(msg.sender) >= amount,
            "Cannot distribute more ASKO than you hold unstaked."
        );
        totalDistributions = totalDistributions.add(amount);
        _increaseProfitPerShare(amount);
        require(
            askoToken.transferFrom(msg.sender, address(this), amount),
            "Distribution failed due to failed transfer."
        );
        emit OnDistribute(msg.sender, amount);
    }

    function handleTaxDistribution(uint256 amount) public onlyAskoToken {
        totalDistributions = totalDistributions.add(amount);
        _increaseProfitPerShare(amount);
        emit OnDistribute(msg.sender, amount);
    }

    function dividendsOf(address staker) public view returns (uint256) {
        return
            uint256(
                uintToInt(profitPerShare.mul(stakeValue[staker])) -
                    stakerPayouts[staker]
            )
                .div(DISTRIBUTION_MULTIPLIER);
    }

    function findTaxAmount(uint256 value, uint256 taxBP)
        public
        pure
        returns (uint256)
    {
        return value.mulBP(taxBP);
    }

    function numberStakeHandlersRegistered() public view returns (uint256) {
        return stakeHandlers.length;
    }

    function registerStakeHandler(IStakeHandler sc) public onlyOwner {
        stakeHandlers.push(sc);
    }

    function unregisterStakeHandler(uint256 index) public onlyOwner {
        IStakeHandler sc = stakeHandlers[stakeHandlers.length - 1];
        stakeHandlers.pop();
        stakeHandlers[index] = sc;
    }

    function setStakingBP(uint256 valueBP) public onlyOwner {
        require(valueBP < 10000, "Tax connot be over 100% (10000 BP)");
        stakingTaxBP = valueBP;
    }

    function setUnstakingBP(uint256 valueBP) public onlyOwner {
        require(valueBP < 10000, "Tax connot be over 100% (10000 BP)");
        unstakingTaxBP = valueBP;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function uintToInt(uint256 val) internal pure returns (int256) {
        if (val >= uint256(-1).div(2)) {
            require(false, "Overflow. Cannot convert uint to int.");
        } else {
            return int256(val);
        }
    }

    function _addStake(uint256 amount) internal returns (uint256 tax) {
        tax = findTaxAmount(amount, stakingTaxBP);
        uint256 stakeAmount = amount.sub(tax);
        totalStaked = totalStaked.add(stakeAmount);
        stakeValue[msg.sender] = stakeValue[msg.sender].add(stakeAmount);
        for (uint256 i = 0; i < stakeHandlers.length; i++) {
            stakeHandlers[i].handleStake(
                msg.sender,
                stakeAmount,
                stakeValue[msg.sender]
            );
        }
        uint256 payout = profitPerShare.mul(stakeAmount);
        stakerPayouts[msg.sender] =
            stakerPayouts[msg.sender] +
            uintToInt(payout);
        _increaseProfitPerShare(tax);
    }

    function _increaseProfitPerShare(uint256 amount) internal {
        if (totalStaked != 0) {
            if (emptyStakeTokens != 0) {
                amount = amount.add(emptyStakeTokens);
                emptyStakeTokens = 0;
            }
            profitPerShare = profitPerShare.add(
                amount.mul(DISTRIBUTION_MULTIPLIER).div(totalStaked)
            );
        } else {
            emptyStakeTokens = emptyStakeTokens.add(amount);
        }
    }
}

contract AskoStakingRewardPool is Initializable, IStakeHandler, Ownable {
    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public releaseBP;
    uint256 public releaseInterval;
    uint256 public cycleStart;
    IERC20 private askoToken;
    AskoStaking private askoStaking;

    mapping(address => bool) public isStakerRegistered;
    mapping(uint256 => mapping(address => uint256))
        public cycleStakerPoolOwnership;
    mapping(uint256 => mapping(address => uint256)) public cycleStakerClaimed;
    mapping(uint256 => uint256) public cyclePoolTotal;

    uint256 public reservedForClaims;
    uint256 public lastCycleSetReservedForClaims;
    mapping(uint256 => uint256) public cycleTotalReward;

    event OnClaim(address sender, uint256 payout);
    event OnRegister(address sender);

    modifier onlyFromAskoStaking {
        require(
            msg.sender == address(askoStaking),
            "Sender must be AskoStaking sc."
        );
        _;
    }

    modifier onlyAfterStart {
        require(cycleStart != 0 && now > cycleStart, "Has not yet started.");
        _;
    }

    function handleStake(
        address staker,
        uint256 stakerDeltaValue,
        uint256 stakeValue
    ) external onlyFromAskoStaking {
        if (!isStakerRegistered[staker]) return;
        uint256 currentCycle = getCurrentCycleCount();
        _updateReservedForClaims(currentCycle);
        _updateStakerPoolOwnershipNextCycle(currentCycle, staker, stakeValue);
    }

    function handleUnstake(
        address staker,
        uint256 stakerDeltaValue,
        uint256 stakeValue
    ) external onlyFromAskoStaking {
        if (!isStakerRegistered[staker]) return;
        uint256 currentCycle = getCurrentCycleCount();
        _updateReservedForClaims(currentCycle);
        _updateStakerPoolOwnershipNextCycle(currentCycle, staker, stakeValue);
        _updateStakerPoolOwnershipCurrentCycle(
            currentCycle,
            staker,
            stakeValue
        );
    }

    function initialize(
        uint256 _releaseBP,
        uint256 _releaseInterval,
        uint256 _cycleStart,
        address _owner,
        IERC20 _askoToken,
        AskoStaking _askoStaking
    ) public initializer {
        Ownable.initialize(msg.sender);

        releaseBP = _releaseBP;
        releaseInterval = _releaseInterval;
        cycleStart = _cycleStart;
        askoToken = _askoToken;
        askoStaking = _askoStaking;

        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(_owner);
    }

    function register() public {
        isStakerRegistered[msg.sender] = true;

        uint256 currentCycle = getCurrentCycleCount();

        _updateReservedForClaims(currentCycle);
        _updateStakerPoolOwnershipNextCycle(
            currentCycle,
            msg.sender,
            askoStaking.stakeValue(msg.sender)
        );

        emit OnRegister(msg.sender);
    }

    function claim(uint256 requestCycle) public onlyAfterStart {
        uint256 currentCycle = getCurrentCycleCount();
        uint256 payout = calculatePayout(msg.sender, currentCycle);

        _updateReservedForClaims(currentCycle);
        _updateStakerPoolOwnershipNextCycle(
            currentCycle,
            msg.sender,
            askoStaking.stakeValue(msg.sender)
        );
        _updateClaimReservations(
            currentCycle,
            requestCycle,
            payout,
            msg.sender
        );

        askoToken.transfer(msg.sender, payout);

        emit OnClaim(msg.sender, payout);
    }

    function setReleaseBP(uint256 _releaseBP) public onlyOwner {
        releaseBP = _releaseBP;
    }

    function setStartTime(uint256 _cycleStart) public onlyOwner {
        cycleStart = _cycleStart;
    }

    function calculatePayout(address staker, uint256 cycle)
        public
        view
        returns (uint256)
    {
        if (!isStakerRegistered[staker]) return 0;
        if (cycleStakerClaimed[cycle][staker] != 0) return 0;
        if (cycleTotalReward[cycle] == 0) return 0;

        uint256 cycleTotalPool = cyclePoolTotal[cycle];
        uint256 stakerPoolOwnership = cycleStakerPoolOwnership[cycle][staker];
        uint256 totalReward = cycleTotalReward[cycle];

        if (cycleTotalPool == 0) return 0;
        return totalReward.mul(stakerPoolOwnership).div(cycleTotalPool);
    }

    function getCurrentCycleCount() public view returns (uint256) {
        if (now <= cycleStart) return 0;
        return now.sub(cycleStart).div(releaseInterval).add(1);
    }

    function _updateReservedForClaims(uint256 currentCycle) internal {
        uint256 nextCycle = currentCycle.add(1);
        if (nextCycle <= lastCycleSetReservedForClaims) return;

        lastCycleSetReservedForClaims = nextCycle;

        uint256 newlyReservedAsko =
            askoToken.balanceOf(address(this)).sub(reservedForClaims).mulBP(
                releaseBP
            );
        reservedForClaims = reservedForClaims.add(newlyReservedAsko);
        cycleTotalReward[nextCycle] = newlyReservedAsko;
    }

    function _updateClaimReservations(
        uint256 currentCycle,
        uint256 requestCycle,
        uint256 payout,
        address claimer
    ) internal {
        require(
            isStakerRegistered[claimer],
            "Must register to be eligble for rewards."
        );
        require(
            requestCycle > 0,
            "Cannot claim for tokens staked before first cycle starts."
        );
        require(
            currentCycle > requestCycle,
            "Can only claim for previous cycles."
        );
        require(
            cycleStakerPoolOwnership[requestCycle][claimer] > 0,
            "Must have pool ownership for cycle."
        );
        require(
            cycleStakerClaimed[requestCycle][claimer] == 0,
            "Must not have claimed for cycle."
        );
        require(payout > 0, "Payout must be greater than 0.");
        cycleStakerClaimed[requestCycle][claimer] = payout;
        reservedForClaims = reservedForClaims.sub(payout);
    }

    function _updateStakerPoolOwnershipNextCycle(
        uint256 currentCycle,
        address staker,
        uint256 stakeValue
    ) internal {
        uint256 nextCycle = currentCycle.add(1);
        uint256 currentStakerPoolOwnership =
            cycleStakerPoolOwnership[nextCycle][staker];
        cyclePoolTotal[nextCycle] = cyclePoolTotal[nextCycle]
            .sub(currentStakerPoolOwnership)
            .add(stakeValue);
        cycleStakerPoolOwnership[nextCycle][staker] = stakeValue;
    }

    function _updateStakerPoolOwnershipCurrentCycle(
        uint256 currentCycle,
        address staker,
        uint256 stakeValue
    ) internal {
        uint256 currentStakerPoolOwnership =
            cycleStakerPoolOwnership[currentCycle][staker];
        if (stakeValue >= currentStakerPoolOwnership) return; //lowest balance is used
        cyclePoolTotal[currentCycle] = cyclePoolTotal[currentCycle]
            .sub(currentStakerPoolOwnership)
            .add(stakeValue);
        cycleStakerPoolOwnership[currentCycle][staker] = stakeValue;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}