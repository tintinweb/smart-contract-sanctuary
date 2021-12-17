/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

// File: tests/Ownable.sol



pragma solidity 0.8.6;

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev `owner` defaults to msg.sender on construction.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
     *      Can only be invoked by the current `owner`.
     * @param _newOwner Address of the new owner.
     * @param _direct True if `_newOwner` should be set immediately. False if `_newOwner` needs to use `claimOwnership`.
     * @param _renounce Allows the `_newOwner` to be `address(0)` if `_direct` and `_renounce` is True. Has no effect otherwise
     */
    function transferOwnership(
        address _newOwner,
        bool _direct,
        bool _renounce
    ) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0) || _renounce, "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    /**
     * @dev Needs to be called by `pendingOwner` to claim ownership.
     */
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: tests/Parameterized.sol



pragma solidity 0.8.6;


contract Parameterized is Ownable {
    uint256 internal constant WEEK = 7 days;
    uint256 internal constant MONTH = 30 days;

    struct StakeParameters {
        uint256 value;
        uint256 lastChange;
    }

    /// @notice time to wait for unstake
    StakeParameters public timeToUnstake;

    /// @notice fee for premature unstake
    /// @dev value 1000 = 10%
    StakeParameters public unstakeFee;

    /// @notice reward recalculation period length
    StakeParameters public periodLength;

    function _minusFee(uint256 val) internal view returns (uint256) {
        return val - ((val * unstakeFee.value) / 10000);
    }

    function updateFee(uint256 val) external onlyOwner {
        require(block.timestamp > unstakeFee.lastChange + WEEK, "soon");
        require(val <= 2500, "max fee is 25%");
        unstakeFee.lastChange = block.timestamp;
        unstakeFee.value = val;
    }

    function updateTimeToUnstake(uint256 val) external onlyOwner {
        require(block.timestamp > timeToUnstake.lastChange + WEEK, "soon");
        require(val <= 2 * MONTH, "max delay is 60 days");
        timeToUnstake.lastChange = block.timestamp;
        timeToUnstake.value = val;
    }

    function updatePeriodLength(uint256 val) external onlyOwner {
        require(block.timestamp > periodLength.lastChange + WEEK, "soon");
        require(val >= WEEK, "min period length is 7 days");
        periodLength.lastChange = block.timestamp;
        periodLength.value = val;
    }
}

// File: tests/RewardsDistribution.sol



pragma solidity 0.8.6;


contract RewardsDistributionData {
    address public rewardsDistributor;
}

contract RewardsDistribution is Ownable, RewardsDistributionData {
    event RewardsDistributorChanged(address indexed previousDistributor, address indexed newDistributor);

    /**
     * @dev `rewardsDistributor` defaults to msg.sender on construction.
     */
    constructor() {
        rewardsDistributor = msg.sender;
        emit RewardsDistributorChanged(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the Reward Distributor.
     */
    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "caller is not reward distributor");
        _;
    }

    /**
     * @dev Change the rewardsDistributor - only called by owner
     * @param _rewardsDistributor Address of the new distributor
     */
    function setRewardsDistribution(address _rewardsDistributor) external onlyOwner {
        require(_rewardsDistributor != address(0), "zero address");

        emit RewardsDistributorChanged(rewardsDistributor, _rewardsDistributor);
        rewardsDistributor = _rewardsDistributor;
    }
}

// File: tests/StableMath.sol


pragma solidity 0.8.6;

// Based on StableMath from mStable
// https://github.com/mstable/mStable-contracts/blob/master/contracts/shared/StableMath.sol

library StableMath {
    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x * FULL_SCALE;
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        // return 9e36 / 1e18 = 9e18
        return (x * y) / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + FULL_SCALE - 1;
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
}

// File: tests/IERC20.sol



pragma solidity 0.8.6;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);

    // EIP 2612
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: tests/SafeERC20.sol



pragma solidity 0.8.6;


library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }

    function safeTransferFromDeluxe(IERC20 token, address from, uint256 amount) internal returns (uint256) {
        uint256 preBalance = token.balanceOf(address(this));
        safeTransferFrom(token, from, amount);
        uint256 postBalance = token.balanceOf(address(this));
        return postBalance - preBalance;
    }
}

