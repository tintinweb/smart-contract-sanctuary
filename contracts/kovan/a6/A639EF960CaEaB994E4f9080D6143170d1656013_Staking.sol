// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable, ReentrancyGuard {
    //STRUCTURES:--------------------------------------------------------
    struct AccountInfo {
        uint256 lessBalance;
        uint256 lpBalance;
        uint256 overallBalance;
    }

    struct StakeItem {
        uint256 startTime;
        uint256 stakedLp;
        uint256 stakedLess;
    }

    struct UserStakes {
        uint256[] ids;
        mapping(uint256 => uint256) indexes;
    }

    struct DepositReward {
        uint256 day;
        uint256 lpShares;
        uint256 lessShares;
        uint256 lpReward;
        uint256 lessReward;
    }

    //FIELDS:----------------------------------------------------
    ERC20 public lessToken;
    ERC20 public lpToken;

    uint256 public contractStart;
    uint256 public minStakeTime;
    uint256 public dayDuration;
    uint256 public participants;
    uint16 public penaltyDistributed = 25; //100% = PERCENT_FACTOR
    uint16 public penaltyBurned = 25; //100% = PERCENT_FACTOR
    uint256 private constant PERCENT_FACTOR = 1000;
    uint256 public lessPerLp = 300; //1 LP = 300 LESS

    uint256 public stakeIdLast;

    uint256 public allLp;
    uint256 public allLess;
    uint256 public totalLpRewards;
    uint256 public totalLessRewards;

    mapping(address => AccountInfo) private accountInfos;
    mapping(address => UserStakes) private userStakes;
    mapping(uint256 => StakeItem) public stakes;
    mapping(uint256 => DepositReward) public rewardDeposits;
    mapping(uint256 => uint256) private _dayIndexies;
    mapping(uint256 => bool) private _firstTransactionPerDay;

    uint8[4] public poolPercentages;
    uint256[5] public stakingTiers;

    uint256 private _todayPenaltyLp;
    uint256 private _todayPenaltyLess;
    uint256 private _lastDayPenalty;
    uint256 private _lastDayIndex;
    uint256[] private _depositDays;

    //CONSTRUCTOR-------------------------------------------------------
    constructor(
        ERC20 _lp,
        ERC20 _less,
        uint256 _dayDuration,
        uint256 _startTime
    ) {
        require(_dayDuration > 0 && _startTime > 0, "Error: wrong params");
        lessToken = _less;
        lpToken = _lp;

        dayDuration = _dayDuration;
        minStakeTime = _dayDuration * 30;
        contractStart = _startTime;

        poolPercentages[0] = 30; //tier 5
        poolPercentages[1] = 20; //tier 4
        poolPercentages[2] = 15; //tier 3
        poolPercentages[3] = 25; //tier 2

        stakingTiers[0] = 200000 ether; //tier 5
        stakingTiers[1] = 50000 ether; //tier 4
        stakingTiers[2] = 20000 ether; //tier 3
        stakingTiers[3] = 5000 ether; //tier 2
        stakingTiers[4] = 1000 ether; //tier 1

        _firstTransactionPerDay[0] = true;
    }

    //EVENTS:-----------------------------------------------------------------
    event Staked(
        address staker,
        uint256 stakeId,
        uint256 startTime,
        uint256 stakedLp,
        uint256 stakedLess
    );

    event Unstaked(
        address staker,
        uint256 stakeId,
        uint256 unstakeTime,
        bool isUnstakedEarlier
    );

    //MODIFIERS:---------------------------------------------------

    modifier onlyWhenOpen() {
        require(block.timestamp > contractStart, "Error: early");
        _;
    }

    //EXTERNAL AND PUBLIC WRITE FUNCTIONS:---------------------------------------------------

    /**
     * @dev stake tokens
     * @param lpAmount Amount of staked LP tokens
     * @param lessAmount Amount of staked Less tokens
     */

    function stake(uint256 lpAmount, uint256 lessAmount)
        external
        nonReentrant
        onlyWhenOpen
    {
        address sender = _msgSender();
        uint256 today = _currentDay();
        if(participants == 0 && totalLessRewards + totalLpRewards > 0){
            _todayPenaltyLp = totalLpRewards;
            _todayPenaltyLess = totalLessRewards;
            _lastDayPenalty = today;
        }
        _rewriteTodayVars();
        if (userStakes[sender].ids.length == 0) {
            participants++;
        }
        require(lpAmount > 0 || lessAmount > 0, "Error: zero staked tokens");

        AccountInfo storage account = accountInfos[sender];

        account.lpBalance += lpAmount;
        account.lessBalance += lessAmount;
        account.overallBalance += lessAmount + getLpInLess(lpAmount);

        StakeItem memory newStake = StakeItem(today, lpAmount, lessAmount);
        stakes[stakeIdLast] = newStake;
        userStakes[sender].ids.push(stakeIdLast);
        userStakes[sender].indexes[stakeIdLast] = userStakes[sender].ids.length;

        if (lpAmount > 0) {
            require(
                lpToken.transferFrom(sender, address(this), lpAmount),
                "Error: LP token tranfer failed"
            );
            allLp += lpAmount;
        }
        if (lessAmount > 0) {
            require(
                lessToken.transferFrom(sender, address(this), lessAmount),
                "Error: Less token tranfer failed"
            );
            allLess += lessAmount;
        }

        emit Staked(sender, stakeIdLast++, today, lpAmount, lessAmount);
    }

    /**
     * @dev unstake all tokens and rewards
     * @param _stakeId id of the unstaked pool
     */

    function unstake(uint256 _stakeId) public onlyWhenOpen {
        _unstake(_stakeId, false);
    }

    /**
     * @dev unstake all tokens and rewards without penalty. Only for owner
     * @param _stakeId id of the unstaked pool
     */

    function unstakeWithoutPenalty(uint256 _stakeId)
        external
        onlyOwner
        onlyWhenOpen
    {
        _unstake(_stakeId, true);
    }

    /**
     * @dev withdraw all of unsold reward tokens. Only for owner
     */
    
    function emergencyWithdraw() external onlyOwner onlyWhenOpen nonReentrant {
        require(participants == 0 && totalLpRewards + totalLessRewards > 0, "Error: owner's emergency rewards withdraw is not available");
        uint256 lessToTransfer = totalLessRewards;
        uint256 lpToTransfer = totalLpRewards;
        if(totalLessRewards > 0){
            totalLessRewards = 0;
            require(lessToken.transfer(owner(), lessToTransfer), "Error: can't send tokens");
        }
        if(totalLpRewards > 0){
            totalLpRewards = 0;
            require(lpToken.transfer(owner(), lpToTransfer), "Error: can't send tokens");
        }
    }

    /**
     * @dev set num of Less per one LP
     */

    function setLessInLP(uint256 amount) public onlyOwner {
        lessPerLp = amount;
    }

    /**
     * @dev set minimum days of stake for unstake without penalty
     */

    function setMinTimeToStake(uint256 _minTimeInDays) public onlyOwner {
        require(_minTimeInDays > 0, "Error: zero time");
        minStakeTime = _minTimeInDays * dayDuration;
    }

    /**
     * @dev set penalty percent
     */
    function setPenalty(uint16 distributed, uint16 burned) public onlyOwner {
        penaltyDistributed = distributed;
        penaltyBurned = burned;
    }

    function setLp(address _lp) external onlyOwner {
        lpToken = ERC20(_lp);
    }

    function setLess(address _less) external onlyOwner {
        lessToken = ERC20(_less);
    }

    /* function setDayDuration(uint256 _timeInSec) external onlyOwner {
        require(_timeInSec > 0, "zero time");
        dayDuration = _timeInSec;
    } */

    function setStakingTiresSums(
        uint256 tier1,
        uint256 tier2,
        uint256 tier3,
        uint256 tier4,
        uint256 tier5
    ) external onlyOwner {
        stakingTiers[0] = tier5; //tier 5
        stakingTiers[1] = tier4; //tier 4
        stakingTiers[2] = tier3; //tier 3
        stakingTiers[3] = tier2; //tier 2
        stakingTiers[4] = tier1; //tier 1
    }

    function setPoolPercentages(
        uint8 tier2,
        uint8 tier3,
        uint8 tier4,
        uint8 tier5
    ) external onlyOwner {
        require(
            tier2 + tier3 + tier4 + tier5 < 100,
            "Percents sum should be less 100"
        );

        poolPercentages[0] = tier5; //tier 5
        poolPercentages[1] = tier4; //tier 4
        poolPercentages[2] = tier3; //tier 3
        poolPercentages[3] = tier2; //tier 2
    }

    function addRewards(uint256 lpAmount, uint256 lessAmount)
        external
        onlyOwner
        nonReentrant
    {
        _rewriteTodayVars();
        address sender = _msgSender();
        require(lpAmount + lessAmount > 0, "Error: add non zero amount");
        if (lpAmount > 0) {
            require(
                lpToken.transferFrom(sender, address(this), lpAmount),
                "Error: can't get your lp tokens"
            );
            totalLpRewards += lpAmount;
            _todayPenaltyLp += lpAmount;
        }
        if (lessAmount > 0) {
            require(
                lessToken.transferFrom(sender, address(this), lessAmount),
                "Error: can't get your less tokens"
            );
            totalLessRewards += lessAmount;
            _todayPenaltyLess += lessAmount;
        }
        _lastDayPenalty = _currentDay();
    }

    //EXTERNAL AND PUBLIC READ FUNCTIONS:--------------------------------------------------

    function getUserTier(address user) external view returns (uint8) {
        uint256 balance = accountInfos[user].overallBalance;
        for (uint8 i = 0; i < stakingTiers.length; i++) {
            if (balance >= stakingTiers[i])
                return uint8(stakingTiers.length - i);
        }
        return 0;
    }

    function getLpRewradsAmount(uint256 id)
        external
        view
        returns (uint256 lpRewards)
    {
        (lpRewards, ) = _rewards(id);
    }

    function getLessRewradsAmount(uint256 id)
        external
        view
        returns (uint256 lessRewards)
    {
        (, lessRewards) = _rewards(id);
    }

    function getLpBalanceByAddress(address user)
        external
        view
        returns (uint256 lp)
    {
        lp = accountInfos[user].lpBalance;
    }

    function getLessBalanceByAddress(address user)
        external
        view
        returns (uint256 less)
    {
        less = accountInfos[user].lessBalance;
    }

    function getOverallBalanceInLessByAddress(address user)
        external
        view
        returns (uint256 overall)
    {
        overall = accountInfos[user].overallBalance;
    }

    /**
     * @dev return sum of LP converted in Less
     * @param _amount amount of converted LP
     */
    function getLpInLess(uint256 _amount) private view returns (uint256) {
        return _amount * lessPerLp;
    }

    /**
     * @dev return full contract balance converted in Less
     */
    function getOverallBalanceInLess() public view returns (uint256) {
        return allLess + allLp * lessPerLp;
    }

    function getAmountOfUsersStakes(address user)
        external
        view
        returns (uint256)
    {
        return userStakes[user].ids.length;
    }

    function getUserStakeIds(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userStakes[user].ids;
    }

    function currentDay() external view onlyWhenOpen returns (uint256) {
        return _currentDay();
    }

    function getRewardDeposits(uint256 day)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256[] memory
        )
    {
        return (
            rewardDeposits[day].lpShares,
            rewardDeposits[day].lessShares,
            rewardDeposits[day].lpReward,
            rewardDeposits[day].lessReward,
            _depositDays
        );
    }

    function getTodayPenalty() external view returns (uint256, uint256) {
        return (_todayPenaltyLp, _todayPenaltyLess);
    }

    //INTERNAL AND PRIVATE FUNCTIONS-------------------------------------------------------
    function _unstake(uint256 id, bool isWithoutPenalty) internal nonReentrant {
        address staker = _msgSender();
        uint256 today = _currentDay();
        _rewriteTodayVars();
        require(userStakes[staker].ids.length > 0, "Error: you haven't stakes");
        require(userStakes[staker].indexes[id] != 0, "Not ur stake");

        bool isUnstakedEarlier = (today - stakes[id].startTime) * dayDuration <
            minStakeTime;

        uint256 lpRewards;
        uint256 lessRewards;
        if (!isUnstakedEarlier) (lpRewards, lessRewards) = _rewards(id);

        uint256 lpAmount = stakes[id].stakedLp;
        uint256 lessAmount = stakes[id].stakedLess;

        allLp -= lpAmount;
        allLess -= lessAmount;
        AccountInfo storage account = accountInfos[staker];

        account.lpBalance -= lpAmount;
        account.lessBalance -= lessAmount;
        account.overallBalance -= lessAmount + getLpInLess(lpAmount);

        if (isUnstakedEarlier && !isWithoutPenalty) {
            (lpAmount, lessAmount) = payPenalty(lpAmount, lessAmount);
            (uint256 freeLp, uint256 freeLess) = _rewards(id);
            if (freeLp > 0) _todayPenaltyLp += freeLp;
            if (freeLess > 0) _todayPenaltyLess += freeLess;
            _lastDayPenalty = today;
        }

        if (lpAmount + lpRewards > 0) {
            require(
                lpToken.transfer(staker, lpAmount + lpRewards),
                "Error: LP transfer failed"
            );
        }
        if (lessAmount + lessRewards > 0) {
            require(
                lessToken.transfer(staker, lessAmount + lessRewards),
                "Error: Less transfer failed"
            );
        }

        totalLessRewards -= lessRewards;
        totalLpRewards -= lpRewards;
        if (userStakes[staker].ids.length == 1) {
            participants--;
        }

        removeStake(staker, id);

        emit Unstaked(staker, id, today, isUnstakedEarlier);
    }

    function payPenalty(uint256 lpAmount, uint256 lessAmount)
        private
        returns (uint256, uint256)
    {
        uint256 lpToBurn = (lpAmount * penaltyBurned) / PERCENT_FACTOR;
        uint256 lessToBurn = (lessAmount * penaltyBurned) / PERCENT_FACTOR;
        uint256 lpToDist = (lpAmount * penaltyDistributed) / PERCENT_FACTOR;
        uint256 lessToDist = (lessAmount * penaltyDistributed) / PERCENT_FACTOR;

        burnPenalty(lpToBurn, lessToBurn);
        distributePenalty(lpToDist, lessToDist);

        uint256 lpDecrease = lpToBurn + lpToDist;
        uint256 lessDecrease = lessToBurn + lessToDist;

        return (lpAmount - lpDecrease, lessAmount - lessDecrease);
    }

    function _rewards(uint256 id)
        private
        view
        returns (uint256 lpRewards, uint256 lessRewards)
    {
        StakeItem storage deposit = stakes[id];

        uint256 countStartIndex;
        uint256 countEndIndex = _depositDays.length;

        uint256 i;
        for (i = 0; i < _depositDays.length; i++) {
            if (deposit.startTime <= _depositDays[i]) {
                countStartIndex = i;
                break;
            }
        }
        if (countStartIndex == 0 && i == _depositDays.length) {
            return (0, 0);
        }
        uint256 curDay;
        for (i = countStartIndex; i < countEndIndex; i++) {
            curDay = _dayIndexies[i];
            if (rewardDeposits[curDay].lpShares > 0) {
                lpRewards +=
                    (deposit.stakedLp * rewardDeposits[curDay].lpReward) /
                    rewardDeposits[curDay].lpShares;
            }
            if (rewardDeposits[curDay].lessShares > 0) {
                lessRewards +=
                    (deposit.stakedLess * rewardDeposits[curDay].lessReward) /
                    rewardDeposits[curDay].lessShares;
            }
        }

        return (lpRewards, lessRewards);
    }

    /**
     * @dev destribute penalty among all stakers proportional their stake sum.
     * @param lp LP token penalty
     * @param less Less token penalty
     */

    function distributePenalty(uint256 lp, uint256 less) internal {
        _todayPenaltyLess += less;
        _todayPenaltyLp += lp;
        _lastDayPenalty = _currentDay();
        totalLpRewards += lp;
        totalLessRewards += less;
    }

    /**
     * @dev burn penalty.
     * @param lp LP token penalty
     * @param less Less token penalty
     */

    function burnPenalty(uint256 lp, uint256 less) internal {
        if (lp > 0) {
            require(lpToken.transfer(owner(), lp), "con't get ur tkns");
        }
        if (less > 0) {
            require(lessToken.transfer(owner(), less), "cont get ur tkns");
        }
    }

    /**
     * @dev remove stake from stakeList by index
     * @param staker staker address
     * @param id id of stake pool
     */

    function removeStake(address staker, uint256 id) internal {
        delete stakes[id];

        require(
            userStakes[staker].ids.length != 0,
            "Error: whitelist is empty"
        );

        if (userStakes[staker].ids.length > 1) {
            uint256 stakeIndex = userStakes[staker].indexes[id] - 1;
            uint256 lastIndex = userStakes[staker].ids.length - 1;
            uint256 lastStake = userStakes[staker].ids[lastIndex];
            userStakes[staker].ids[stakeIndex] = lastStake;
            userStakes[staker].indexes[lastStake] = stakeIndex + 1;
        }
        userStakes[staker].ids.pop();
        userStakes[staker].indexes[id] = 0;
    }

    function _currentDay() private view returns (uint256) {
        return (block.timestamp - contractStart) / dayDuration;
    }

    function _rewriteTodayVars() private {
        uint256 today = _currentDay();
        if (
            !_firstTransactionPerDay[today] &&
            _todayPenaltyLess + _todayPenaltyLp > 0 &&
            participants > 0
        ) {
            rewardDeposits[_lastDayPenalty] = DepositReward(
                _lastDayPenalty,
                allLp,
                allLess,
                _todayPenaltyLp,
                _todayPenaltyLess
            );
            _todayPenaltyLp = 0;
            _todayPenaltyLess = 0;
            _depositDays.push(_lastDayPenalty);
            _dayIndexies[_depositDays.length - 1] = _lastDayPenalty;
            _firstTransactionPerDay[today] = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

