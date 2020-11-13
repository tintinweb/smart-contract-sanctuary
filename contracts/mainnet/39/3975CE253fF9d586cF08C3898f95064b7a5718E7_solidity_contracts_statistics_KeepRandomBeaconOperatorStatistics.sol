pragma solidity ^0.5.4;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../KeepRandomBeaconOperator.sol";

contract KeepRandomBeaconOperatorStatistics {
    using SafeMath for uint256;

    KeepRandomBeaconOperator public operatorContract;

    constructor(
        address _operatorContract
    ) public {
        operatorContract = KeepRandomBeaconOperator(_operatorContract);
    }

    /// @notice Counts how many times the operator is present in a group.
    /// @param groupPubKey The public key of the group.
    /// @param operator The address of the operator.
    /// @return The number of members the operator has in the group.
    function countGroupMembership(
        bytes memory groupPubKey,
        address operator
    ) public view returns (uint256) {
        address[] memory members = operatorContract.getGroupMembers(groupPubKey);
        uint256 counter;
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == operator) {
                counter++;
            }
        }
        return counter;
    }


    /// @notice Gets all indices in the provided group for a member.
    /// If the given operator is not a member, returns an empty array.
    function getGroupMemberIndices(
        bytes memory groupPubKey,
        address operator
    ) public view returns (uint256[] memory indices) {
        uint256 count = countGroupMembership(groupPubKey, operator);
        address[] memory members = operatorContract.getGroupMembers(groupPubKey);

        indices = new uint256[](count);
        uint256 counter = 0;
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == operator) {
                indices[counter] = i;
                counter++;
            }
        }
    }

    /// @notice Get the amount of group rewards
    /// allocated to the given operator in the given group.
    /// The rewards may or may not be withdrawable.
    /// @param operator Address of the operator.
    /// @param groupIndex Index of the group.
    /// @return The total allocated rewards.
    function awaitingRewards(
        address operator,
        uint256 groupIndex
    ) public view returns (uint256 rewards) {
        if (operatorContract.hasWithdrawnRewards(operator, groupIndex)) {
            return 0;
        }
        bytes memory groupPubKey = operatorContract.getGroupPublicKey(groupIndex);
        uint256 memberRewards = operatorContract.getGroupMemberRewards(groupPubKey);

        uint256 memberCount = countGroupMembership(groupPubKey, operator);

        return memberRewards.mul(memberCount);
    }

    /// @notice Get the amount of group rewards
    /// withdrawable by the given operator in the given group.
    /// The group must be stale for any group rewards to be withdrawn.
    /// @param operator Address of the operator.
    /// @param groupIndex Index of the group.
    /// @return The total withdrawable rewards.
    function withdrawableRewards(
        address operator,
        uint256 groupIndex
    ) public view returns (uint256 rewards) {
        bytes memory groupPubKey = operatorContract.getGroupPublicKey(groupIndex);
        if (operatorContract.isStaleGroup(groupPubKey)) {
            return awaitingRewards(operator, groupIndex);
        } else {
            return 0;
        }
    }
}
