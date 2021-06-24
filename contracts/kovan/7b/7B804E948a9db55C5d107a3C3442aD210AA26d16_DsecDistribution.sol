// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IDsecDistribution.sol";

contract DsecDistribution is IDsecDistribution {
    using SafeMath for uint256;

    uint256 public constant DSEC_WITHDRAW_PENALTY_RATE = 20;

    address public governanceAccount;
    address public treasuryPoolAddress;

    mapping(uint256 => uint256) public totalDsec;

    struct GovernanceFormingParams {
        uint256 totalNumberOfEpochs;
        uint256 startTimestamp;
        uint256 epochDuration;
        uint256 intervalBetweenEpochs;
        uint256 endTimestamp;
    }

    GovernanceFormingParams public governanceForming;

    mapping(address => mapping(uint256 => uint256)) private _dsecs;
    mapping(address => mapping(uint256 => bool)) private _redeemedDsec;
    mapping(uint256 => bool) private _redeemedTeamReward;

    constructor(
        uint256 totalNumberOfEpochs_,
        uint256 epoch0StartTimestamp,
        uint256 epochDuration,
        uint256 intervalBetweenEpochs
    ) {
        governanceAccount = msg.sender;
        treasuryPoolAddress = msg.sender;
        governanceForming = GovernanceFormingParams({
            totalNumberOfEpochs: totalNumberOfEpochs_,
            startTimestamp: epoch0StartTimestamp,
            epochDuration: epochDuration,
            intervalBetweenEpochs: intervalBetweenEpochs,
            endTimestamp: epoch0StartTimestamp
                .add(totalNumberOfEpochs_.mul(epochDuration))
                .add(totalNumberOfEpochs_.sub(1).mul(intervalBetweenEpochs))
        });
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "sender not authorized");
        _;
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newGovernanceAccount != address(0),
            "new governance account is the zero address"
        );

        governanceAccount = newGovernanceAccount;
    }

    function setTreasuryPoolAddress(address newTreasuryPoolAddress)
        external
        onlyBy(governanceAccount)
    {
        require(
            newTreasuryPoolAddress != address(0),
            "new treasury pool address is the zero address"
        );

        treasuryPoolAddress = newTreasuryPoolAddress;
    }

    function addDsec(address account, uint256 amount)
        external
        override
        onlyBy(treasuryPoolAddress)
    {
        require(account != address(0), "add to zero address");
        require(amount != 0, "add zero amount");

        (uint256 currentEpoch, uint256 currentDsec) =
            getDsecForTransferNow(amount);
        if (currentEpoch >= totalNumberOfEpochs()) {
            return;
        }

        _dsecs[account][currentEpoch] = _dsecs[account][currentEpoch].add(
            currentDsec
        );
        totalDsec[currentEpoch] = totalDsec[currentEpoch].add(currentDsec);

        uint256 nextEpoch = currentEpoch.add(1);
        if (nextEpoch < totalNumberOfEpochs()) {
            for (uint256 i = nextEpoch; i < totalNumberOfEpochs(); i++) {
                uint256 futureDsec =
                    amount.mul(governanceForming.epochDuration);
                _dsecs[account][i] = _dsecs[account][i].add(futureDsec);
                totalDsec[i] = totalDsec[i].add(futureDsec);
            }
        }

        emit DsecAdd(
            account,
            currentEpoch,
            amount,
            block.timestamp,
            currentDsec
        );
    }

    function removeDsec(address account, uint256 amount)
        external
        override
        onlyBy(treasuryPoolAddress)
    {
        require(account != address(0), "remove from zero address");
        require(amount != 0, "remove zero amount");

        (uint256 currentEpoch, uint256 currentDsec) =
            getDsecForTransferNow(amount);
        if (currentEpoch >= totalNumberOfEpochs()) {
            return;
        }

        if (_dsecs[account][currentEpoch] == 0) {
            return;
        }

        uint256 dsecRemove =
            (block.timestamp < getStartTimestampForEpoch(currentEpoch))
                ? currentDsec
                : currentDsec.mul(DSEC_WITHDRAW_PENALTY_RATE.add(100)).div(100);

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
        if (nextEpoch < totalNumberOfEpochs()) {
            for (uint256 i = nextEpoch; i < totalNumberOfEpochs(); i++) {
                uint256 futureDsecRemove =
                    amount.mul(governanceForming.epochDuration);
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
            currentEpoch,
            amount,
            block.timestamp,
            accountDsecRemove
        );
    }

    function redeemDsec(
        address account,
        uint256 epoch,
        uint256 distributionAmount
    ) external override onlyBy(treasuryPoolAddress) returns (uint256) {
        require(account != address(0), "redeem for zero address");

        uint256 rewardAmount =
            calculateRewardFor(account, epoch, distributionAmount);
        // https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        // slither-disable-next-line incorrect-equality
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

    function redeemTeamReward(uint256 epoch)
        external
        override
        onlyBy(treasuryPoolAddress)
    {
        require(epoch < totalNumberOfEpochs(), "governance forming ended");

        uint256 currentEpoch = getCurrentEpoch();
        require(epoch < currentEpoch, "only for completed epochs");

        require(!hasRedeemedTeamReward(epoch), "already redeemed");

        _redeemedTeamReward[epoch] = true;
        emit TeamRewardRedeem(msg.sender, epoch);
    }

    function totalNumberOfEpochs()
        public
        view
        returns (uint256 totalNumberOfEpochs_)
    {
        totalNumberOfEpochs_ = governanceForming.totalNumberOfEpochs;
    }

    function calculateRewardFor(
        address account,
        uint256 epoch,
        uint256 distributionAmount
    ) public view returns (uint256) {
        require(distributionAmount != 0, "zero distribution amount");

        if (epoch >= totalNumberOfEpochs()) {
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
    ) external view returns (uint256) {
        require(distributionAmount != 0, "zero distribution amount");

        uint256 currentEpoch = getCurrentEpoch();
        return getRewardFor(account, currentEpoch, distributionAmount);
    }

    function hasRedeemedDsec(address account, uint256 epoch)
        public
        view
        override
        returns (bool)
    {
        require(epoch < totalNumberOfEpochs(), "governance forming ended");

        return _redeemedDsec[account][epoch];
    }

    function hasRedeemedTeamReward(uint256 epoch)
        public
        view
        override
        returns (bool)
    {
        require(epoch < totalNumberOfEpochs(), "governance forming ended");

        return _redeemedTeamReward[epoch];
    }

    function getCurrentEpoch() public view returns (uint256) {
        return getEpoch(block.timestamp);
    }

    function getCurrentEpochStartTimestamp()
        external
        view
        returns (uint256, uint256)
    {
        return getEpochStartTimestamp(block.timestamp);
    }

    function getCurrentEpochEndTimestamp()
        external
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
            return totalNumberOfEpochs();
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
        if (epoch >= totalNumberOfEpochs()) {
            return 0;
        }

        // https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        // slither-disable-next-line incorrect-equality
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
        if (epoch >= totalNumberOfEpochs()) {
            return 0;
        }

        return
            governanceForming
                .startTimestamp
                .add(epoch.add(1).mul(governanceForming.epochDuration))
                .add(epoch.mul(governanceForming.intervalBetweenEpochs));
    }

    function getStartEndTimestampsForEpoch(uint256 epoch)
        external
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
        // https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        // slither-disable-next-line incorrect-equality
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
        external
        view
        returns (uint256)
    {
        if (epoch >= totalNumberOfEpochs()) {
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

        if (epoch >= totalNumberOfEpochs()) {
            return 0;
        }

        // https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
        // slither-disable-next-line incorrect-equality
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IDsecDistribution {
    function addDsec(address account, uint256 amount) external;

    function hasRedeemedDsec(address account, uint256 epoch)
        external
        view
        returns (bool);

    function hasRedeemedTeamReward(uint256 epoch) external view returns (bool);

    function removeDsec(address account, uint256 amount) external;

    function redeemDsec(
        address account,
        uint256 epoch,
        uint256 distributionAmount
    ) external returns (uint256);

    function redeemTeamReward(uint256 epoch) external;

    event DsecAdd(
        address indexed account,
        uint256 indexed epoch,
        uint256 amount,
        uint256 timestamp,
        uint256 dsec
    );

    event DsecRemove(
        address indexed account,
        uint256 indexed epoch,
        uint256 amount,
        uint256 timestamp,
        uint256 dsec
    );

    event DsecRedeem(
        address indexed account,
        uint256 indexed epoch,
        uint256 distributionAmount,
        uint256 rewardAmount
    );

    event TeamRewardRedeem(address indexed sender, uint256 indexed epoch);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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