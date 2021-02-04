// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IDsecDistribution.sol";

contract DsecDistribution is IDsecDistribution {
    using SafeMath for uint256;

    uint256 public constant DSEC_WITHDRAW_PENALTY_RATE = 20;
    uint256 public constant TOTAL_NUMBER_OF_EPOCHS = 20;

    address public governanceAccount;
    address public poolAccount;

    uint256[TOTAL_NUMBER_OF_EPOCHS] public totalDsec;

    struct GovernanceFormingParams {
        uint256 startTimestamp;
        uint256 epochDuration;
        uint256 intervalBetweenEpochs;
        uint256 endTimestamp;
    }

    GovernanceFormingParams public governanceForming;

    mapping(address => uint256[TOTAL_NUMBER_OF_EPOCHS]) private _dsecs;
    mapping(address => bool[TOTAL_NUMBER_OF_EPOCHS]) private _redeemedDsec;
    bool[TOTAL_NUMBER_OF_EPOCHS] private _redeemedTeamReward;

    event DsecAdd(
        address account,
        uint256 amount,
        uint256 timestamp,
        uint256 epoch,
        uint256 dsec
    );
    event DsecRemove(
        address account,
        uint256 amount,
        uint256 timestamp,
        uint256 epoch,
        uint256 dsec
    );
    event DsecRedeem(
        address account,
        uint256 epoch,
        uint256 distributionAmount,
        uint256 rewardAmount
    );
    event TeamRewardRedeem(address sender, uint256 epoch);

    constructor(
        uint256 epoch0StartTimestamp,
        uint256 epochDuration,
        uint256 intervalBetweenEpochs
    ) {
        governanceAccount = msg.sender;
        poolAccount = msg.sender;
        governanceForming = GovernanceFormingParams({
            startTimestamp: epoch0StartTimestamp,
            epochDuration: epochDuration,
            intervalBetweenEpochs: intervalBetweenEpochs,
            endTimestamp: epoch0StartTimestamp
                .add(TOTAL_NUMBER_OF_EPOCHS.mul(epochDuration))
                .add(TOTAL_NUMBER_OF_EPOCHS.sub(1).mul(intervalBetweenEpochs))
        });
    }

    function setGovernanceAccount(address account) external {
        require(msg.sender == governanceAccount, "must be governance account");
        governanceAccount = account;
    }

    function setPoolAccount(address account) external {
        require(msg.sender == governanceAccount, "must be governance account");
        poolAccount = account;
    }

    function addDsec(address account, uint256 amount) external override {
        require(msg.sender == poolAccount, "must be pool account");
        require(account != address(0), "add to zero address");
        require(amount != 0, "add zero amount");

        (uint256 currentEpoch, uint256 currentDsec) =
            getDsecForTransferNow(amount);
        if (currentEpoch >= TOTAL_NUMBER_OF_EPOCHS) {
            return;
        }

        _dsecs[account][currentEpoch] = _dsecs[account][currentEpoch].add(
            currentDsec
        );
        totalDsec[currentEpoch] = totalDsec[currentEpoch].add(currentDsec);

        uint256 nextEpoch = currentEpoch.add(1);
        if (nextEpoch < TOTAL_NUMBER_OF_EPOCHS) {
            for (uint256 i = nextEpoch; i < TOTAL_NUMBER_OF_EPOCHS; i++) {
                uint256 futureDsec =
                    amount.mul(governanceForming.epochDuration);
                _dsecs[account][i] = _dsecs[account][i].add(futureDsec);
                totalDsec[i] = totalDsec[i].add(futureDsec);
            }
        }

        emit DsecAdd(
            account,
            amount,
            block.timestamp,
            currentEpoch,
            currentDsec
        );
    }

    function removeDsec(address account, uint256 amount) external override {
        require(msg.sender == poolAccount, "must be pool account");
        require(account != address(0), "remove from zero address");
        require(amount != 0, "remove zero amount");

        (uint256 currentEpoch, uint256 currentDsec) =
            getDsecForTransferNow(amount);
        if (currentEpoch >= TOTAL_NUMBER_OF_EPOCHS) {
            return;
        }

        if (_dsecs[account][currentEpoch] == 0) {
            return;
        }

        uint256 dsecRemove =
            currentDsec.mul(DSEC_WITHDRAW_PENALTY_RATE.add(100)).div(100);

        uint256 accountDsecRemove =
            (dsecRemove < _dsecs[account][currentEpoch])
                ? dsecRemove
                : _dsecs[account][currentEpoch];
        _dsecs[account][currentEpoch] = _dsecs[account][currentEpoch].sub(
            accountDsecRemove,
            "insufficient account dsec"
        );
        totalDsec[currentEpoch] = totalDsec[currentEpoch].sub(
            accountDsecRemove,
            "insufficient total dsec"
        );

        uint256 nextEpoch = currentEpoch.add(1);
        if (nextEpoch < TOTAL_NUMBER_OF_EPOCHS) {
            for (uint256 i = nextEpoch; i < TOTAL_NUMBER_OF_EPOCHS; i++) {
                uint256 futureDsecRemove =
                    amount
                        .mul(governanceForming.epochDuration)
                        .mul(DSEC_WITHDRAW_PENALTY_RATE.add(100))
                        .div(100);
                uint256 futureAccountDsecRemove =
                    (futureDsecRemove < _dsecs[account][i])
                        ? futureDsecRemove
                        : _dsecs[account][i];
                _dsecs[account][i] = _dsecs[account][i].sub(
                    futureAccountDsecRemove,
                    "insufficient account future dsec"
                );
                totalDsec[i] = totalDsec[i].sub(
                    futureAccountDsecRemove,
                    "insufficient total future dsec"
                );
            }
        }

        emit DsecRemove(
            account,
            amount,
            block.timestamp,
            currentEpoch,
            accountDsecRemove
        );
    }

    function redeemDsec(
        address account,
        uint256 epoch,
        uint256 distributionAmount
    ) external override returns (uint256) {
        require(msg.sender == poolAccount, "must be pool account");
        require(account != address(0), "redeem for zero address");

        uint256 rewardAmount =
            calculateRewardFor(account, epoch, distributionAmount);
        if (rewardAmount == 0) {
            return 0;
        }

        if (hasRedeemedDsec(account, epoch)) {
            return 0;
        }

        _redeemedDsec[account][epoch] = true;
        emit DsecRedeem(account, epoch, distributionAmount, rewardAmount);
        return rewardAmount;
    }

    function redeemTeamReward(uint256 epoch) external override {
        require(msg.sender == poolAccount, "must be pool account");
        require(epoch < TOTAL_NUMBER_OF_EPOCHS, "governance forming ended");

        uint256 currentEpoch = getCurrentEpoch();
        require(epoch < currentEpoch, "only for completed epochs");

        require(!hasRedeemedTeamReward(epoch), "already redeemed");

        _redeemedTeamReward[epoch] = true;
        emit TeamRewardRedeem(msg.sender, epoch);
    }

    function calculateRewardFor(
        address account,
        uint256 epoch,
        uint256 distributionAmount
    ) public view returns (uint256) {
        require(distributionAmount != 0, "zero distribution amount");

        if (epoch >= TOTAL_NUMBER_OF_EPOCHS) {
            return 0;
        }

        uint256 currentEpoch = getCurrentEpoch();
        if (epoch >= currentEpoch) {
            return 0;
        }

        return getRewardFor(account, epoch, distributionAmount);
    }

    function estimateRewardForCurrentEpoch(
        address account,
        uint256 distributionAmount
    ) public view returns (uint256) {
        require(distributionAmount != 0, "zero distribution amount");

        uint256 currentEpoch = getCurrentEpoch();
        return getRewardFor(account, currentEpoch, distributionAmount);
    }

    function hasRedeemedDsec(address account, uint256 epoch)
        public
        view
        returns (bool)
    {
        require(epoch < TOTAL_NUMBER_OF_EPOCHS, "governance forming ended");

        return _redeemedDsec[account][epoch];
    }

    function hasRedeemedTeamReward(uint256 epoch) public view returns (bool) {
        require(epoch < TOTAL_NUMBER_OF_EPOCHS, "governance forming ended");

        return _redeemedTeamReward[epoch];
    }

    function getCurrentEpoch() public view returns (uint256) {
        return getEpoch(block.timestamp);
    }

    function getCurrentEpochStartTimestamp()
        public
        view
        returns (uint256, uint256)
    {
        return getEpochStartTimestamp(block.timestamp);
    }

    function getCurrentEpochEndTimestamp()
        public
        view
        returns (uint256, uint256)
    {
        return getEpochEndTimestamp(block.timestamp);
    }

    function getEpoch(uint256 timestamp) public view returns (uint256) {
        if (timestamp < governanceForming.startTimestamp) {
            return 0;
        }

        if (timestamp >= governanceForming.endTimestamp) {
            return TOTAL_NUMBER_OF_EPOCHS;
        }

        return
            timestamp
                .sub(governanceForming.startTimestamp, "before epoch 0")
                .add(governanceForming.intervalBetweenEpochs)
                .div(
                governanceForming.epochDuration.add(
                    governanceForming.intervalBetweenEpochs
                )
            );
    }

    function getEpochStartTimestamp(uint256 timestamp)
        public
        view
        returns (uint256, uint256)
    {
        uint256 epoch = getEpoch(timestamp);
        return (epoch, getStartTimestampForEpoch(epoch));
    }

    function getStartTimestampForEpoch(uint256 epoch)
        public
        view
        returns (uint256)
    {
        if (epoch >= TOTAL_NUMBER_OF_EPOCHS) {
            return 0;
        }

        if (epoch == 0) {
            return governanceForming.startTimestamp;
        }

        return
            governanceForming.startTimestamp.add(
                epoch.mul(
                    governanceForming.epochDuration.add(
                        governanceForming.intervalBetweenEpochs
                    )
                )
            );
    }

    function getEpochEndTimestamp(uint256 timestamp)
        public
        view
        returns (uint256, uint256)
    {
        uint256 epoch = getEpoch(timestamp);
        return (epoch, getEndTimestampForEpoch(epoch));
    }

    function getEndTimestampForEpoch(uint256 epoch)
        public
        view
        returns (uint256)
    {
        if (epoch >= TOTAL_NUMBER_OF_EPOCHS) {
            return 0;
        }

        return
            governanceForming
                .startTimestamp
                .add(epoch.add(1).mul(governanceForming.epochDuration))
                .add(epoch.mul(governanceForming.intervalBetweenEpochs));
    }

    function getStartEndTimestampsForEpoch(uint256 epoch)
        public
        view
        returns (uint256, uint256)
    {
        return (
            getStartTimestampForEpoch(epoch),
            getEndTimestampForEpoch(epoch)
        );
    }

    function getSecondsUntilCurrentEpochEnd()
        public
        view
        returns (uint256, uint256)
    {
        return getSecondsUntilEpochEnd(block.timestamp);
    }

    function getSecondsUntilEpochEnd(uint256 timestamp)
        public
        view
        returns (uint256, uint256)
    {
        (uint256 endEpoch, uint256 epochEndTimestamp) =
            getEpochEndTimestamp(timestamp);
        if (timestamp >= epochEndTimestamp) {
            return (endEpoch, 0);
        }

        (uint256 startEpoch, uint256 epochStartTimestamp) =
            getEpochStartTimestamp(timestamp);
        require(epochStartTimestamp > 0, "unexpected 0 epoch start");
        require(endEpoch == startEpoch, "start/end different epochs");

        uint256 startTimestamp =
            (timestamp < epochStartTimestamp) ? epochStartTimestamp : timestamp;
        return (
            endEpoch,
            epochEndTimestamp.sub(startTimestamp, "after end of epoch")
        );
    }

    function getDsecForTransferNow(uint256 amount)
        public
        view
        returns (uint256, uint256)
    {
        (uint256 currentEpoch, uint256 secondsUntilCurrentEpochEnd) =
            getSecondsUntilCurrentEpochEnd();
        return (currentEpoch, amount.mul(secondsUntilCurrentEpochEnd));
    }

    function dsecBalanceFor(address account, uint256 epoch)
        public
        view
        returns (uint256)
    {
        if (epoch >= TOTAL_NUMBER_OF_EPOCHS) {
            return 0;
        }

        uint256 currentEpoch = getCurrentEpoch();
        if (epoch > currentEpoch) {
            return 0;
        }

        return _dsecs[account][epoch];
    }

    function getRewardFor(
        address account,
        uint256 epoch,
        uint256 distributionAmount
    ) internal view returns (uint256) {
        require(distributionAmount != 0, "zero distribution amount");

        if (epoch >= TOTAL_NUMBER_OF_EPOCHS) {
            return 0;
        }

        if (totalDsec[epoch] == 0) {
            return 0;
        }

        if (_dsecs[account][epoch] == 0) {
            return 0;
        }

        uint256 rewardAmount =
            _dsecs[account][epoch].mul(distributionAmount).div(
                totalDsec[epoch]
            );
        return rewardAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";

contract LFI is ERC20Capped {
    address public governanceAccount;
    address public minter;

    constructor(
        string memory name,
        string memory symbol,
        uint256 cap
    ) ERC20(name, symbol) ERC20Capped(cap) {
        governanceAccount = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "LFI: must be minter");

        _mint(to, amount);
    }

    function setGovernanceAccount(address to) external {
        require(
            msg.sender == governanceAccount,
            "LFI: must be governance account"
        );

        governanceAccount = to;
    }

    function setMinter(address to) external {
        require(
            msg.sender == governanceAccount,
            "LFI: must be governance account"
        );

        minter = to;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/ILToken.sol";
import "./LFI.sol";
import "./DsecDistribution.sol";

contract TreasuryPool is Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant LP_REWARD_PER_EPOCH = 4000 ether;
    uint256 public constant TEAM_REWARD_PER_EPOCH = 1000 ether;

    address public governanceAccount;
    address public lfiAddress;
    address public underlyingAssetAddress;
    address public ltokenAddress;
    address public teamAccount;
    address public dsecDistributionAddress;

    uint256 public totalUnderlyingAssetAmount = 0;

    LFI private _lfi;
    IERC20 private _underlyingAsset;
    ILToken private _ltoken;
    DsecDistribution private _dsecDistribution;

    event AddLiquidity(
        address account,
        address underlyingAssetAddress,
        uint256 amount,
        uint256 timestamp
    );

    event RemoveLiquidity(
        address account,
        address underlyingAssetAddress,
        uint256 amount,
        uint256 timestamp
    );

    event RedeemProviderReward(
        address account,
        uint256 fromEpoch,
        uint256 toEpoch,
        address rewardTokenAddress,
        uint256 amount,
        uint256 timestamp
    );

    event RedeemTeamReward(
        address account,
        uint256 fromEpoch,
        uint256 toEpoch,
        address rewardTokenAddress,
        uint256 amount,
        uint256 timestamp
    );

    event Sweep(
        address from,
        address to,
        address underlyingAssetAddress,
        uint256 amount,
        address operator
    );

    constructor(
        address lfiAddress_,
        address underlyingAssetAddress_,
        address ltokenAddress_,
        address teamAccount_,
        address dsecDistributionAddress_
    ) {
        governanceAccount = msg.sender;
        lfiAddress = lfiAddress_;
        underlyingAssetAddress = underlyingAssetAddress_;
        ltokenAddress = ltokenAddress_;
        teamAccount = teamAccount_;
        dsecDistributionAddress = dsecDistributionAddress_;

        _lfi = LFI(lfiAddress_);
        _underlyingAsset = IERC20(underlyingAssetAddress_);
        _ltoken = ILToken(ltokenAddress);
        _dsecDistribution = DsecDistribution(dsecDistributionAddress_);
    }

    function addLiquidity(uint256 amount) external {
        require(amount != 0, "Pool: can't add 0");
        require(!paused(), "Pool: deposit while paused");

        _underlyingAsset.safeTransferFrom(msg.sender, address(this), amount);
        totalUnderlyingAssetAmount = totalUnderlyingAssetAmount.add(amount);
        _dsecDistribution.addDsec(msg.sender, amount);
        _ltoken.mint(msg.sender, amount);

        emit AddLiquidity(
            msg.sender,
            underlyingAssetAddress,
            amount,
            block.timestamp
        );
    }

    function removeLiquidity(uint256 amount) external {
        require(amount != 0, "Pool: can't remove 0");
        require(!paused(), "Pool: withdraw while paused");
        require(
            totalUnderlyingAssetAmount >= amount,
            "Pool: insufficient liquidity"
        );
        require(
            _ltoken.balanceOf(msg.sender) >= amount,
            "Pool: insufficient LToken"
        );

        totalUnderlyingAssetAmount = totalUnderlyingAssetAmount.sub(amount);
        _ltoken.burn(msg.sender, amount);
        _dsecDistribution.removeDsec(msg.sender, amount);
        _underlyingAsset.safeTransfer(msg.sender, amount);

        emit RemoveLiquidity(
            msg.sender,
            underlyingAssetAddress,
            amount,
            block.timestamp
        );
    }

    function redeemProviderReward(uint256 fromEpoch, uint256 toEpoch) external {
        require(fromEpoch <= toEpoch, "Pool: invalid epoch range");
        require(!paused(), "Pool: redeem while paused");

        uint256 totalRewardAmount = 0;
        for (uint256 i = fromEpoch; i <= toEpoch; i++) {
            if (_dsecDistribution.hasRedeemedDsec(msg.sender, i)) {
                break;
            }

            uint256 rewardAmount =
                _dsecDistribution.redeemDsec(
                    msg.sender,
                    i,
                    LP_REWARD_PER_EPOCH
                );
            totalRewardAmount = totalRewardAmount.add(rewardAmount);
        }

        if (totalRewardAmount == 0) {
            return;
        }

        _lfi.mint(msg.sender, totalRewardAmount);

        emit RedeemProviderReward(
            msg.sender,
            fromEpoch,
            toEpoch,
            lfiAddress,
            totalRewardAmount,
            block.timestamp
        );
    }

    function redeemTeamReward(uint256 fromEpoch, uint256 toEpoch) external {
        require(msg.sender == teamAccount, "Pool: must be team account");
        require(fromEpoch <= toEpoch, "Pool: invalid epoch range");
        require(!paused(), "Pool: redeem while paused");

        uint256 totalRewardAmount = 0;
        for (uint256 i = fromEpoch; i <= toEpoch; i++) {
            if (_dsecDistribution.hasRedeemedTeamReward(i)) {
                break;
            }

            _dsecDistribution.redeemTeamReward(i);
            totalRewardAmount = totalRewardAmount.add(TEAM_REWARD_PER_EPOCH);
        }

        if (totalRewardAmount == 0) {
            return;
        }

        _lfi.mint(teamAccount, totalRewardAmount);

        emit RedeemTeamReward(
            teamAccount,
            fromEpoch,
            toEpoch,
            lfiAddress,
            totalRewardAmount,
            block.timestamp
        );
    }

    function setGovernanceAccount(address to) external {
        require(
            msg.sender == governanceAccount,
            "Pool: must be governance account"
        );

        governanceAccount = to;
    }

    function pause() external {
        require(
            msg.sender == governanceAccount,
            "Pool: must be governance account"
        );

        _pause();
    }

    function unpause() external {
        require(
            msg.sender == governanceAccount,
            "Pool: must be governance account"
        );

        _unpause();
    }

    function sweep(address to) external {
        require(
            msg.sender == governanceAccount,
            "Pool: must be governance account"
        );

        uint256 balance = _underlyingAsset.balanceOf(address(this));
        if (balance == 0) {
            return;
        }

        totalUnderlyingAssetAmount = totalUnderlyingAssetAmount.sub(balance);
        _underlyingAsset.safeTransfer(to, balance);

        emit Sweep(
            address(this),
            to,
            underlyingAssetAddress,
            balance,
            msg.sender
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IDsecDistribution {
    function addDsec(address account, uint256 amount) external;

    function removeDsec(address account, uint256 amount) external;

    function redeemDsec(
        address account,
        uint256 epoch,
        uint256 distributionAmount
    ) external returns (uint256);

    function redeemTeamReward(uint256 epoch) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    using SafeMath for uint256;

    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap_) internal {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
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

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}