/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity ^0.5.17;

import "./Rewards.sol";
import "./KeepRandomBeaconOperator.sol";
import "./TokenStaking.sol";

/// @title KEEP Random Beacon Signer Subsidy Rewards
/// @notice Contract distributing KEEP rewards to Random Beacon signers based
/// on the defined reward schedule.
///
/// The amount of KEEP to be distributed is determined by funding the contract,
/// and additional KEEP can be added at any time.
/// 
/// When an interval is over, it will be allocated a percentage of the remaining
/// unallocated rewards based on its weight, and adjusted by the number of groups
/// created in the interval if the quota is not met.
///
/// The adjustment for not meeting the group quota is a percentage that equals
/// the percentage of the quota that was met; if the number of groups created is
/// 80% of the quota then 80% of the base reward will be allocated for the
/// interval.
///
/// Any unallocated rewards will stay in the unallocated rewards pool,
/// to be allocated for future intervals. Intervals past the initially defined
/// schedule have a weight of 100%, meaning that all remaining unallocated
/// rewards will be allocated to the interval.
///
/// Groups can receive rewards once the interval they were created in is over,
/// and the group has been marked as stale.
/// There is no time limit to receiving rewards, nor is there need to wait for
/// all groups from the interval to be marked as stale.
/// Calling `receiveReward` automatically allocates the rewards for the interval
/// the specified group was created in and all previous intervals.
///
/// If a group is terminated, that fact can be reported to the reward contract.
/// Reporting a terminated group returns its allocated reward to the pool of
/// unallocated rewards.
contract BeaconRewards is Rewards {


    // Weights of the 24 reward intervals assigned over
    // 24 * beaconTermLength days.
    uint256[] internal beaconIntervalWeights = [
        4, 8, 10, 12, 15, 15,
        15, 15, 15, 15, 15, 15,
        15, 15, 15, 15, 15, 15,
        15, 15, 15, 15, 15, 15
    ];

    // Beacon genesis date, 2020-09-24, is the first interval start.
    // https://etherscan.io/tx/0xe2e8ab5631473a3d7d8122ce4853c38f5cc7d3dcbfab3607f6b27a7ef3b86da2
    uint256 internal constant beaconFirstIntervalStart = 1600905600;

    // Each interval is 30 days long.
    uint256 internal constant beaconTermLength = 30 days;

    // There has to be at least 2 groups per interval to meet the group quota
    // and distribute the full reward for the given interval.
    uint256 internal constant minimumBeaconGroupsPerInterval = 2;


    KeepRandomBeaconOperator operatorContract;
    TokenStaking tokenStaking;

    constructor (
        address _token,
        address _operatorContract,
        address _stakingContract
    ) public Rewards(
        _token,
        beaconFirstIntervalStart,
        beaconIntervalWeights,
        beaconTermLength,
        minimumBeaconGroupsPerInterval
    ) {
        operatorContract = KeepRandomBeaconOperator(_operatorContract);
        tokenStaking = TokenStaking(_stakingContract);
    }

    /// @notice Sends the reward for a group to the group member beneficiaries.
    /// @param groupIndex Index of the group to receive a reward.
    function receiveReward(uint256 groupIndex) public {
        receiveReward(bytes32(groupIndex));
    }

    /// @notice Stakers can receive KEEP rewards from multiple groups of their choice
    /// in one transaction to reduce total cost comparing to single calls for rewards.
    /// It is a caller responsibility to determine the cost and consumed gas when
    /// receiving rewards from multiple groups.
    /// @param groupIndices An array of group indices.
    function receiveRewards(uint256[] memory groupIndices) public {
        uint256 len = groupIndices.length;
        bytes32[] memory bytes32identifiers = new bytes32[](len);
        for (uint256 i = 0; i < groupIndices.length; i++) {
            bytes32identifiers[i] = bytes32(groupIndices[i]);
        }
        receiveRewards(bytes32identifiers);
    }

    /// @notice Checks if the group is eligible to receive a reward.
    /// Group is eligible to receive a reward if it has been marked as stale
    /// and rewards has not been claimed yet.
    /// @param groupIndex Index of the group to check.
    function eligibleForReward(uint256 groupIndex) public view returns (bool) {
        return eligibleForReward(bytes32(groupIndex));
    }

    /// @notice Report that the group was terminated, and return its allocated
    /// rewards to the unallocated pool.
    /// @param groupIndex Index of the terminated group.
    function reportTermination(uint256 groupIndex) public {
        reportTermination(bytes32(groupIndex));
    }

    /// @notice Report about the terminated groups in batch. All the allocated
    /// rewards in these groups will be returned to the unallocated pool.
    /// @param groupIndices An array of group indices.
    function reportTerminations(uint256[] memory groupIndices) public {
        uint256 len = groupIndices.length;
        bytes32[] memory bytes32identifiers = new bytes32[](len);
        for (uint256 i = 0; i < groupIndices.length; i++) {
            bytes32identifiers[i] = bytes32(groupIndices[i]);
        }
        reportTerminations(bytes32identifiers);
    }

    /// @notice Checks if the group is terminated and thus its rewards can be
    /// returned to the unallocated pool by calling `reportTermination`.
    /// @param groupIndex Index of the potentially terminated group.
    function isTerminated(uint256 groupIndex) public view returns (bool) {
        return eligibleButTerminated(bytes32(groupIndex));
    }

    function _getKeepCount() internal view returns (uint256) {
        return operatorContract.getNumberOfCreatedGroups();
    }

    function _getKeepAtIndex(uint256 i) internal view returns (bytes32) {
        return bytes32(i);
    }

    function _getCreationTime(bytes32 groupIndexBytes) internal view returns (uint256) {
        return operatorContract.getGroupRegistrationTime(uint256(groupIndexBytes));
    }

    function _isClosed(bytes32 groupIndexBytes) internal view returns (bool) {
        if (_isTerminated(groupIndexBytes)) { return false; }
        bytes memory groupPubkey = operatorContract.getGroupPublicKey(
            uint256(groupIndexBytes)
        );
        return operatorContract.isStaleGroup(groupPubkey);
    }

    function _isTerminated(bytes32 groupIndexBytes) internal view returns (bool) {
        return operatorContract.isGroupTerminated(uint256(groupIndexBytes));
    }

    function _recognizedByFactory(bytes32 groupIndexBytes) internal view returns (bool) {
        return _getKeepCount() > uint256(groupIndexBytes);
    }

    function _distributeReward(bytes32 groupIndexBytes, uint256 _value) internal {
        bytes memory groupPubkey = operatorContract.getGroupPublicKey(
            uint256(groupIndexBytes)
        );
        address[] memory members = operatorContract.getGroupMembers(groupPubkey);

        uint256 memberCount = members.length;
        uint256 dividend = _value.div(memberCount);

        // Only pay other members if dividend is nonzero.
        if(dividend > 0) {
            for (uint256 i = 0; i < memberCount - 1; i++) {
                token.safeTransfer(
                    tokenStaking.beneficiaryOf(members[i]),
                    dividend
                );
            }
        }

        // Transfer of dividend for the last member. Remainder might be equal to
        // zero in case of even distribution or some small number.
        uint256 remainder = _value.mod(memberCount);
        token.safeTransfer(
            tokenStaking.beneficiaryOf(members[memberCount - 1]),
            dividend.add(remainder)
        );
    }
}
