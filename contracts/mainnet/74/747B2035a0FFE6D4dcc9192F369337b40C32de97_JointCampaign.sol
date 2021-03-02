// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

pragma experimental ABIEncoderV2;

import {Ownable} from "../lib/Ownable.sol";
import {SafeMath} from "../lib/SafeMath.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";
import {Decimal} from "../lib/Decimal.sol";

import {IERC20} from "../token/IERC20.sol";

import {IMozartCoreV2} from "../debt/mozart/IMozartCoreV2.sol";
import {MozartTypes} from "../debt/mozart/MozartTypes.sol";

contract JointCampaign is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== Structs ========== */

    struct Staker {
        uint256 positionId;
        uint256 debtSnapshot;
        uint256 balance;
        uint256 arcRewardPerTokenPaid;
        uint256 collabRewardPerTokenPaid;
        uint256 arcRewardsEarned;
        uint256 collabRewardsEarned;
        uint256 arcRewardsReleased;
        uint256 collabRewardsReleased;
    }

    /* ========== Variables ========== */

    bool public isInitialized;

    IERC20 public arcRewardToken;
    IERC20 public collabRewardToken;
    IERC20 public stakingToken;

    IMozartCoreV2 public stateContract;

    address public arcDAO;
    address public arcRewardsDistributor;
    address public collabRewardsDistributor;

    mapping (address => Staker) public stakers;

    uint256 public arcPeriodFinish = 0;
    uint256 public collabPeriodFinish = 0;
    uint256 public rewardsDuration = 0;
    uint256 public arcLastUpdateTime;
    uint256 public collabLastUpdateTime;

    uint256 public arcRewardRate = 0;
    uint256 public collabRewardRate = 0;

    uint256 public arcRewardPerTokenStored;
    uint256 public collabPerTokenStored;

    Decimal.D256 public daoAllocation;
    Decimal.D256 public slasherCut;

    uint8 public stakeToDebtRatio;

    bool public arcTokensClaimable;
    bool public collabTokensClaimable;

    uint256 private _totalSupply;

    /* ========== Events ========== */

    event RewardAdded (uint256 _reward, address _rewardToken);

    event Staked(address indexed _user, uint256 _amount);

    event Withdrawn(address indexed _user, uint256 _amount);

    event RewardPaid(address indexed _user, uint256 _arcReward, uint256 _collabReward);

    event RewardsDurationUpdated(uint256 _newDuration);

    event ERC20Recovered(address _token, uint256 _amount);

    event PositionStaked(address _address, uint256 _positionId);

    event ArcClaimableStatusUpdated(bool _status);

    event CollabClaimableStatusUpdated(bool _status);

    event UserSlashed(address _user, address _slasher, uint256 _arcPenalty, uint256 _collabPenalty);

    event CollabRewardsDistributorUpdated(address _rewardsDistributor);

    event ArcRewardsDistributorUpdated(address _rewardsDistributor);

    event CollabRecovered(uint256 _amount);

    /* ========== Modifiers ========== */

    modifier updateReward(address _account, address _rewardToken) {
        _updateReward(_account, _rewardToken);
        _;
    }

    modifier onlyRewardDistributors() {
        require(
            msg.sender == arcRewardsDistributor || msg.sender == collabRewardsDistributor,
            "Caller is not a reward distributor"
        );
        _;
    }

    modifier onlyCollabDistributor() {
        require(
            msg.sender == collabRewardsDistributor,
            "Caller is not the collab rewards distributor"
        );
        _;
    }

    modifier verifyRewardToken(address _rewardTokenAddress) {
        bool isArcToken = _rewardTokenAddress == address(arcRewardToken);
        bool iscollabToken = _rewardTokenAddress == address(collabRewardToken);

        require (
            isArcToken || iscollabToken,
            "The reward token address does not correspond to one of the rewards tokens."
        );
        _;
    }

    /* ========== Admin Functions ========== */

    function setcollabRewardsDistributor(
        address _rewardsDistributor
    )
        external
        onlyCollabDistributor
    {
        require(
            collabRewardsDistributor != _rewardsDistributor,
            "Cannot set the same rewards distributor"
        );

        collabRewardsDistributor = _rewardsDistributor;
        emit CollabRewardsDistributorUpdated(_rewardsDistributor);
    }

    function setArcRewardsDistributor(
        address _rewardsDistributor
    )
        external
        onlyOwner
    {
        require(
            arcRewardsDistributor != _rewardsDistributor,
            "Cannot set the same rewards distributor"
        );

        arcRewardsDistributor = _rewardsDistributor;
        emit ArcRewardsDistributorUpdated(_rewardsDistributor);
    }

    function setRewardsDuration(
        uint256 _rewardsDuration
    )
        external
        onlyOwner
    {
        uint256 periodFinish = arcPeriodFinish > collabPeriodFinish
            ? arcPeriodFinish
            : collabPeriodFinish;

        require(
            periodFinish == 0 || getCurrentTimestamp() > periodFinish,
            "Prev period must be complete before changing duration for new period"
        );

        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /**
     * @notice Sets the reward amount for the given reward token. There contract must
     *          already have at least as much amount as the given `_reward`
     *
     * @param _reward The amount of the reward
     * @param _rewardToken The address of the reward token
     */
    function notifyRewardAmount(
        uint256 _reward,
        address _rewardToken
    )
        external
        onlyRewardDistributors
        verifyRewardToken(_rewardToken)
        updateReward(address(0), _rewardToken)
    {
        require(
            rewardsDuration > 0,
            "Rewards duration is not set"
        );

        uint256 remaining;
        uint256 leftover;

        if (_rewardToken == address(arcRewardToken)) {
            require(
                msg.sender == arcRewardsDistributor,
                "Only the ARCx rewards distributor can notify the amount of ARCx rewards"
            );

            if (getCurrentTimestamp() >= arcPeriodFinish) {
                arcRewardRate = _reward.div(rewardsDuration);
            } else {
                remaining = arcPeriodFinish.sub(getCurrentTimestamp());
                leftover = remaining.mul(arcRewardRate);
                arcRewardRate = _reward.add(leftover).div(rewardsDuration);

            }

            require(
                arcRewardRate <= arcRewardToken.balanceOf(address(this)).div(rewardsDuration),
                "Provided reward too high for the balance of ARCx token"
            );

            arcPeriodFinish = getCurrentTimestamp().add(rewardsDuration);
            arcLastUpdateTime = getCurrentTimestamp();
        } else {
            require(
                msg.sender == collabRewardsDistributor,
                "Only the collab rewards distributor can notify the amount of collab rewards"
            );

            // collab token
            if (getCurrentTimestamp() >= collabPeriodFinish) {
                collabRewardRate = _reward.div(rewardsDuration);
            } else {
                remaining = collabPeriodFinish.sub(getCurrentTimestamp());
                leftover = remaining.mul(collabRewardRate);
                collabRewardRate = _reward.add(leftover).div(rewardsDuration);

            }

            require(
                collabRewardRate <= collabRewardToken.balanceOf(address(this)).div(rewardsDuration),
                "Provided reward too high for the balance of collab token"
            );

            collabPeriodFinish = getCurrentTimestamp().add(rewardsDuration);
            collabLastUpdateTime = getCurrentTimestamp();
        }

        emit RewardAdded(_reward, _rewardToken);
    }

    /**
     * @notice Allows owner to recover any ERC20 token sent to this contract, except the staking
     *          okens and the reward tokens - with the exception of ARCx surplus that was transfered.
     *
     * @param _tokenAddress the address of the token
     * @param _tokenAmount to amount to recover
     */
    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        onlyOwner
    {
        // If _tokenAddress is ARCx, only allow its recovery if the amount is not greater than
        // the current reward
        if (_tokenAddress == address(arcRewardToken) && rewardsDuration > 0) {
            uint256 arcBalance = arcRewardToken.balanceOf(address(this));

            require(
                arcRewardRate <= arcBalance.sub(_tokenAmount).div(rewardsDuration),
                "Only the surplus of the reward can be recovered, not more"
            );
        }

        // Cannot recover the staking token or the collab rewards token
        require(
            _tokenAddress != address(stakingToken) && _tokenAddress != address(collabRewardToken),
            "Cannot withdraw the staking or collab reward tokens"
        );

        IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
        emit ERC20Recovered(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Lets the collab reward distributor recover a desired amount of collab as long as that
     *          amount is not greater than the reward to recover
     *
     * @param _amount The amount of collab to recover
     */
    function recovercollab(
        uint256 _amount
    )
        external
        onlyCollabDistributor
    {
        if (rewardsDuration > 0) {
            uint256 collabBalance = collabRewardToken.balanceOf(address(this));

            require(
                collabRewardRate <= collabBalance.sub(_amount).div(rewardsDuration),
                "Only the surplus of the reward can be recovered, not more"
            );
        }

        collabRewardToken.safeTransfer(msg.sender, _amount);
        emit CollabRecovered(_amount);
    }

    function setArcTokensClaimable(
        bool _enabled
    )
        external
        onlyOwner
    {
        arcTokensClaimable = _enabled;

        emit ArcClaimableStatusUpdated(_enabled);
    }

    function setCollabTokensClaimable(
        bool _enabled
    )
        external
        onlyOwner
    {
        collabTokensClaimable = _enabled;

        emit CollabClaimableStatusUpdated(_enabled);
    }

    function init(
        address _arcDAO,
        address _arcRewardsDistributor,
        address _collabRewardsDistributor,
        address _arcRewardToken,
        address _collabRewardToken,
        address _stakingToken,
        Decimal.D256 memory _daoAllocation,
        Decimal.D256 memory _slasherCut,
        uint8 _stakeToDebtRatio,
        address _stateContract
    )
        public
        onlyOwner
    {
        require(
            !isInitialized &&
            _arcDAO != address(0) &&
            _arcRewardsDistributor != address(0) &&
            _collabRewardsDistributor != address(0) &&
            _arcRewardToken != address(0) &&
            _collabRewardToken != address(0) &&
            _stakingToken != address(0) &&
            _daoAllocation.value > 0 &&
            _slasherCut.value > 0 &&
            _stakeToDebtRatio > 0 &&
            _stateContract != address(0),
            "One or more values is empty"
        );

        isInitialized = true;

        arcDAO = _arcDAO;
        arcRewardsDistributor = _arcRewardsDistributor;
        collabRewardsDistributor = _collabRewardsDistributor;
        arcRewardToken = IERC20(_arcRewardToken);
        collabRewardToken = IERC20(_collabRewardToken);
        stakingToken = IERC20(_stakingToken);

        daoAllocation = _daoAllocation;
        slasherCut = _slasherCut;
        stakeToDebtRatio = _stakeToDebtRatio;

        stateContract = IMozartCoreV2(_stateContract);
    }

    /* ========== View Functions ========== */

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address account
    )
        public
        view
        returns (uint256)
    {
        return stakers[account].balance;
    }

    function lastTimeRewardApplicable(
        address _rewardToken
    )
        public
        view
        verifyRewardToken(_rewardToken)
        returns (uint256)
    {
        uint256 relevantPeriod = _rewardToken == address(arcRewardToken) ? arcPeriodFinish : collabPeriodFinish;

        return getCurrentTimestamp() < relevantPeriod ? getCurrentTimestamp() : relevantPeriod;
    }

    function arcRewardPerTokenUser()
        external
        view
        returns (uint256)
    {
        if (_totalSupply == 0) {
            return arcRewardPerTokenStored;
        }

        return
            Decimal.mul(
                arcRewardPerTokenStored.add(
                    lastTimeRewardApplicable(address(arcRewardToken))
                        .sub(arcLastUpdateTime)
                        .mul(arcRewardRate)
                        .mul(1e18)
                        .div(_totalSupply)
                ),
                userAllocation()
            );
    }

    function collabRewardPerToken()
        external
        view
        returns (uint256)
    {
        if (_totalSupply == 0) {
            return collabPerTokenStored;
        }

        return collabPerTokenStored.add(
            lastTimeRewardApplicable(address(collabRewardToken))
                .sub(collabLastUpdateTime)
                .mul(collabRewardRate)
                .mul(1e18)
                .div(_totalSupply)
        );
    }

    function _actualEarned(
        address _account,
        address _rewardTokenAddress
    )
        internal
        view
        verifyRewardToken(_rewardTokenAddress)
        returns (uint256)
    {
        uint256 stakerBalance = stakers[_account].balance;

        if (_rewardTokenAddress == address(arcRewardToken)) {
            return
                stakerBalance.mul(
                    _rewardPerToken(address(arcRewardToken))
                    .sub(stakers[_account].arcRewardPerTokenPaid)
                )
                .div(1e18)
                .add(stakers[_account].arcRewardsEarned);
        }

        return
            stakerBalance.mul(
                _rewardPerToken(address(collabRewardToken))
                .sub(stakers[_account].collabRewardPerTokenPaid)
            )
            .div(1e18)
            .add(stakers[_account].collabRewardsEarned);
    }

    function arcEarned(
        address _account
    )
        external
        view
        returns (uint256)
    {
        return Decimal.mul(
            _actualEarned(_account, address(arcRewardToken)),
            userAllocation()
        );
    }

    function collabEarned(
        address _account
    )
        external
        view
        returns (uint256)
    {
        return _actualEarned(_account, address(collabRewardToken));
    }

    function getArcRewardForDuration()
        external
        view
        returns (uint256)
    {
        return arcRewardRate.mul(rewardsDuration);
    }

    function getCollabRewardForDuration()
        external
        view
        returns (uint256)
    {
        return collabRewardRate.mul(rewardsDuration);
    }

    function getCurrentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function isMinter(
        address _user,
        uint256 _amount,
        uint256 _positionId
    )
        public
        view
        returns (bool)
    {
        MozartTypes.Position memory position = stateContract.getPosition(_positionId);

        if (position.owner != _user) {
            return false;
        }

        return uint256(position.borrowedAmount.value) >= _amount;
    }

    function  userAllocation()
        public
        view
        returns (Decimal.D256 memory)
    {
        return Decimal.sub(
            Decimal.one(),
            daoAllocation.value
        );
    }

    /* ========== Mutative Functions ========== */

    function stake(
        uint256 _amount,
        uint256 _positionId
    )
        external
        updateReward(msg.sender, address(0))
    {
        uint256 totalBalance = balanceOf(msg.sender).add(_amount);

        // Setting each variable invididually means we don't overwrite
        Staker storage staker = stakers[msg.sender];

        if (staker.positionId != 0) {
            require (
                staker.positionId == _positionId,
                "You cannot stake based on a different debt position"
            );
        }

        require(
            stakeToDebtRatio != 0,
            "The stake to debt ratio cannot be 0"
        );

        uint256 debtRequirement = totalBalance.div(uint256(stakeToDebtRatio));

        require(
            isMinter(
                msg.sender,
                debtRequirement,
                _positionId
            ),
            "Must be a valid minter"
        );

        // This stops an attack vector where a user stakes a lot of money
        // then drops the debt requirement by staking less before the deadline
        // to reduce the amount of debt they need to lock in

        require(
            debtRequirement >= staker.debtSnapshot,
            "Your new debt requirement cannot be lower than last time"
        );

        if (staker.positionId == 0) {
            staker.positionId = _positionId;
        }
        staker.debtSnapshot = debtRequirement;
        staker.balance = staker.balance.add(_amount);

        _totalSupply = _totalSupply.add(_amount);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    function slash(
        address _user
    )
        external
        updateReward(_user, address(0))
    {
        require(
            _user != msg.sender,
            "You cannot slash yourself"
        );

        uint256 currentTime = getCurrentTimestamp();
        require(
            currentTime < arcPeriodFinish ||
            currentTime < collabPeriodFinish,
            "You cannot slash after the reward period"
        );

        Staker storage userStaker = stakers[_user];

        require(
            isMinter(
                _user,
                userStaker.debtSnapshot,
                userStaker.positionId
            ) == false,
            "You can't slash a user who is a valid minter"
        );

        uint256 arcPenalty = userStaker.arcRewardsEarned.sub(userStaker.arcRewardsReleased);
        uint256 arcBounty = Decimal.mul(arcPenalty, slasherCut);

        uint256 collabPenalty = userStaker.collabRewardsEarned.sub(userStaker.collabRewardsReleased);

        stakers[msg.sender].arcRewardsEarned = stakers[msg.sender].arcRewardsEarned.add(arcBounty);
        stakers[msg.sender].collabRewardsEarned = stakers[msg.sender].collabRewardsEarned.add(collabPenalty);

        stakers[arcRewardsDistributor].arcRewardsEarned = stakers[arcRewardsDistributor].arcRewardsEarned.add(
            arcPenalty.sub(arcBounty)
        );

        userStaker.arcRewardsEarned = userStaker.arcRewardsEarned.sub(arcPenalty);
        userStaker.collabRewardsEarned = userStaker.collabRewardsEarned.sub(collabPenalty);

        emit UserSlashed(
            _user,
            msg.sender,
            arcPenalty,
            collabPenalty
        );
    }

    function getReward(address _user)
        public
        updateReward(_user, address(0))
    {
        Staker storage staker = stakers[_user];
        uint256 arcPayableAmount;
        uint256 collabPayableAmount;

        require(
            collabTokensClaimable || arcTokensClaimable,
            "At least one reward token must be claimable"
        );

        if (collabTokensClaimable) {
            collabPayableAmount = staker.collabRewardsEarned.sub(staker.collabRewardsReleased);
            staker.collabRewardsReleased = staker.collabRewardsReleased.add(collabPayableAmount);

            collabRewardToken.safeTransfer(_user, collabPayableAmount);
        }

        if (arcTokensClaimable) {
            arcPayableAmount = staker.arcRewardsEarned.sub(staker.arcRewardsReleased);
            staker.arcRewardsReleased = staker.arcRewardsReleased.add(arcPayableAmount);

            uint256 daoPayable = Decimal.mul(arcPayableAmount, daoAllocation);
            arcRewardToken.safeTransfer(arcDAO, daoPayable);
            arcRewardToken.safeTransfer(_user, arcPayableAmount.sub(daoPayable));
        }

        emit RewardPaid(_user, arcPayableAmount, collabPayableAmount);
    }

    function withdraw(
        uint256 amount
    )
        public
        updateReward(msg.sender, address(0))
    {
        require(
            amount >= 0,
            "Cannot withdraw less than 0"
        );

        _totalSupply = _totalSupply.sub(amount);
        stakers[msg.sender].balance = stakers[msg.sender].balance.sub(amount);

        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function exit()
        external
    {
        getReward(msg.sender);
        withdraw(balanceOf(msg.sender));
    }

    /* ========== Private Functions ========== */

    function _updateReward(
        address _account,
        address _rewardToken
    )
        private
    {
        require(
            _rewardToken == address(0) ||
            _rewardToken == address(arcRewardToken) ||
            _rewardToken == address(collabRewardToken),
            "The reward token can either be 0 or a valid reward token"
        );

        // If an individual reward token is updated, only update the relevant variables
        if (_rewardToken == address(0)) {
            arcRewardPerTokenStored = _rewardPerToken(address(arcRewardToken));
            collabPerTokenStored = _rewardPerToken(address(collabRewardToken));

            arcLastUpdateTime = lastTimeRewardApplicable(address(arcRewardToken));
            collabLastUpdateTime = lastTimeRewardApplicable(address(collabRewardToken));

        } else if (_rewardToken == address(arcRewardToken)) {
            arcRewardPerTokenStored = _rewardPerToken(address(arcRewardToken));
            arcLastUpdateTime = lastTimeRewardApplicable(address(arcRewardToken));

        } else {
            collabPerTokenStored = _rewardPerToken(address(collabRewardToken));
            collabLastUpdateTime = lastTimeRewardApplicable(address(collabRewardToken));
        }

        if (_account != address(0)) {
            stakers[_account].arcRewardsEarned = _actualEarned(_account, address(arcRewardToken));
            stakers[_account].arcRewardPerTokenPaid = arcRewardPerTokenStored;

            stakers[_account].collabRewardsEarned = _actualEarned(_account, address(collabRewardToken));
            stakers[_account].collabRewardPerTokenPaid = collabPerTokenStored;
        }
    }

    function _rewardPerToken(
        address _rewardTokenAddress
    )
        private
        view
        verifyRewardToken(_rewardTokenAddress)
        returns (uint256)
    {
        if (_rewardTokenAddress == address(arcRewardToken)) {
            if (_totalSupply == 0) {
                return arcRewardPerTokenStored;
            }

            return arcRewardPerTokenStored.add(
                lastTimeRewardApplicable(address(arcRewardToken))
                    .sub(arcLastUpdateTime)
                    .mul(arcRewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
        } else {
            if (_totalSupply == 0) {
                return collabPerTokenStored;
            }

            return collabPerTokenStored.add(
                lastTimeRewardApplicable(address(collabRewardToken))
                    .sub(collabLastUpdateTime)
                    .mul(collabRewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
        }
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.5.16;

import {IERC20} from "../token/IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                0x23b872dd,
                from,
                to,
                value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FROM_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    )
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
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);

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
    )
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "../lib/SafeMath.sol";
import {Math} from "./Math.sol";

/**
 * @title Decimal
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Functions ============

    function one()
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory d
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(BASE) });
    }

    function mul(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, d.value, BASE);
    }

    function mul(
        D256 memory d1,
        D256 memory d2
    )
        internal
        pure
        returns (D256 memory)
    {
        return Decimal.D256({ value: Math.getPartial(d1.value, d2.value, BASE) });
    }

    function div(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, BASE, d.value);
    }

    function add(
        D256 memory d,
        uint256 amount
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(amount) });
    }

    function sub(
        D256 memory d,
        uint256 amount
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.sub(amount) });
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "./SafeMath.sol";

/**
 * @title Math
 *
 * Library for non-standard Math functions
 */
library Math {
    using SafeMath for uint256;

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        require(
            result == number,
            "Math: Unsafe cast to uint128"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {MozartTypes} from "./MozartTypes.sol";

interface IMozartCoreV2 {
    function getPosition(
        uint256 id
    )
        external
        view
        returns (MozartTypes.Position memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Amount} from "../../lib/Amount.sol";

library MozartTypes {

    /* ========== Structs ========== */

    struct Position {
        address owner;
        Amount.Principal collateralAmount;
        Amount.Principal borrowedAmount;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "../lib/SafeMath.sol";
import {Math} from "../lib/Math.sol";

library Amount {

    using Math for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // A Principal Amount is an amount that's been adjusted by an index

    struct Principal {
        bool sign; // true if positive
        uint256 value;
    }

    function zero()
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: false,
            value: 0
        });
    }

    function sub(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (Principal memory)
    {
        return add(a, negative(b));
    }

    function add(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (Principal memory)
    {
        Principal memory result;

        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Principal memory a
    )
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: !a.sign,
            value: a.value
        });
    }

    function calculateAdjusted(
        Principal memory a,
        uint256 index
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(a.value, index, BASE);
    }

    function calculatePrincipal(
        uint256 value,
        uint256 index,
        bool sign
    )
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: sign,
            value: Math.getPartial(value, BASE, index)
        });
    }

}