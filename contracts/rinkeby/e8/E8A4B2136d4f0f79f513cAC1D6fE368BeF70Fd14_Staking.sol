pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IErc20Token.sol";
import "./StakingStorage.sol";
import "./StakingEvent.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Staking Contract
contract Staking is StakingStorage, StakingEvent, Ownable {
    using SafeMath for uint256;

    constructor(address chn, uint256 _autoCompoundingFee) Ownable() {
        rewardAddress = chn;
        autoCompoundingFee = _autoCompoundingFee;
    }

    /********************
     * MODIFIER *
     ********************/

    modifier pidValid(uint256 pid) {
        require(linearPoolInfo.length > pid && pid >= 0, "pid not valid");
        _;
    }

    /********************
     * STANDARD ACTIONS *
     ********************/

    function getPoolInfoFromId(uint pid) public view pidValid(pid) returns (LinearPoolInfo memory) {
        return linearPoolInfo[pid];
    }

    function getStakedAmount(uint256 pid, address staker) public view pidValid(pid) returns (uint256) {
        uint256 currentIndex = stakedMapIndex[pid][staker];
        Checkpoint memory current = stakedMap[pid][staker][currentIndex];
        return current.stakedAmount;
    }

    function getPriorStakedAmount(uint256 pid, address staker, uint256 blockNumber) external view pidValid(pid) returns (uint256) {
        if (blockNumber == 0) {
            return getStakedAmount(pid, staker);
        }

        uint256 currentIndex = stakedMapIndex[pid][staker];
        Checkpoint memory current = stakedMap[pid][staker][currentIndex];

        for (uint i = current.blockNumber; i > 0; i--) {
            Checkpoint memory checkpoint = stakedMap[pid][staker][i];
            if (checkpoint.blockNumber <= blockNumber) {
                return checkpoint.stakedAmount;
            }
        }
        return 0;
    }


    function getAmountRewardInPool(uint256 pid, address staker) public view pidValid(pid) returns (uint256) {
        return _getAmountRewardInPool(pid, staker);
    }

    function getCoumpoundingReward(uint256 pid) public view pidValid(pid) returns (uint256) {
        LinearPoolInfo memory currentPool = linearPoolInfo[pid];
        require(currentPool.tokenStake == rewardAddress, "Pool not valid");
        address[] memory listUser = listUserInPool[pid];
        uint256 totalReward;
        for (uint256 index = 0; index < listUser.length; index++) {
            address staker = listUser[index];
            uint256 reward = _getAmountRewardInPool(pid, staker);
            totalReward = totalReward.add(reward.mul(autoCompoundingFee).div(PERCENT));
        }
        return totalReward;
    }

    function calculateReward(uint256 rewardPerBlock, uint256 diffBlock, uint256 stakeAmount) public pure returns (uint256) {
        return rewardPerBlock.mul(diffBlock).mul(stakeAmount).div(REWARD_SCALE);
    }

    function _getAmountRewardInPool(uint256 pid, address staker) private view returns (uint256) {
        LinearPoolInfo memory currentPool = linearPoolInfo[pid];
        uint256 currentIndex = stakedMapIndex[pid][staker];
        Checkpoint memory current = stakedMap[pid][staker][currentIndex];
        uint256 currentBlock = block.number;
        uint256 diffBlock = currentBlock.sub(current.blockNumber);
        uint256 reward = calculateReward(currentPool.rewardPerBlock, diffBlock, current.stakedAmount);
        return totalClaimForLatestStakeBlock[pid][staker].add(reward).sub(claimedByUser[pid][staker]);
    }

    function getAllAmountReward(address staker) public view returns (uint256) {
        uint256 totalAmount;
        for (uint i = 0; i < linearPoolInfo.length; i++) {
            uint256 pendingRewardInPool = _getAmountRewardInPool(i, staker);
            totalAmount = totalAmount.add(pendingRewardInPool);
        }
        return totalAmount;
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function _updateTotalClaimForLatestStakeBlock(uint256 pid, uint256 rewardPerBlock, Checkpoint memory checkpoint, uint256 blockNumber, address staker) private {
        uint256 diffBlock = blockNumber.sub(checkpoint.blockNumber);
        uint256 claimAmount = calculateReward(rewardPerBlock, diffBlock, checkpoint.stakedAmount);
        totalClaimForLatestStakeBlock[pid][staker] = totalClaimForLatestStakeBlock[pid][staker].add(claimAmount);
    }

    function stake(uint256 pid, uint256 amount) public pidValid(pid) {
        LinearPoolInfo memory currentPool = linearPoolInfo[pid];
        require(amount >= currentPool.minimumStakeAmount, "Too small amount");
        _stake(pid, amount, msg.sender);
        if (hasUserInPool[msg.sender][pid] == 0) {
            listUserInPool[pid].push(msg.sender);
            hasUserInPool[msg.sender][pid] = listUserInPool[pid].length;
        }

        require(
            IErc20Token(currentPool.tokenStake).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Stake failed"
        );

        emit Stake(
            msg.sender,
            amount,
            pid
        );
    }

    function _stake(uint256 pid, uint256 amount, address staker) private {
        LinearPoolInfo storage currentPool = linearPoolInfo[pid];
        uint256 blockNum = block.number;
        uint256 currentIndex = stakedMapIndex[pid][staker];
        Checkpoint storage current = stakedMap[pid][staker][currentIndex];

        _updateTotalClaimForLatestStakeBlock(pid, currentPool.rewardPerBlock, current, blockNum, staker);

        uint256 newStakedAmount = current.stakedAmount.add(amount);
        stakedMapIndex[pid][staker] = stakedMapIndex[pid][staker].add(1);
        stakedMap[pid][staker][stakedMapIndex[pid][staker]] = Checkpoint({
            blockNumber: blockNum,
            stakedAmount: newStakedAmount
        });
        currentPool.totalStaked = currentPool.totalStaked.add(amount);
    }

    /**
     * @notice Claims reward
     *
     */
    function claimReward(uint256 pid) public pidValid(pid) {
        _claim(pid, msg.sender);
    }

    function claimAllReward() public {
        address staker = msg.sender;
        uint256 totalClaim;
        for (uint i = 0; i < linearPoolInfo.length; i++) {
            uint256 amount = _getAmountRewardInPool(i, staker);
            claimedByUser[i][staker] = claimedByUser[i][staker].add(amount);
            totalClaim = totalClaim.add(amount);
        }

        require(
            IErc20Token(rewardAddress).transfer(
                staker,
                totalClaim
            ),
            "Claim failed"
        );

        emit Claim(staker, totalClaim);
    }

    function _claim(uint256 pid, address staker) private {
        uint256 amount = _getAmountRewardInPool(pid, staker);
        claimedByUser[pid][staker] = claimedByUser[pid][staker].add(amount);
        require(
            IErc20Token(rewardAddress).transfer(
                staker,
                amount
            ),
            "Claim failed"
        );
        emit Claim(staker, amount);
    }

    /**
     * @notice Withdraws the provided amount of staked
     *
     * @param amount The amount to withdraw
    */
    function withdraw(uint256 pid, uint256 amount) public pidValid(pid) {
        LinearPoolInfo storage currentPool = linearPoolInfo[pid];
        uint256 blockNum = block.number;
        address staker = msg.sender;
        require(amount >= currentPool.minimumWithdraw, "Too small amount");

        uint256 currentIndex = stakedMapIndex[pid][staker];
        Checkpoint memory current = stakedMap[pid][staker][currentIndex];
        require(amount <= current.stakedAmount && amount > 0, "Invalid amount");

        uint256 reward = _getAmountRewardInPool(pid, staker);
        _updateTotalClaimForLatestStakeBlock(pid, currentPool.rewardPerBlock, current, blockNum, staker);

        uint256 newStakedAmount = current.stakedAmount.sub(amount);
        stakedMapIndex[pid][staker] = stakedMapIndex[pid][staker].add(1);
        stakedMap[pid][staker][stakedMapIndex[pid][staker]] = Checkpoint({
            blockNumber: blockNum,
            stakedAmount: newStakedAmount
        });

        if (newStakedAmount == 0 && hasUserInPool[staker][pid] > 0) {
            uint256 pid_1 = pid; // stack to deep
            address userAddressInLatest = listUserInPool[pid_1][listUserInPool[pid_1].length - 1];
            uint256 userIndexForSender = hasUserInPool[staker][pid_1];
            uint256 indexUser = userIndexForSender.sub(1);

            listUserInPool[pid_1][indexUser] = userAddressInLatest;
            hasUserInPool[userAddressInLatest][pid_1] = indexUser.add(1);
            hasUserInPool[staker][pid_1] = 0;
            listUserInPool[pid_1].pop();
        }

        currentPool.totalStaked = currentPool.totalStaked.sub(amount);
        if (reward > 0) {
            claimedByUser[pid][staker] = claimedByUser[pid][staker].add(reward);
            require(
                IErc20Token(rewardAddress).transfer(
                    staker,
                    reward
                ),
                "Get reward failed"
            );
        }
        require(
            IErc20Token(currentPool.tokenStake).transfer(
                staker,
                amount
            ),
            "Withdraw failed"
        );

        emit Withdraw(staker, amount, reward);

    }

    function emergencyWithdraw(uint256 pid) public pidValid(pid) {
        LinearPoolInfo storage currentPool = linearPoolInfo[pid];
        address staker = msg.sender;
        uint256 blockNum = block.number;

        uint256 currentIndex = stakedMapIndex[pid][staker];
        Checkpoint memory current = stakedMap[pid][staker][currentIndex];

        require(current.stakedAmount > 0, "Not valid amount");

        _updateTotalClaimForLatestStakeBlock(pid, currentPool.rewardPerBlock, current, blockNum, staker);

        stakedMapIndex[pid][staker] = stakedMapIndex[pid][staker].add(1);
        stakedMap[pid][staker][stakedMapIndex[pid][staker]] = Checkpoint({
            blockNumber: blockNum,
            stakedAmount: 0
        });
        currentPool.totalStaked = currentPool.totalStaked.sub(current.stakedAmount);
        // rewardFromEmergencyWithdraw = rewardFromEmergencyWithdraw.add(totalClaimForLatestStakeBlock[pid][staker].sub(claimedByUser[pid][staker]));
        claimedByUser[pid][staker] = totalClaimForLatestStakeBlock[pid][staker];
        if (hasUserInPool[staker][pid] > 0) {
            uint256 pid_1 = pid; // stack to deep
            address userAddressInLatest = listUserInPool[pid_1][listUserInPool[pid_1].length - 1];
            uint256 userIndexForSender = hasUserInPool[staker][pid_1];
            uint256 indexUser = userIndexForSender.sub(1);

            listUserInPool[pid_1][indexUser] = userAddressInLatest;
            hasUserInPool[userAddressInLatest][pid_1] = indexUser.add(1);
            hasUserInPool[staker][pid_1] = 0;
            listUserInPool[pid_1].pop();
        }
        require(
            IErc20Token(currentPool.tokenStake).transfer(
                staker,
                current.stakedAmount
            ),
            "Withdraw failed"
        );
        emit EmergencyWithdraw(staker, current.stakedAmount);
    }

    function autoCoumpound(uint256 pid) public {
        LinearPoolInfo memory currentPool = linearPoolInfo[pid];
        require(currentPool.tokenStake == rewardAddress, "Pool not valid");
        address[] memory listUser = listUserInPool[pid];
        uint256 totalReward;
        for (uint256 index = 0; index < listUser.length; index++) {
            address staker = listUser[index];
            uint256 reward = _getAmountRewardInPool(pid, staker);
            totalReward = totalReward.add(reward.mul(autoCompoundingFee).div(PERCENT));
            _stake(pid, reward.mul(PERCENT.sub(autoCompoundingFee)), staker);
        }

        require(
            IErc20Token(currentPool.tokenStake).transfer(
                msg.sender,
                totalReward
            ),
            "AutoCompounding failed"
        );

        emit AutoCompounding(msg.sender, totalReward);

    }

    /*****************
     * ADMIN ACTIONS *
     *****************/

    function addNewStakingPool(
        uint256 minimumStakeAmount,
        uint256 rewardPerBlock,
        address tokenStake,
        uint256 minimumWithdraw
    ) public onlyOwner {
        linearPoolInfo.push(
            LinearPoolInfo({
                totalStaked: 0,
                minimumStakeAmount: minimumStakeAmount,
                rewardPerBlock: rewardPerBlock,
                tokenStake: tokenStake,
                minimumWithdraw: minimumWithdraw
            })
        );

        emit PoolCreated(linearPoolInfo.length-1, minimumStakeAmount, rewardPerBlock, tokenStake, minimumWithdraw);
    }

    function setNewRewardToken(address newToken) public onlyOwner {
        rewardAddress = newToken;
    }

    // function claimRewardFromEmergencyWithdraw() public onlyOwner {
    //     uint256 amount = rewardFromEmergencyWithdraw;
    //     rewardFromEmergencyWithdraw = 0;
    //     require(
    //         IErc20Token(rewardAddress).transfer(
    //             msg.sender,
    //             amount
    //         ),
    //         "RewardFromEmergencyWithdraw failed"
    //     );
    //     emit RewardFromEmergencyWithdraw(msg.sender, amount);
    // }

    function setStakingPool(
        uint256 pid,
        uint256 minimumStakeAmount,
        uint256 rewardPerBlock,
        uint256 minimumWithdraw
    ) public onlyOwner pidValid(pid) {
        LinearPoolInfo storage pool = linearPoolInfo[pid];
        pool.minimumStakeAmount = minimumStakeAmount;
        pool.rewardPerBlock = rewardPerBlock;
        pool.minimumWithdraw = minimumWithdraw;
        emit ChangeStakingPoolSetting(
            pid,
            minimumStakeAmount,
            rewardPerBlock,
            minimumWithdraw
        );
    }

    function changeAutoCompoundingFee(uint256 _fee) public onlyOwner {
        uint256 oldFee = autoCompoundingFee;
        autoCompoundingFee = _fee;
        emit ChangeAutoCompoundingFee(oldFee ,_fee);
    }

    /********************
     * VALUE ACTIONS *
     ********************/

    /**
     * @notice Does not accept BNB.
     */
    receive () external payable {
        revert();
    }

}

pragma solidity ^0.8.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.0;

interface IErc20Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.0;

/// @title Staking Storage Contract
contract StakingStorage {
    uint256 public constant PERCENT = 10000;
    uint256 public constant REWARD_SCALE = 10**18;
    struct Checkpoint {
        uint256 blockNumber;
        uint256 stakedAmount;
    }

    struct LinearPoolInfo {
        uint256 totalStaked;
        uint256 minimumStakeAmount;
        uint256 rewardPerBlock;
        address tokenStake;
        uint256 minimumWithdraw;
    }

    // config
    address public rewardAddress;
    uint256 public autoCompoundingFee;

    //state
    // uint256 public rewardFromEmergencyWithdraw;
    // pool id => address user => total reward claimed;
    mapping (uint256 => mapping(address => uint256)) public claimedByUser;
    // pool id => address user => total reward in latest checkpoint
    mapping (uint256 => mapping(address => uint256)) public totalClaimForLatestStakeBlock;
    // pool id => address user => array checkpoint for user
    mapping (uint256 => mapping(address => mapping (uint256 => Checkpoint))) public stakedMap;
    // pool id => address user => latest index checkpoint for user
    mapping (uint256 => mapping(address => uint256)) public stakedMapIndex;
    //pool id => list address user in pool.
    mapping (uint256 => address[]) public listUserInPool;
    // address user => pool id => index address user in listUserInPool;
    mapping (address => mapping(uint256 => uint256)) public hasUserInPool; // We using value 0 to check user has been pool. So, index address user in listUserInPool will increase 1; 
    LinearPoolInfo[] public linearPoolInfo;
}

pragma solidity ^0.8.0;

/// @title Staking Event Contract
contract StakingEvent {

    event Stake(
        address indexed staker,
        uint256 indexed amount,
        uint256 indexed pid
    );

    event Claim(
        address indexed toAddress,
        uint256 indexed amount
    );

    event Withdraw(
        address indexed toAddress,
        uint256 indexed amount,
        uint256 reward
    );

    event EmergencyWithdraw(
        address indexed toAddress,
        uint256 indexed amount
    );

    event GuardianshipTransferAuthorization(
        address indexed authorizedAddress
    );

    event GuardianUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event MinimumStakeAmountUpdate(
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    event DepositRewardPool(
        address indexed depositor,
        uint256 indexed amount
    );

    event WithdrawRewardPool(
        address indexed toAddress,
        uint256 indexed amount
    );

    event AutoCompounding(
        address indexed toAddress,
        uint256 indexed amount
    );

    event RewardFromEmergencyWithdraw(
        address indexed toAddress,
        uint256 indexed amount
    );

    event PoolCreated(
        uint256 pid,
        uint256 minimumStakeAmount,
        uint256 rewardPerBlock,
        address tokenStake,
        uint256 minimumWithdraw
    );

    event ChangeAutoCompoundingFee(
        uint256 oldFee,
        uint256 newFee
    );

    event ChangeStakingPoolSetting(
        uint256 pid,
        uint256 minimumStakeAmount,
        uint256 rewardPerBlock,
        uint256 minimumWithdraw
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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