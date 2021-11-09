// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./RewardManager.sol";

contract RewardManagerFactory is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeERC20 for IERC20;

    /// @notice all the information for this RewardManager in one struct
    struct RewardManagerInfo {
        address managerAddress;
        uint256 startDistribution;
        uint256 endDistribution;
    }

    struct UserInfo {
        uint256 _totalVested;
        uint256 _totalDrawnAmount;
        uint256 _amountBurnt;
        uint256 _claimable;
        uint256 _bonusRewards;
        uint256 _stillDue;
    }

    RewardManagerInfo[] public managers;

    uint256 public totalRewardManagers;

    mapping(address => uint256) public mangerIndex;

    // whitelisted rewardDistributors
    mapping(address => bool) public rewardDistributor;

    //Cryption Network Token (cnt) token address
    IERC20 public cnt;

    event RewardManagerLaunched(
        address indexed mangerAddress,
        uint256 indexed startDistributionTime,
        uint256 indexed endDistributionTime
    );

    /**
     * @notice Construct a new Reward Manager Factory contract
     * @param _cnt cnt token address
     * @dev deployer of contract on constructor is set as owner
     */
    constructor(IERC20 _cnt) {
        cnt = _cnt;
    }

    modifier validateRewardManagerByIndex(uint256 _index) {
        require(_index < managers.length, "Reward Manager does not exist");
        RewardManager manager = RewardManager(managers[_index].managerAddress);
        require(
            address(manager) != address(0),
            "Reward Manager does not exist"
        );
        _;
    }

    /**
     * @notice Creates a new Reward Manager contract and registers it in the Factory Contract
     * @param _cnt cnt token address
     * @param _startDistribution start timestamp
     * @param _endDistribution end timestamp
     * @param _upfrontUnlock Upfront unlock percentage
     * @param _preMaturePenalty Penalty percentage for pre mature withdrawal
     * @param _bonusPercentage Bonus rewards percentage for user who hasn't drawn any rewards untill endDistribution
     * @param _burner Burner for collecting preMaturePenalty
     * @dev deployer of contract on constructor is set as owner
     */
    function launchRewardManager(
        IERC20 _cnt,
        uint256 _startDistribution,
        uint256 _endDistribution,
        uint256 _upfrontUnlock,
        uint256 _preMaturePenalty,
        uint256 _bonusPercentage,
        address _burner
    ) public onlyOwner {
        require(address(_cnt) != address(0), "Cant be Zero address");
        require(address(_burner) != address(0), "Burner Cant be Zero address");

        require(
            _startDistribution >= block.timestamp,
            "Start time should be greater than current"
        ); // ideally at least 24 hours more to give investors time

        require(
            _endDistribution > _startDistribution,
            "EndDistribution should be more than startDistribution"
        );

        RewardManager newManager = new RewardManager(
            _cnt,
            _startDistribution,
            _endDistribution,
            _upfrontUnlock,
            _preMaturePenalty,
            _bonusPercentage,
            _burner
        );

        managers.push(
            RewardManagerInfo({
                managerAddress: address(newManager),
                startDistribution: _startDistribution,
                endDistribution: _endDistribution
            })
        ); //stacking up every crowdsale info ever made to crowdsales variable

        mangerIndex[address(newManager)] = totalRewardManagers; //mapping every manager address to its index in the array

        emit RewardManagerLaunched(
            address(newManager),
            _startDistribution,
            _endDistribution
        );
        totalRewardManagers++;
    }

    function removeRewardManager(uint256 _index) public onlyOwner {
        require(_index <= totalRewardManagers, "Invalid Index");
        delete managers[_index];
    }

    function userTotalVestingInfo(address _user)
        public
        view
        returns (
            uint256 totalVested,
            uint256 totalDrawnAmount,
            uint256 amountBurnt,
            uint256 claimable,
            uint256 bonusRewards,
            uint256 stillDue
        )
    {
        UserInfo memory user;
        for (uint256 i = 0; i < totalRewardManagers; i++) {
            address rewardManagerAddress = managers[i].managerAddress;
            if (rewardManagerAddress != address(0)) {
                RewardManager manager = RewardManager(rewardManagerAddress);
                (
                    user._totalVested,
                    user._totalDrawnAmount,
                    user._amountBurnt,
                    user._claimable,
                    user._bonusRewards,
                    user._stillDue
                ) = manager.vestingInfo(_user);

                if (user._totalVested > 0) {
                    totalVested += user._totalVested;
                    totalDrawnAmount += user._totalDrawnAmount;
                    amountBurnt += user._amountBurnt;
                    claimable += user._claimable;
                    bonusRewards += user._bonusRewards;
                    stillDue += user._stillDue;
                }
            }
        }
    }

    function handleRewardsForUser(
        address user,
        uint256 rewardAmount,
        uint256 timestamp,
        uint256 pid,
        uint256 rewardDebt
    ) external {
        require(rewardDistributor[msg.sender], "Not a valid RewardDistributor");
        //get the most active reward manager
        RewardManager manager = RewardManager(
            managers[totalRewardManagers - 1].managerAddress
        );
        require(address(manager) != address(0), "No Reward Manager Added");
        /* No use of if condition here to check if AddressZero since funds are transferred before calling handleRewardsForUser. Require is a must
        So if there is accidentally no strategy linked, it goes into else resulting in loss of user's funds.
        */
        cnt.safeTransfer(address(manager), rewardAmount);
        manager.handleRewardsForUser(
            user,
            rewardAmount,
            timestamp,
            pid,
            rewardDebt
        );
    }

    /**
     * @notice Draws down any vested tokens due in all Reward Manager
     * @dev Must be called directly by the beneficiary assigned the tokens in the vesting
     */
    function drawDown() external onlyOwner {
        for (uint256 i = 0; i < totalRewardManagers; i++) {
            address rewardManagerAddress = managers[i].managerAddress;
            if (rewardManagerAddress != address(0)) {
                RewardManager manager = RewardManager(rewardManagerAddress);
                (, , , uint256 userClaimable, , ) = manager.vestingInfo(
                    msg.sender
                );
                if (userClaimable > 0) {
                    manager.drawDown(msg.sender);
                }
            }
        }
    }

    /**
     * @notice Pre maturely Draws down all vested tokens by burning the preMaturePenalty
     * @dev Must be called directly by the beneficiary assigned the tokens in the vesting
     */
    function preMatureDraw() external onlyOwner {
        for (uint256 i = 0; i < totalRewardManagers; i++) {
            address rewardManagerAddress = managers[i].managerAddress;
            if (rewardManagerAddress != address(0)) {
                RewardManager manager = RewardManager(rewardManagerAddress);
                (, , , , , uint256 userStillDue) = manager.vestingInfo(
                    msg.sender
                );
                if (userStillDue > 0) {
                    manager.preMatureDraw(msg.sender);
                }
            }
        }
    }

    function updatePreMaturePenalty(
        uint256 _index,
        uint256 _newpreMaturePenalty
    ) external onlyOwner validateRewardManagerByIndex(_index) {
        RewardManager manager = RewardManager(managers[_index].managerAddress);
        manager.updatePreMaturePenalty(_newpreMaturePenalty);
    }

    function updateBonusPercentage(uint256 _index, uint256 _newBonusPercentage)
        external
        onlyOwner
        validateRewardManagerByIndex(_index)
    {
        RewardManager manager = RewardManager(managers[_index].managerAddress);
        manager.updateBonusPercentage(_newBonusPercentage);
    }

    function updateDistributionTime(
        uint256 _index,
        uint256 _updatedStartTime,
        uint256 _updatedEndTime
    ) external onlyOwner validateRewardManagerByIndex(_index) {
        RewardManager manager = RewardManager(managers[_index].managerAddress);
        manager.updateDistributionTime(_updatedStartTime, _updatedEndTime);
    }

    function updateUpfrontUnlock(uint256 _index, uint256 _newUpfrontUnlock)
        external
        onlyOwner
        validateRewardManagerByIndex(_index)
    {
        RewardManager manager = RewardManager(managers[_index].managerAddress);
        manager.updateUpfrontUnlock(_newUpfrontUnlock);
    }

    function updateWhitelistAddress(
        uint256 _index,
        address _excludeAddress,
        bool status
    ) external onlyOwner validateRewardManagerByIndex(_index) {
        RewardManager manager = RewardManager(managers[_index].managerAddress);
        manager.updateWhitelistAddress(_excludeAddress, status);
    }

    function updateRewardDistributor(address _distributor, bool status)
        external
        onlyOwner
    {
        rewardDistributor[_distributor] = status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RewardManager is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public bonusRewardsPool;

    address public rewardManagerFactory = owner();

    // Call from excludedAddresses will be whitelisted & rewards harvested from farm will not be vested
    mapping(address => bool) public excludedAddresses;

    // preMaturePenalty will be sent to burner address
    address public l2Burner;

    //Upfront rewards unlock in percentage. This number is later divided by 1000 for calculations.
    uint256 public upfrontUnlock;

    //Pre mature penalty in percentage. This number is later divided by 1000 for calculations.
    uint256 public preMaturePenalty;

    //Bonus Rewards in percentage. This number is later divided by 1000 for calculations.
    uint256 public bonusPercentage;

    /// @notice start of Distribution phase as a timestamp
    uint256 public startDistribution;

    /// @notice end of Distribution phase as a timestamp
    uint256 public endDistribution;

    //Cryption Network Token (cnt) token address
    IERC20 public cnt;

    /// @notice amount vested for a user.
    mapping(address => uint256) public vestedAmount;

    /// @notice cumulative total of tokens drawn down (and transferred from the deposit account) per beneficiary
    mapping(address => uint256) public totalDrawn;

    /// @notice total tokens burnt per beneficiary
    mapping(address => uint256) public burntAmount;

    /// @notice bonus rewards entitled per beneficiary
    mapping(address => uint256) public bonusReward;

    /// @notice event emitted when a vesting schedule is created
    event Vested(address indexed _beneficiary, uint256 indexed value);

    /// @notice event emitted when a successful drawn down of vesting tokens is made
    event DrawDown(
        address indexed _beneficiary,
        uint256 indexed _amount,
        uint256 indexed bonus
    );

    /// @notice event emitted when a successful pre mature drawn down of vesting tokens is made
    event PreMatureDrawn(
        address indexed _beneficiary,
        uint256 indexed burntAmount,
        uint256 indexed userEffectiveWithdrawn
    );

    modifier checkPercentages(uint256 _percentage) {
        require(_percentage <= 1000, "Invalid Percentages");
        _;
    }

    modifier checkTime(uint256 _startDistribution, uint256 _endDistribution) {
        require(
            _endDistribution > _startDistribution,
            "end time should be greater than start"
        );
        _;
    }

    /**
     * @notice Construct a new Reward Manager contract
     * @param _cnt cnt token address
     * @param _startDistribution start timestamp
     * @param _endDistribution end timestamp
     * @param _upfrontUnlock Upfront unlock percentage
     * @param _preMaturePenalty Penalty percentage for pre mature withdrawal
     * @param _bonusPercentage Bonus rewards percentage for user who hasn't drawn any rewards untill endDistribution
     * @param _burner Burner for collecting preMaturePenalty
     * @dev deployer of contract on constructor is set as owner
     */
    constructor(
        IERC20 _cnt,
        uint256 _startDistribution,
        uint256 _endDistribution,
        uint256 _upfrontUnlock,
        uint256 _preMaturePenalty,
        uint256 _bonusPercentage,
        address _burner
    ) checkTime(_startDistribution, _endDistribution) {
        cnt = _cnt;
        startDistribution = _startDistribution;
        endDistribution = _endDistribution;
        upfrontUnlock = _upfrontUnlock;
        preMaturePenalty = _preMaturePenalty;
        bonusPercentage = _bonusPercentage;
        l2Burner = _burner;
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    function updatePreMaturePenalty(uint256 _newpreMaturePenalty)
        external
        checkPercentages(_newpreMaturePenalty)
        onlyOwner
    {
        preMaturePenalty = _newpreMaturePenalty;
    }

    function updateBonusPercentage(uint256 _newBonusPercentage)
        external
        onlyOwner
    {
        bonusPercentage = _newBonusPercentage;
    }

    function updateDistributionTime(
        uint256 _updatedStartTime,
        uint256 _updatedEndTime
    ) external checkTime(_updatedStartTime, _updatedEndTime) onlyOwner {
        require(
            startDistribution > _getNow(),
            "Vesting already started can't update now"
        );
        startDistribution = _updatedStartTime;
        endDistribution = _updatedEndTime;
    }

    function updateUpfrontUnlock(uint256 _newUpfrontUnlock)
        external
        checkPercentages(_newUpfrontUnlock)
        onlyOwner
    {
        upfrontUnlock = _newUpfrontUnlock;
    }

    function updateWhitelistAddress(address _excludeAddress, bool status)
        external
        onlyOwner
    {
        excludedAddresses[_excludeAddress] = status;
    }

    function handleRewardsForUser(
        address user,
        uint256 rewardAmount,
        uint256 timestamp,
        uint256 pid,
        uint256 rewardDebt
    ) external onlyOwner {
        if (rewardAmount > 0) {
            if (excludedAddresses[user]) {
                cnt.safeTransfer(user, rewardAmount);
            } else {
                uint256 upfrontAmount = rewardAmount.mul(upfrontUnlock).div(
                    1000
                );
                cnt.safeTransfer(user, upfrontAmount);
                _vest(user, rewardAmount.sub(upfrontAmount));
            }
        }
    }

    function _vest(address _user, uint256 _amount) internal {
        require(
            _getNow() < startDistribution,
            " Cannot vest in distribution phase"
        );
        require(_user != address(0), "Cannot vest for Zero address");

        vestedAmount[_user] = vestedAmount[_user].add(_amount);

        emit Vested(_user, _amount);
    }

    /**
     * @notice Vesting schedule data associated for a user
     * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
     * @return totalVested Total vested amount for user
     * @return totalDrawnAmount total token drawn by user
     * @return amountBurnt total amount burnt while pre maturely drawing
     * @return claimable token available to be claimed
     * @return bonusRewards tokens a user will get if nothing has been withdrawn untill endDistribution
     * @return stillDue tokens still due (and currently locked) from vesting schedule
     */
    function vestingInfo(address _user)
        public
        view
        returns (
            uint256 totalVested,
            uint256 totalDrawnAmount,
            uint256 amountBurnt,
            uint256 claimable,
            uint256 bonusRewards,
            uint256 stillDue
        )
    {
        return (
            vestedAmount[_user],
            totalDrawn[_user],
            burntAmount[_user],
            _availableDrawDownAmount(_user),
            bonusReward[_user],
            _remainingBalance(_user)
        );
    }

    function _availableDrawDownAmount(address _user)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = _getNow();
        if (
            currentTime < startDistribution ||
            totalDrawn[_user] == vestedAmount[_user]
        ) {
            return 0;
        } else if (currentTime >= endDistribution) {
            return _remainingBalance(_user);
        } else {
            uint256 elapsedTime = currentTime.sub(startDistribution);
            uint256 _totalVestingTime = endDistribution.sub(startDistribution);
            return
                _remainingBalance(_user).mul(elapsedTime).div(
                    _totalVestingTime
                );
        }
    }

    function _remainingBalance(address _user) internal view returns (uint256) {
        return vestedAmount[_user].sub(totalDrawn[_user]);
    }

    /**
     * @notice Draws down any vested tokens due
     * @dev Must be called directly by the beneficiary assigned the tokens in the vesting
     */
    function drawDown(address _user) external onlyOwner nonReentrant {
        require(_getNow() > startDistribution, "Vesting not yet started");
        return _drawDown(_user);
    }

    /**
     * @notice Pre maturely Draws down all vested tokens by burning the preMaturePenalty
     * @dev Must be called directly by the beneficiary assigned the tokens in the vesting
     */
    function preMatureDraw(address _beneficiary)
        external
        onlyOwner
        nonReentrant
    {
        uint256 remainingBalance = _remainingBalance(_beneficiary);
        require(remainingBalance > 0, "Nothing left to draw");

        _drawDown(_beneficiary);
        remainingBalance = _remainingBalance(_beneficiary);
        if (remainingBalance > 0) {
            uint256 burnAmount = remainingBalance.mul(preMaturePenalty).div(
                1000
            );
            uint256 effectiveAmount = remainingBalance.sub(burnAmount);

            totalDrawn[_beneficiary] = vestedAmount[_beneficiary];
            burntAmount[_beneficiary] = burntAmount[_beneficiary].add(
                burnAmount
            );
            cnt.safeTransfer(_beneficiary, effectiveAmount);
            cnt.safeTransfer(l2Burner, burnAmount);
            emit PreMatureDrawn(_beneficiary, burnAmount, effectiveAmount);
        }
    }

    function _drawDown(address _beneficiary) internal {
        require(vestedAmount[_beneficiary] > 0, "No vesting found");

        uint256 amount = _availableDrawDownAmount(_beneficiary);
        if (amount == 0) return;

        if (_getNow() > endDistribution && totalDrawn[_beneficiary] == 0) {
            bonusReward[_beneficiary] = amount.mul(bonusPercentage).div(1000);
        }
        // Increase total drawn amount
        totalDrawn[_beneficiary] = totalDrawn[_beneficiary].add(amount);

        // Safety measure - this should never trigger
        require(
            totalDrawn[_beneficiary] <= vestedAmount[_beneficiary],
            "Safety Mechanism - Drawn exceeded Amount Vested"
        );

        // Issue tokens to beneficiary
        cnt.safeTransfer(_beneficiary, amount.add(bonusReward[_beneficiary]));
        emit DrawDown(_beneficiary, amount, bonusReward[_beneficiary]);
    }

    /**
     * @notice Function to add Bonus Rewards for user who hasn't vested any amount untill endDistribution
     * @dev Must be called directly by the owner
     */
    function addBonusRewards(uint256 _bonusRewards) external onlyOwner {
        bonusRewardsPool = bonusRewardsPool.add(_bonusRewards);
        cnt.safeTransferFrom(msg.sender, address(this), _bonusRewards);
    }

    /**
     * @notice Function to remove any extra Bonus Rewards sent to this contract
     * @dev Must be called directly by the owner
     */
    function removeBonusRewards() external onlyOwner {
        uint256 cntBalance = cnt.balanceOf(address(this));
        uint256 bonus = bonusRewardsPool;
        bonusRewardsPool = 0;
        if (cntBalance < bonus) {
            cnt.safeTransfer(msg.sender, cntBalance);
        } else {
            cnt.safeTransfer(msg.sender, bonus);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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