// File: tests/ReentrancyGuard.sol



pragma solidity 0.8.6;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: tests/staking.sol



pragma solidity 0.8.6;






/**
 * @title  Staking
 * @notice Rewards stakers of given token with rewards in form of reward token, on a pro-rata basis.
 * @dev    Uses an ever increasing 'rewardPerTokenStored' variable to distribute rewards
 *         each time a write action is called in the contract. This allows for passive reward accrual.
 */
contract Staking is ReentrancyGuard, RewardsDistribution, Parameterized {
    using StableMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice reward token address
    address public token;
    /// @notice fee collecting address
    address public feeCollector;

    /// @notice timestamp for current period finish
    uint256 public periodFinish;
    /// @notice rewardRate for the rest of the period
    uint256 public rewardRate;
    /// @notice last time any user took action
    uint256 public lastUpdateTime;
    /// @notice accumulated per token reward since the beginning of time
    uint256 public rewardPerTokenStored;
    /// @notice amount of tokens that is used in reward per token calculation
    uint256 public stakedTokens;

    struct Stake {
        uint256 stakeStart; // timestamp of stake creation
        //
        uint256 rewardPerTokenPaid; // user accumulated per token rewards
        //
        uint256 tokens; // total tokens staked by user
        uint256 rewards; // current not-claimed rewards from last update
        //
        uint256 withdrawalPossibleAt; // timestamp after which stake can be removed without fee
        bool isWithdrawing; // true = user call to remove stake
    }

    /// @dev each holder have one stake
    /// @notice token stakes storage
    mapping(address => Stake) public tokenStake;

    /// @dev events
    event Claimed(address indexed user, uint256 amount);
    event StakeAdded(address indexed user, uint256 amount);
    event StakeRemoveRequested(address indexed user);
    event StakeRemoved(address indexed user, uint256 amount);
    event Recalculation(uint256 reward);

    /**
     * @dev One time initialization function
     * @param _token Staking token address
     * @param _feeCollector fee collecting address
     */
    function init(address _token, address _feeCollector) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        require(_feeCollector != address(0), "_feeCollector address cannot be 0");
        require(token == address(0), "init already done");
        token = _token;
        feeCollector = _feeCollector;

        timeToUnstake.value = WEEK;
        unstakeFee.value = 1000;
        periodLength.value = MONTH;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "_feeCollector address cannot be 0");
        feeCollector = _feeCollector;
    }

    /**
     * @dev Updates the reward for a given address,
     *      before executing function
     * @param _account address for which rewards will be updated
     */
    modifier updateReward(address _account) {
        _updateReward(_account);
        _;
    }

    /**
     * @dev guards that the msg.sender has token stake
     */
    modifier hasStake() {
        require(tokenStake[msg.sender].tokens > 0, "nothing staked");
        _;
    }

    /**
     * @dev checks if the msg.sender can withdraw requested unstake
     */
    modifier canUnstake() {
        require(_canUnstake(), "cannot unstake");
        _;
    }

    /**
     * @dev checks if for the msg.sender there is possibility to
     *      withdraw staked tokens without fee.
     */
    modifier cantUnstake() {
        require(!_canUnstake(), "unstake first");
        _;
    }

    /***************************************
                    ACTIONS
    ****************************************/

    /**
     * @dev Updates reward
     * @param _account address for which rewards will be updated
     */
    function _updateReward(address _account) internal {
        uint256 newRewardPerTokenStored = currentRewardPerTokenStored();
        // if statement protects against loss in initialization case
        if (newRewardPerTokenStored > 0) {
            rewardPerTokenStored = newRewardPerTokenStored;
            lastUpdateTime = lastTimeRewardApplicable();

            // setting of personal vars based on new globals
            if (_account != address(0)) {
                Stake storage s = tokenStake[_account];
                if (!s.isWithdrawing) {
                    s.rewards = _earned(_account);
                    s.rewardPerTokenPaid = newRewardPerTokenStored;
                }
            }
        }
    }

    /**
     * @dev Add tokens to staking contract
     * @param _amount of tokens to stake
     */
    function addStake(uint256 _amount) external {
        _addStake(msg.sender, _amount);
        emit StakeAdded(msg.sender, _amount);
    }

    /**
     * @dev Add tokens to staking contract by using permit to set allowance
     * @param _amount of tokens to stake
     * @param _deadline of permit signature
     * @param _approveMax allowance for the token
     */
    function addStakeWithPermit(
        uint256 _amount,
        uint256 _deadline,
        bool _approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 value = _approveMax ? type(uint256).max : _amount;
        IERC20(token).permit(msg.sender, address(this), value, _deadline, v, r, s);
        _addStake(msg.sender, _amount);
        emit StakeAdded(msg.sender, _amount);
    }

    /**
     * @dev Internal add stake function
     * @param _account selected staked tokens are credited to this address
     * @param _amount of staked tokens
     */
    function _addStake(address _account, uint256 _amount) internal nonReentrant updateReward(_account) {
        require(_amount > 0, "zero amount");
        Stake storage ts = tokenStake[_account];
        require(!ts.isWithdrawing, "cannot when withdrawing");

        // check for fee-on-transfer and proceed with received amount
        _amount = _transferFrom(token, msg.sender, _amount);

        if (ts.stakeStart == 0) {
            // new stake
            ts.stakeStart = block.timestamp;
        }

        // update account stake data
        ts.tokens += _amount;
        // update staking data
        stakedTokens += _amount;
    }

    /**
     * @dev Restake earned tokens and add them to token stake (instead of claiming)
     */
    function restake() external hasStake updateReward(msg.sender) {
        Stake storage ts = tokenStake[msg.sender];
        require(!ts.isWithdrawing, "cannot when withdrawing");

        uint256 rewards = ts.rewards;
        require(rewards > 0, "nothing to restake");

        delete ts.rewards;

        // update account stake data
        ts.tokens += rewards;
        // update pool staking data
        stakedTokens += rewards;

        emit Claimed(msg.sender, rewards);
        emit StakeAdded(msg.sender, rewards);
    }

    /**
     * @dev Claims rewards for the msg.sender.
     */
    function claim() external {
        _claim(msg.sender, msg.sender);
    }

    /**
     * @dev Claim msg.sender rewards to provided address
     * @param _recipient address where claimed tokens should be sent
     */
    function claimTo(address _recipient) external {
        _claim(msg.sender, _recipient);
    }

    /**
     * @dev Internal claim function. First updates rewards
     *      and then transfers.
     * @param _account claim rewards for this address
     * @param _recipient claimed tokens are sent to this address
     */
    function _claim(address _account, address _recipient) internal nonReentrant hasStake updateReward(_account) {
        uint256 rewards = tokenStake[_account].rewards;
        require(rewards > 0, "nothing to claim");

        delete tokenStake[_account].rewards;
        _transfer(token, _recipient, rewards);

        emit Claimed(_account, rewards);
    }

    /**
     * @dev Request unstake for deposited tokens. Marks user token stake as withdrawing,
     *      and start withdrawing period.
     */
    function requestUnstake() external {
        _requestUnstake(msg.sender);
        emit StakeRemoveRequested(msg.sender);
    }

    /**
     * @dev Internal request unstake function. Update rewards for the user first.
     * @param _account User address
     */
    function _requestUnstake(address _account) internal hasStake() updateReward(_account) {
        Stake storage ts = tokenStake[_account];
        require(!ts.isWithdrawing, "cannot when withdrawing");

        // update account stake data
        ts.isWithdrawing = true;
        ts.withdrawalPossibleAt = block.timestamp + timeToUnstake.value;
        // update pool staking data
        stakedTokens -= ts.tokens;
    }

    /**
     * @dev Withdraw stake for msg.sender from stake (if possible)
     */
    function unstake() external nonReentrant hasStake canUnstake {
        _unstake(false);
    }

    /**
     * @dev Unstake requested stake at any time accepting penalty fee
     */
    function unstakeWithFee() external nonReentrant hasStake cantUnstake {
        _unstake(true);
    }

    function _unstake(bool withFee) private {
        Stake memory ts = tokenStake[msg.sender];
        uint256 tokens;
        uint256 rewards;
        uint256 fee;

        if (ts.isWithdrawing) {
            tokens = withFee ? _minusFee(ts.tokens) : ts.tokens;
            fee = withFee ? (ts.tokens - tokens) : 0;
            rewards = ts.rewards;

            emit StakeRemoved(msg.sender, ts.tokens);
            delete tokenStake[msg.sender];
        }

        if (tokens + rewards > 0) {
            _transfer(token, msg.sender, tokens + rewards);
            if (fee > 0) {
                _transfer(token, feeCollector, fee);
            }

            if (rewards > 0) {
                emit Claimed(msg.sender, rewards);
            }
        }
    }

    /***************************************
                    GETTERS
    ****************************************/

    /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return StableMath.min(block.timestamp, periodFinish);
    }

    /**
     * @dev Calculates the amount of unclaimed rewards per token since last update,
     *      and sums with stored to give the new cumulative reward per token
     * @return 'Reward' per staked token
     */
    function currentRewardPerTokenStored() public view returns (uint256) {
        // If there is no staked tokens, avoid div(0)
        if (stakedTokens == 0) {
            return (rewardPerTokenStored);
        }
        // new reward units to distribute = rewardRate * timeSinceLastUpdate
        uint256 timeDelta = lastTimeRewardApplicable() - lastUpdateTime;
        uint256 rewardUnitsToDistribute = rewardRate * timeDelta;
        // new reward units per token = (rewardUnitsToDistribute * 1e18) / stakedTokens
        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(stakedTokens);
        // return summed rate
        return (rewardPerTokenStored + unitsToDistributePerToken);
    }

    /**
     * @dev Calculates the amount of unclaimed rewards a user has earned
     * @param _account user address
     * @return Total reward amount earned
     */
    function _earned(address _account) internal view returns (uint256) {
        Stake memory ts = tokenStake[_account];
        if (ts.isWithdrawing) return ts.rewards;

        // current rate per token - rate user previously received
        uint256 userRewardDelta = currentRewardPerTokenStored() - ts.rewardPerTokenPaid;
        uint256 userNewReward = ts.tokens.mulTruncate(userRewardDelta);

        // add to previous rewards
        return (ts.rewards + userNewReward);
    }

    /**
     * @dev Calculates the claimable amounts for token stake from rewards
     * @param _account user address
     */
    function claimable(address _account) external view returns (uint256) {
        return _earned(_account);
    }

    /**
     * @dev internal view to check if msg.sender can unstake
     * @return true if user requested unstake and time for unstake has passed
     */
    function _canUnstake() private view returns (bool) {
        return (tokenStake[msg.sender].isWithdrawing && block.timestamp >= tokenStake[msg.sender].withdrawalPossibleAt);
    }

    /**
     * @dev external view to check if address can stake tokens
     * @return true if user can stake tokens
     */
    function canStakeTokens(address _account) external view returns (bool) {
        return !tokenStake[_account].isWithdrawing;
    }

    /***************************************
                    REWARDER
    ****************************************/

    /**
     * @dev Notifies the contract that new rewards have been added.
     *      Calculates an updated rewardRate based on the rewards in period.
     * @param _reward Units of token that have been added to the token pool
     */
    function notifyRewardAmount(uint256 _reward) external onlyRewardsDistributor updateReward(address(0)) {
        uint256 currentTime = block.timestamp;

        // pull tokens
        require(_transferFrom(token, msg.sender, _reward) == _reward, "Exclude Rewarder from fee");

        // If previous period over, reset rewardRate
        if (currentTime >= periodFinish) {
            rewardRate = _reward / periodLength.value;
        }
        // If additional reward to existing period, calc sum
        else {
            uint256 remaining = periodFinish - currentTime;

            uint256 leftoverReward = remaining * rewardRate;
            rewardRate = (_reward + leftoverReward) / periodLength.value;
        }

        lastUpdateTime = currentTime;
        periodFinish = currentTime + periodLength.value;

        emit Recalculation(_reward);
    }

    /***************************************
                    TOKEN
    ****************************************/

    function _transferFrom(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        return IERC20(_token).safeTransferFromDeluxe(_from, _amount);
    }

    function _transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_token).safeTransfer(_to, _amount);
    }
}