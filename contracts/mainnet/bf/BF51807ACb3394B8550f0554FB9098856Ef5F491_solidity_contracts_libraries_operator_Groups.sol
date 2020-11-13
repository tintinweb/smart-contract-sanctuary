pragma solidity 0.5.17;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../utils/BytesLib.sol";
import "../../utils/PercentUtils.sol";
import "../../cryptography/AltBn128.sol";
import "../../cryptography/BLS.sol";
import "../../TokenStaking.sol";


library Groups {
    using SafeMath for uint256;
    using PercentUtils for uint256;
    using BytesLib for bytes;

    // The index of a group is flagged with the most significant bit set,
    // to distinguish the group `0` from null.
    // The flag is toggled with bitwise XOR (`^`)
    // which keeps all other bits intact but flips the flag bit.
    // The flag should be set before writing to `groupIndices`,
    // and unset after reading from `groupIndices`
    // before using the value.
    uint256 constant GROUP_INDEX_FLAG = 1 << 255;

    uint256 constant ONE_MONTH = 86400 * 30;
    uint256 constant THREE_MONTHS = 3 * ONE_MONTH;
    uint256 constant SIX_MONTHS = 6 * ONE_MONTH;

    struct Group {
        bytes groupPubKey;
        uint256 registrationBlockHeight;
        bool terminated;
        uint248 registrationTime;
    }

    struct Storage {
        // Time in blocks after which a group expires.
        uint256 groupActiveTime;

        // Duplicated constant from operator contract to avoid extra call.
        // The value is set when the operator contract is added.
        uint256 relayEntryTimeout;

        // Mapping of `groupPubKey` to flagged `groupIndex`
        mapping (bytes => uint256) groupIndices;
        Group[] groups;
        uint256[] activeTerminatedGroups;
        mapping (bytes => address[]) groupMembers;

        // Sum of all group member rewards earned so far. The value is the same for
        // all group members. Submitter reward and reimbursement is paid immediately
        // and is not included here. Each group member can withdraw no more than
        // this value.
        mapping (bytes => uint256) groupMemberRewards;

        // Mapping of `groupPubKey, operator`
        // to whether the operator has withdrawn rewards from that group.
        mapping(bytes => mapping(address => bool)) withdrawn;

        // expiredGroupOffset is pointing to the first active group, it is also the
        // expired groups counter
        uint256 expiredGroupOffset;

        TokenStaking stakingContract;
    }

    /// @notice Adds a new group.
    function addGroup(
        Storage storage self,
        bytes memory groupPubKey
    ) public {
        self.groupIndices[groupPubKey] = (self.groups.length ^ GROUP_INDEX_FLAG);
        self.groups.push(Group(groupPubKey, block.number, false, uint248(block.timestamp)));
    }

    /// @notice Sets addresses of members for the group with the given public key
    /// eliminating members at positions pointed by the misbehaved array.
    /// @param groupPubKey Group public key.
    /// @param members Group member addresses as outputted by the group selection
    /// protocol.
    /// @param misbehaved Bytes array of misbehaved (disqualified or inactive)
    /// group members indexes in ascending order; Indexes reflect positions of
    /// members in the group as outputted by the group selection protocol -
    /// member indexes start from 1.
    function setGroupMembers(
        Storage storage self,
        bytes memory groupPubKey,
        address[] memory members,
        bytes memory misbehaved
    ) public {
        self.groupMembers[groupPubKey] = members;

        // Iterate misbehaved array backwards, replace misbehaved
        // member with the last element and reduce array length
        uint256 i = misbehaved.length;
        while (i > 0) {
             // group member indexes start from 1, so we need to -1 on misbehaved
            uint256 memberArrayPosition = misbehaved.toUint8(i - 1) - 1;
            self.groupMembers[groupPubKey][memberArrayPosition] = self.groupMembers[groupPubKey][self.groupMembers[groupPubKey].length - 1];
            self.groupMembers[groupPubKey].length--;
            i--;
        }
    }

    /// @notice Adds group member reward per group so the accumulated amount can
    /// be withdrawn later.
    function addGroupMemberReward(
        Storage storage self,
        bytes memory groupPubKey,
        uint256 amount
    ) internal {
        self.groupMemberRewards[groupPubKey] = self.groupMemberRewards[groupPubKey].add(amount);
    }

    /// @notice Returns accumulated group member rewards for provided group.
    function getGroupMemberRewards(
        Storage storage self,
        bytes memory groupPubKey
    ) internal view returns (uint256) {
        return self.groupMemberRewards[groupPubKey];
    }

    /// @notice Gets group public key.
    function getGroupPublicKey(
        Storage storage self,
        uint256 groupIndex
    ) internal view returns (bytes memory) {
        return self.groups[groupIndex].groupPubKey;
    }

    /// @notice Gets group member.
    function getGroupMember(
        Storage storage self,
        bytes memory groupPubKey,
        uint256 memberIndex
    ) internal view returns (address) {
        return self.groupMembers[groupPubKey][memberIndex];
    }

    /// @notice Terminates group with the provided index. Reverts if the group
    /// is already terminated.
    function terminateGroup(
        Storage storage self,
        uint256 groupIndex
    ) public {
        require(
            !isGroupTerminated(self, groupIndex),
            "Group has been already terminated"
        );
        self.groups[groupIndex].terminated = true;
        self.activeTerminatedGroups.length++;

        // Sorting activeTerminatedGroups in ascending order so a non-terminated
        // group is properly selected.
        uint256 i;
        for (
            i = self.activeTerminatedGroups.length - 1;
            i > 0 && self.activeTerminatedGroups[i - 1] > groupIndex;
            i--
        ) {
            self.activeTerminatedGroups[i] = self.activeTerminatedGroups[i - 1];
        }
        self.activeTerminatedGroups[i] = groupIndex;
    }

    /// @notice Checks if group with the given index is terminated.
    function isGroupTerminated(
        Storage storage self,
        uint256 groupIndex
    ) internal view returns(bool) {
        return self.groups[groupIndex].terminated;
    }

    /// @notice Checks if group with the given public key is registered.
    function isGroupRegistered(
        Storage storage self,
        bytes memory groupPubKey
    ) internal view returns(bool) {
        // Values in `groupIndices` are flagged with `GROUP_INDEX_FLAG`
        // and thus nonzero, even for group 0
        return self.groupIndices[groupPubKey] > 0;
    }

    /// @notice Gets the cutoff time in blocks until which the given group is
    /// considered as an active group assuming it hasn't been terminated before.
    function groupActiveTimeOf(
        Storage storage self,
        Group memory group
    ) internal view returns(uint256) {
        return uint256(group.registrationBlockHeight).add(self.groupActiveTime);
    }

    /// @notice Gets the cutoff time in blocks after which the given group is
    /// considered as stale. Stale group is an expired group which is no longer
    /// performing any operations.
    function groupStaleTime(
        Storage storage self,
        Group memory group
    ) internal view returns(uint256) {
        return groupActiveTimeOf(self, group).add(self.relayEntryTimeout);
    }

    /// @notice Checks if a group with the given public key is a stale group.
    /// Stale group is an expired group which is no longer performing any
    /// operations. It is important to understand that an expired group may
    /// still perform some operations for which it was selected when it was still
    /// active. We consider a group to be stale when it's expired and when its
    /// expiration time and potentially executed operation timeout are both in
    /// the past.
    function isStaleGroup(
        Storage storage self,
        bytes memory groupPubKey
    ) public view returns(bool) {
        uint256 flaggedIndex = self.groupIndices[groupPubKey];
        require(flaggedIndex != 0, "Group does not exist");
        uint256 index = flaggedIndex ^ GROUP_INDEX_FLAG;
        bool isExpired = self.expiredGroupOffset > index;
        bool isStale = groupStaleTime(self, self.groups[index]) < block.number;
        return isExpired && isStale;
    }

    /// @notice Checks if a group with the given index is a stale group.
    /// Stale group is an expired group which is no longer performing any
    /// operations. It is important to understand that an expired group may
    /// still perform some operations for which it was selected when it was still
    /// active. We consider a group to be stale when it's expired and when its
    /// expiration time and potentially executed operation timeout are both in
    /// the past.
    function isStaleGroup(
        Storage storage self,
        uint256 groupIndex
    ) public view returns(bool) {
        return groupStaleTime(self, self.groups[groupIndex]) < block.number;
    }

    /// @notice Gets the number of active groups. Expired and terminated groups are
    /// not counted as active.
    function numberOfGroups(
        Storage storage self
    ) internal view returns(uint256) {
        return self.groups.length.sub(self.expiredGroupOffset).sub(self.activeTerminatedGroups.length);
    }

    /// @notice Goes through groups starting from the oldest one that is still
    /// active and checks if it hasn't expired. If so, updates the information
    /// about expired groups so that all expired groups are marked as such.
    function expireOldGroups(Storage storage self) public {
        // Move expiredGroupOffset as long as there are some groups that should
        // be marked as expired. It is possible that expired group offset will
        // move out of the groups array by one position. It means that all groups
        // are expired (it points to the first active group) and that place in
        // groups array - currently empty - will be possibly filled later by
        // a new group.
        while(
            self.expiredGroupOffset < self.groups.length &&
            groupActiveTimeOf(self, self.groups[self.expiredGroupOffset]) < block.number
        ) {
            self.expiredGroupOffset++;
        }

        // Go through all activeTerminatedGroups and if some of the terminated
        // groups are expired, remove them from activeTerminatedGroups collection.
        // This is needed because we evaluate the shift of selected group index
        // based on how many non-expired groups has been terminated.
        for (uint i = 0; i < self.activeTerminatedGroups.length; i++) {
            if (self.expiredGroupOffset > self.activeTerminatedGroups[i]) {
                self.activeTerminatedGroups[i] = self.activeTerminatedGroups[self.activeTerminatedGroups.length - 1];
                self.activeTerminatedGroups.length--;
            }
        }
    }

    /// @notice Returns an index of a randomly selected active group. Terminated
    /// and expired groups are not considered as active.
    /// Before new group is selected, information about expired groups
    /// is updated. At least one active group needs to be present for this
    /// function to succeed.
    /// @param seed Random number used as a group selection seed.
    function selectGroup(
        Storage storage self,
        uint256 seed
    ) public returns(uint256) {
        expireOldGroups(self);

        require(numberOfGroups(self) > 0, "No active groups");

        uint256 selectedGroup = seed % numberOfGroups(self);
        return shiftByTerminatedGroups(self, shiftByExpiredGroups(self, selectedGroup));
    }

    /// @notice Evaluates the shift of selected group index based on the number of
    /// expired groups.
    function shiftByExpiredGroups(
        Storage storage self,
        uint256 selectedIndex
    ) internal view returns(uint256) {
        return self.expiredGroupOffset.add(selectedIndex);
    }

    /// @notice Evaluates the shift of selected group index based on the number of
    /// non-expired, terminated groups.
    function shiftByTerminatedGroups(
        Storage storage self,
        uint256 selectedIndex
    ) internal view returns(uint256) {
        uint256 shiftedIndex = selectedIndex;
        for (uint i = 0; i < self.activeTerminatedGroups.length; i++) {
            if (self.activeTerminatedGroups[i] <= shiftedIndex) {
                shiftedIndex++;
            }
        }

        return shiftedIndex;
    }

    /// @notice Withdraws accumulated group member rewards for operator
    /// using the provided group index.
    /// Once the accumulated reward is withdrawn from the selected group,
    /// the operator is flagged as withdrawn.
    /// Rewards can be withdrawn only from stale group.
    /// @param operator Operator address.
    /// @param groupIndex Group index.
    function withdrawFromGroup(
        Storage storage self,
        address operator,
        uint256 groupIndex
    ) public returns (uint256 rewards) {
        bool isExpired = self.expiredGroupOffset > groupIndex;
        bool isStale = isStaleGroup(self, groupIndex);
        require(isExpired && isStale, "Group must be expired and stale");
        bytes memory groupPublicKey = getGroupPublicKey(self, groupIndex);
        require(
            !(self.withdrawn[groupPublicKey][operator]),
            "Rewards already withdrawn"
        );
        self.withdrawn[groupPublicKey][operator] = true;
        for (uint i = 0; i < self.groupMembers[groupPublicKey].length; i++) {
            if (operator == self.groupMembers[groupPublicKey][i]) {
                rewards = rewards.add(self.groupMemberRewards[groupPublicKey]);
            }
        }
    }

    /// @notice Returns members of the given group by group public key.
    /// @param groupPubKey Group public key.
    function getGroupMembers(
        Storage storage self,
        bytes memory groupPubKey
    ) public view returns (address[] memory members) {
        return self.groupMembers[groupPubKey];
    }

    /// @notice Returns addresses of all the members in the provided group.
    function getGroupMembers(
        Storage storage self,
        uint256 groupIndex
    ) public view returns (address[] memory members) {
        bytes memory groupPubKey = self.groups[groupIndex].groupPubKey;
        return self.groupMembers[groupPubKey];
    }

    function getGroupRegistrationTime(
        Storage storage self,
        uint256 groupIndex
    ) public view returns (uint256) {
        return uint256(self.groups[groupIndex].registrationTime);
    }

    /// @notice Reports unauthorized signing for the provided group. Must provide
    /// a valid signature of the group address as a message. Successful signature
    /// verification means the private key has been leaked and all group members
    /// should be punished by seizing their tokens. The submitter of this proof is
    /// rewarded with 5% of the total seized amount scaled by the reward adjustment
    /// parameter and the rest 95% is burned. Group has to be active or expired.
    /// Unauthorized signing cannot be reported for stale or terminated group.
    /// In case of reporting unauthorized signing for stale group,
    /// terminated group, or when the signature is inavlid, function reverts.
    function reportUnauthorizedSigning(
        Storage storage self,
        uint256 groupIndex,
        bytes memory signedMsgSender,
        uint256 minimumStake
    ) public {
        require(!isStaleGroup(self, groupIndex), "Group can not be stale");
        bytes memory groupPubKey = getGroupPublicKey(self, groupIndex);

        require(
            BLS.verifyBytes(
                groupPubKey,
                abi.encodePacked(msg.sender),
                signedMsgSender
            ),
            "Invalid signature"
        );

        terminateGroup(self, groupIndex);
        self.stakingContract.seize(minimumStake, 100, msg.sender, self.groupMembers[groupPubKey]);
    }

    function reportRelayEntryTimeout(
        Storage storage self,
        uint256 groupIndex,
        uint256 groupSize
    ) public {
        uint256 punishment = relayEntryTimeoutPunishment(self);
        terminateGroup(self, groupIndex);
        // Reward is limited to min(1, 20 / group_size) of the maximum tattletale reward, see the Yellow Paper for more details.
        uint256 rewardAdjustment = uint256(20 * 100).div(groupSize); // Reward adjustment in percentage
        rewardAdjustment = rewardAdjustment > 100 ? 100:rewardAdjustment; // Reward adjustment can be 100% max
        self.stakingContract.seize(punishment, rewardAdjustment, msg.sender, getGroupMembers(self, groupIndex));
    }

    /// @notice Evaluates relay entry timeout punishment using the following
    /// rules:
    /// - 1% of the minimum stake for the first 3 months,
    /// - 50% of the minimum stake between the first 3 and 6 months,
    /// - 100% of the minimum stake after the first 6 months.
    function relayEntryTimeoutPunishment(
        Storage storage self
    ) public view returns (uint256) {
        uint256 minimumStake = self.stakingContract.minimumStake();

        uint256 stakingContractDeployedAt = self.stakingContract.deployedAt();
        /* solium-disable-next-line security/no-block-members */
        if (now < stakingContractDeployedAt + THREE_MONTHS) {
            return minimumStake.percent(1);
        /* solium-disable-next-line security/no-block-members */
        } else if (now < stakingContractDeployedAt + SIX_MONTHS) {
            return minimumStake.percent(50);
        } else {
            return minimumStake;
        }
    }

    /// @notice Return whether the given operator
    /// has withdrawn their rewards from the given group.
    function hasWithdrawnRewards(
        Storage storage self,
        address operator,
        uint256 groupIndex
    ) public view returns (bool) {
        return self.withdrawn[getGroupPublicKey(self, groupIndex)][operator];
    }
}
