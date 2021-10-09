// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {Ownable} from "../lib/Ownable.sol";
import {Bytes32} from "../lib/Bytes32.sol";
import {PassportScoreVerifiable} from "../lib/PassportScoreVerifiable.sol";

import {IERC20} from "../token/IERC20.sol";
import {IPermittableERC20} from "../token/IPermittableERC20.sol";

import {CampaignStorage} from "./CampaignStorage.sol";
import {ISapphirePassportScores} from "../sapphire/ISapphirePassportScores.sol";
import {SapphireTypes} from "../sapphire/SapphireTypes.sol";

/**
 * @notice A farm that requires a defi passport with a good credit
 *         score to participate that has two reward tokens.
 */
contract JointPassportCampaign is CampaignStorage, PassportScoreVerifiable, Ownable {

    /* ========== Libraries ========== */

    using Bytes32 for bytes32;

    /* ========== Structs ========== */

    struct Staker {
        uint256 balance;
        uint256 arcRewardPerTokenPaid;
        uint256 collabRewardPerTokenPaid;
        uint256 arcRewardsEarned;
        uint256 collabRewardsEarned;
        uint256 arcRewardsReleased;
        uint256 collabRewardsReleased;
    }

    /* ========== Variables ========== */

    IERC20 public collabRewardToken;

    address public collabRewardsDistributor;

    mapping (address => Staker) public stakers;

    uint256 public collabPeriodFinish = 0;
    uint256 public collabLastUpdateTime;

    uint256 public collabPerTokenStored;

    uint256 public maxStakePerUser;
    uint16 public creditScoreThreshold;

    uint256 public collabRewardRate = 0;

    bool public collabTokensClaimable;

    /**
     * @dev The protocol value to be used in the score proofs
     */
    bytes32 private _proofProtocol = "arcx.creditScore";

    /* ========== Events ========== */

    event RewardAdded (
        uint256 _reward,
        address _rewardToken
    );

    event Staked(
        address indexed _user,
        uint256 _amount
    );

    event Withdrawn(
        address indexed _user,
        uint256 _amount
    );

    event RewardPaid(
        address indexed _user,
        uint256 _arcReward,
        uint256 _collabReward
    );

    event RewardsDurationUpdated(uint256 _newDuration);

    event Recovered(
        address _token,
        uint256 _amount
    );

    event ArcClaimableStatusUpdated(bool _status);

    event CollabClaimableStatusUpdated(bool _status);

    event RewardsDistributorUpdated(address _rewardsDistributor);

    event CollabRewardsDistributorUpdated(address _rewardsDistributor);

    event CollabRecovered(uint256 _amount);

    event CreditScoreThresholdSet(uint16 _newThreshold);

    event MaxStakePerUserSet(uint256 _newMaxStakePerUser);

    event ProofProtocolSet(string _protocol);

    /* ========== Modifiers ========== */

    modifier updateReward(
        address _account,
        address _rewardToken
    ) {
        _updateRewardTokenCalculations(_rewardToken);
        _updateRewardsForUser(_account);
        _;
    }

    modifier onlyRewardDistributors() {
        require(
            msg.sender == rewardsDistributor || msg.sender == collabRewardsDistributor,
            "JointPassportCampaign: caller is not a reward distributor"
        );
        _;
    }

    modifier onlyCollabDistributor() {
        require(
            msg.sender == collabRewardsDistributor,
            "JointPassportCampaign: caller is not the collab rewards distributor"
        );
        _;
    }

    modifier verifyRewardToken(address _rewardTokenAddress) {
        bool isArcToken = _rewardTokenAddress == address(rewardToken);
        bool isCollabToken = _rewardTokenAddress == address(collabRewardToken);

        require(
            isArcToken || isCollabToken,
            "JointPassportCampaign: invalid reward token"
        );
        _;
    }

    /* ========== Constructor ========== */

    constructor(
        address _arcDAO,
        address _rewardsDistributor,
        address _collabRewardsDistributor,
        address _rewardToken,
        address _collabRewardToken,
        address _stakingToken,
        address _creditScoreContract,
        uint256 _daoAllocation,
        uint256 _maxStakePerUser,
        uint16 _creditScoreThreshold
    )
        public
    {
        require(
            _arcDAO != address(0) &&
            _rewardsDistributor != address(0) &&
            _collabRewardsDistributor != address(0) &&
            _rewardToken.isContract() &&
            _collabRewardToken.isContract() &&
            _stakingToken.isContract() &&
            _daoAllocation > 0 &&
            _creditScoreContract.isContract() &&
            _creditScoreThreshold > 0,
            "JointPassportCampaign: one or more values is empty"
        );

        arcDAO                      = _arcDAO;
        rewardsDistributor          = _rewardsDistributor;
        collabRewardsDistributor    = _collabRewardsDistributor;
        rewardToken                 = IERC20(_rewardToken);
        collabRewardToken           = IERC20(_collabRewardToken);
        stakingToken                = IPermittableERC20(_stakingToken);
        creditScoreThreshold        = _creditScoreThreshold;
        maxStakePerUser             = _maxStakePerUser;
        daoAllocation               = _daoAllocation;
        passportScoresContract      = ISapphirePassportScores(_creditScoreContract);
    }

    /* ========== Admin Functions ========== */

    function setCollabRewardsDistributor(
        address _rewardsDistributor
    )
        external
        onlyCollabDistributor
    {
        require(
            collabRewardsDistributor != _rewardsDistributor,
            "JointPassportCampaign: cannot set the same rewards distributor"
        );

        collabRewardsDistributor = _rewardsDistributor;
        emit CollabRewardsDistributorUpdated(_rewardsDistributor);
    }

    function setRewardsDistributor(
        address _rewardsDistributor
    )
        external
        onlyOwner
    {
        require(
            rewardsDistributor != _rewardsDistributor,
            "JointPassportCampaign: cannot set the same rewards distributor"
        );

        rewardsDistributor = _rewardsDistributor;
        emit RewardsDistributorUpdated(_rewardsDistributor);
    }

    function setRewardsDuration(
        uint256 _rewardsDuration
    )
        external
        onlyOwner
    {
        uint256 periodFinish = periodFinish > collabPeriodFinish
            ? periodFinish
            : collabPeriodFinish;

        require(
            periodFinish == 0 || currentTimestamp() > periodFinish,
            "JointPassportCampaign: previous period not yet finished"
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
            "JointPassportCampaign: rewards duration is not set"
        );

        uint256 remaining;
        uint256 leftover;

        if (_rewardToken == address(rewardToken)) {
            require(
                msg.sender == rewardsDistributor,
                "JointPassportCampaign: only ARCx distributor can notify ARCx rewards"
            );

            if (currentTimestamp() >= periodFinish) {
                rewardRate = _reward.div(rewardsDuration);
            } else {
                remaining = periodFinish.sub(currentTimestamp());
                leftover = remaining.mul(rewardRate);
                rewardRate = _reward.add(leftover).div(rewardsDuration);

            }

            require(
                rewardRate <= rewardToken.balanceOf(address(this)).div(rewardsDuration),
                "JointPassportCampaign: not enough ARCx balance on the contract"
            );

            periodFinish = currentTimestamp().add(rewardsDuration);
            lastUpdateTime = currentTimestamp();
        } else {
            require(
                msg.sender == collabRewardsDistributor,
                "JointPassportCampaign: only the collab distributor can notify collab rewards"
            );

            // collab token
            if (currentTimestamp() >= collabPeriodFinish) {
                collabRewardRate = _reward.div(rewardsDuration);
            } else {
                remaining = collabPeriodFinish.sub(currentTimestamp());
                leftover = remaining.mul(collabRewardRate);
                collabRewardRate = _reward.add(leftover).div(rewardsDuration);

            }

            require(
                collabRewardRate <= collabRewardToken.balanceOf(address(this)).div(rewardsDuration),
                "JointPassportCampaign: not enough collab token balance on the contract"
            );

            collabPeriodFinish = currentTimestamp().add(rewardsDuration);
            collabLastUpdateTime = currentTimestamp();
        }

        emit RewardAdded(_reward, _rewardToken);
    }

    /**
     * @notice Allows owner to recover any ERC20 token sent to this contract, except the staking
     *         tokens and the reward tokens - with the exception of ARCx surplus that was transferred.
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
        if (_tokenAddress == address(rewardToken) && rewardsDuration > 0) {
            uint256 arcBalance = rewardToken.balanceOf(address(this));

            require(
                rewardRate <= arcBalance.sub(_tokenAmount).div(rewardsDuration),
                "JointPassportCampaign: only the surplus of the reward can be recovered"
            );
        }

        // Cannot recover the staking token or the collab rewards token
        require(
            _tokenAddress != address(stakingToken) && _tokenAddress != address(collabRewardToken),
            "JointPassportCampaign: cannot withdraw the staking or collab reward tokens"
        );

        IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Lets the collab reward distributor recover a desired amount of collab as long as that
     *          amount is not greater than the reward to recover
     *
     * @param _amount The amount of collab to recover
     */
    function recoverCollab(
        uint256 _amount
    )
        external
        onlyCollabDistributor
    {
        if (rewardsDuration > 0) {
            uint256 collabBalance = collabRewardToken.balanceOf(address(this));

            require(
                collabRewardRate <= collabBalance.sub(_amount).div(rewardsDuration),
                "JointPassportCampaign: only the surplus of the reward can be recovered"
            );
        }

        collabRewardToken.safeTransfer(msg.sender, _amount);
        emit CollabRecovered(_amount);
    }

    function setTokensClaimable(
        bool _enabled
    )
        external
        onlyOwner
    {
        tokensClaimable = _enabled;

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

    function setCreditScoreThreshold(
        uint16 _newThreshold
    )
        external
        onlyOwner
    {
        creditScoreThreshold = _newThreshold;

        emit CreditScoreThresholdSet(creditScoreThreshold);
    }

    function setMaxStakePerUser(
        uint256 _maxStakePerUser
    )
        external
        onlyOwner
    {
        maxStakePerUser = _maxStakePerUser;

        emit MaxStakePerUserSet(maxStakePerUser);
    }

    function setProofProtocol(
        bytes32 _protocol
    )
        external
        onlyOwner
    {
        _proofProtocol = _protocol;

        emit ProofProtocolSet(_proofProtocol.toString());
    }

    /* ========== View Functions ========== */

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
        uint256 relevantPeriod = _rewardToken == address(rewardToken) ? periodFinish : collabPeriodFinish;

        return currentTimestamp() < relevantPeriod ? currentTimestamp() : relevantPeriod;
    }

    function arcRewardPerTokenUser()
        external
        view
        returns (uint256)
    {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(
            lastTimeRewardApplicable(address(rewardToken))
                .sub(lastUpdateTime)
                .mul(rewardRate)
                .mul(BASE)
                .div(totalSupply)
        )
            .mul(userAllocation())
            .div(BASE);

    }

    function collabRewardPerToken()
        external
        view
        returns (uint256)
    {
        if (totalSupply == 0) {
            return collabPerTokenStored;
        }

        return collabPerTokenStored.add(
            lastTimeRewardApplicable(address(collabRewardToken))
                .sub(collabLastUpdateTime)
                .mul(collabRewardRate)
                .mul(BASE)
                .div(totalSupply)
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

        if (_rewardTokenAddress == address(rewardToken)) {
            return
                stakerBalance.mul(
                    _rewardPerToken(address(rewardToken))
                    .sub(stakers[_account].arcRewardPerTokenPaid)
                )
                .div(BASE)
                .add(stakers[_account].arcRewardsEarned);
        }

        return
            stakerBalance.mul(
                _rewardPerToken(address(collabRewardToken))
                .sub(stakers[_account].collabRewardPerTokenPaid)
            )
            .div(BASE)
            .add(stakers[_account].collabRewardsEarned);
    }

    function arcEarned(
        address _account
    )
        external
        view
        returns (uint256)
    {
        return _actualEarned(_account, address(rewardToken))
            .mul(userAllocation())
            .div(BASE);
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

    function getCollabRewardForDuration()
        external
        view
        returns (uint256)
    {
        return collabRewardRate.mul(rewardsDuration);
    }

    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function getProofProtocol()
        external
        view
        returns (string memory)
    {
        return _proofProtocol.toString();
    }

    /* ========== Mutative Functions ========== */

    function stake(
        uint256 _amount,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
        checkScoreProof(_scoreProof, true, true)
        updateReward(msg.sender, address(0))
    {
        // Do not allow user to stake if they do not meet the credit score requirements
        require(
            _scoreProof.score >= creditScoreThreshold,
            "JointPassportCampaign: user does not meet the credit score requirement"
        );

        require(
            _scoreProof.protocol == _proofProtocol,
            "JointPassportCampaign: invalid proof protocol"
        );

        // Setting each variable individually means we don't overwrite
        Staker storage staker = stakers[msg.sender];

        staker.balance = staker.balance.add(_amount);

        // Heads up: the the max stake amount is not set in stone. It can be changed
        // by the admin by calling `setMaxStakePerUser()`
        if (maxStakePerUser > 0) {
            require(
                staker.balance <= maxStakePerUser,
                "JointPassportCampaign: cannot stake more than the limit"
            );
        }

        totalSupply = totalSupply.add(_amount);

        emit Staked(msg.sender, _amount);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function stakeWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
    {
        stakingToken.permit(
            msg.sender,
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );
        stake(_amount, _scoreProof);
    }

    function getReward(
        address _user
    )
        public
        updateReward(_user, address(0))
    {
        Staker storage staker = stakers[_user];
        uint256 arcPayableAmount;
        uint256 collabPayableAmount;

        require(
            collabTokensClaimable || tokensClaimable,
            "JointPassportCampaign: at least one reward token must be claimable"
        );

        if (collabTokensClaimable) {
            collabPayableAmount = staker.collabRewardsEarned.sub(staker.collabRewardsReleased);
            staker.collabRewardsReleased = staker.collabRewardsReleased.add(collabPayableAmount);

            collabRewardToken.safeTransfer(_user, collabPayableAmount);
        }

        if (tokensClaimable) {
            arcPayableAmount = staker.arcRewardsEarned.sub(staker.arcRewardsReleased);
            staker.arcRewardsReleased = staker.arcRewardsReleased.add(arcPayableAmount);

            uint256 daoPayable = arcPayableAmount
                .mul(daoAllocation)
                .div(BASE);
            rewardToken.safeTransfer(arcDAO, daoPayable);
            rewardToken.safeTransfer(_user, arcPayableAmount.sub(daoPayable));
        }

        emit RewardPaid(_user, arcPayableAmount, collabPayableAmount);
    }

    function withdraw(
        uint256 _amount
    )
        public
        updateReward(msg.sender, address(0))
    {
        Staker storage staker = stakers[msg.sender];

        require(
            _amount >= 0,
            "JointPassportCampaign: cannot withdraw less than 0"
        );

        require(
            staker.balance >= _amount,
            "JointPassportCampaign: cannot withdraw more than the balance"
        );

        totalSupply = totalSupply.sub(_amount);
        staker.balance = staker.balance.sub(_amount);

        emit Withdrawn(msg.sender, _amount);

        stakingToken.safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Claim reward and withdraw collateral
     */
    function exit()
        public
    {
        getReward(msg.sender);
        withdraw(balanceOf(msg.sender));
    }

    /* ========== Private Functions ========== */

    function _rewardPerToken(
        address _rewardTokenAddress
    )
        private
        view
        verifyRewardToken(_rewardTokenAddress)
        returns (uint256)
    {
        if (_rewardTokenAddress == address(rewardToken)) {
            if (totalSupply == 0) {
                return rewardPerTokenStored;
            }

            return rewardPerTokenStored.add(
                lastTimeRewardApplicable(address(rewardToken))
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(BASE)
                    .div(totalSupply)
            );
        } else {
            if (totalSupply == 0) {
                return collabPerTokenStored;
            }

            return collabPerTokenStored.add(
                lastTimeRewardApplicable(address(collabRewardToken))
                    .sub(collabLastUpdateTime)
                    .mul(collabRewardRate)
                    .mul(BASE)
                    .div(totalSupply)
            );
        }
    }

    /**
     * @dev If an individual reward token is updated, only update the relevant variables
     */
    function _updateRewardTokenCalculations(
        address _rewardToken
    )
        private
    {
        require(
            _rewardToken == address(0) ||
            _rewardToken == address(rewardToken) ||
            _rewardToken == address(collabRewardToken),
            "JointPassportCampaign: invalid reward token"
        );

        if (_rewardToken == address(0)) {
            rewardPerTokenStored = _rewardPerToken(address(rewardToken));
            collabPerTokenStored = _rewardPerToken(address(collabRewardToken));

            lastUpdateTime = lastTimeRewardApplicable(address(rewardToken));
            collabLastUpdateTime = lastTimeRewardApplicable(address(collabRewardToken));

        } else if (_rewardToken == address(rewardToken)) {
            rewardPerTokenStored = _rewardPerToken(address(rewardToken));
            lastUpdateTime = lastTimeRewardApplicable(address(rewardToken));

        } else {
            collabPerTokenStored = _rewardPerToken(address(collabRewardToken));
            collabLastUpdateTime = lastTimeRewardApplicable(address(collabRewardToken));
        }
    }

    function _updateRewardsForUser(
        address _account
    )
        private
    {
        if (_account != address(0)) {
            stakers[_account].arcRewardsEarned = _actualEarned(_account, address(rewardToken));
            stakers[_account].arcRewardPerTokenPaid = rewardPerTokenStored;

            stakers[_account].collabRewardsEarned = _actualEarned(_account, address(collabRewardToken));
            stakers[_account].collabRewardPerTokenPaid = collabPerTokenStored;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

library Bytes32 {

    function toString(
        bytes32 _bytes
    )
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes[i] != 0; i++) {
            bytesArray[i] = _bytes[i];
        }
        return string(bytesArray);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Address} from "./Address.sol";

import {ISapphirePassportScores} from "../sapphire/ISapphirePassportScores.sol";
import {SapphireTypes} from "../sapphire/SapphireTypes.sol";

/**
 * @dev Provides the ability of verifying users' credit scores
 */
contract PassportScoreVerifiable {

    using Address for address;

    ISapphirePassportScores public passportScoresContract;

    /**
     * @dev Verifies that the proof is passed if the score is required, and
     *      validates it.
     *      Additionally, it checks the proof validity if `scoreProof` has a score > 0
     */
    modifier checkScoreProof(
        SapphireTypes.ScoreProof memory _scoreProof,
        bool _isScoreRequired,
        bool _enforceSameCaller
    ) {
        if (_scoreProof.account != address(0) && _enforceSameCaller) {
            require (
                msg.sender == _scoreProof.account,
                "PassportScoreVerifiable: proof does not belong to the caller"
            );
        }

        bool isProofPassed = _scoreProof.merkleProof.length > 0;

        if (_isScoreRequired || isProofPassed || _scoreProof.score > 0) {
            passportScoresContract.verify(_scoreProof);
        }
        _;
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
pragma solidity 0.5.16;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
contract IPermittableERC20 is IERC20 {

    /**
     * @notice Approve token with signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "../lib/SafeMath.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";

import {IPermittableERC20} from "../token/IPermittableERC20.sol";
import {IERC20} from "../token/IERC20.sol";

/**
 * @dev A common storage for reward campaigns
 */
contract CampaignStorage {

    /* ========== Libraries ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IPermittableERC20;

    /* ========== Constants ========== */

    uint256 constant BASE = 1e18;

    /* ========== Variables ========== */

    /**
     * @notice Address of the ARCx DAO
     */
    address public arcDAO;

    /**
     * @notice The reward token distributed in the farm
     */
    IERC20 public rewardToken;

    /**
     * @notice The staking token
     */
    IPermittableERC20 public stakingToken;

    /**
     * @notice Epoch when the farm ends
     */
    uint256 public periodFinish = 0;

    /**
     * @notice The duration of the farm, in seconds
     */
    uint256 public rewardsDuration = 0;

    /**
     * @notice The current reward amount per staking token
     */
    uint256 public rewardPerTokenStored;

    /**
     * @notice Timestamp of the last reward update
     */
    uint256 public lastUpdateTime;

    /**
     * @notice Amount of rewards distributed every second
     */
    uint256 public rewardRate = 0;

    /**
     * @notice The current rewards distributor
     */
    address public rewardsDistributor;

    /**
     * @notice The current share of the ARCx DAO (ratio)
     */
    uint256 public daoAllocation;

    /**
     * @notice Flag determining if the rewards are claimable or not
     */
    bool public tokensClaimable;

    /**
     * @notice The amount of staking tokens on the contract
     */
    uint256 public totalSupply;

    /* ========== Public Getters ========== */

    function getRewardForDuration()
        external
        view
        returns (uint256)
    {
        return rewardRate.mul(rewardsDuration);
    }

    function  userAllocation()
        public
        view
        returns (uint256)
    {
        return BASE.sub(daoAllocation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphirePassportScores {
    function updateMerkleRoot(bytes32 newRoot) external;

    function setMerkleRootUpdater(address merkleRootUpdater) external;

    /**
     * Reverts if proof is invalid
     */
    function verify(SapphireTypes.ScoreProof calldata proof) external view returns(bool);

    function setMerkleRootDelay(uint256 delay) external;

    function setPause(bool status) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

library SapphireTypes {

    struct ScoreProof {
        address account;
        bytes32 protocol;
        uint256 score;
        bytes32[] merkleProof;
    }

    struct Vault {
        uint256 collateralAmount;
        uint256 borrowedAmount;
    }

    struct RootInfo {
        bytes32 merkleRoot;
        uint256 timestamp;
    }

    enum Operation {
        Deposit,
        Withdraw,
        Borrow,
        Repay,
        Liquidate
    }

    struct Action {
        uint256 amount;
        Operation operation;
        address userToLiquidate;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @dev Collection of functions related to the address type.
 *      Take from OpenZeppelin at
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
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
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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