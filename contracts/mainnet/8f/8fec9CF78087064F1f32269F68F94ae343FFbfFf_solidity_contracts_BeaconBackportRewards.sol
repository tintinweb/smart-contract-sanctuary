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

/// @title KEEP Random Beacon Signer Subsidy Rewards for the May release.
/// @notice Contract distributing KEEP rewards to Random Beacon signers from
/// May KeepRandomBeaconOperator contract:
/// https://etherscan.io/address/0x70F2202D85a4F0Cad36e978976f84E982920A624
///
/// We use a separate contract for those rewards as the previous version of
/// KeepRandomBeaconOperator did not have all the functions BeaconRewards uses.
///
/// Groups from May release of KeepRandomBeaconOperator contract can claim their
/// rewards at any time.
contract BeaconBackportRewards is Rewards {

    // Beacon genesis date, 2020-05-11, is the interval start.
    // https://etherscan.io/tx/0x5c0387a2402be57dae95d5f5c3745afb3a770462df13fceccf3967a1eecf6136
    uint256 internal constant beaconIntervalStart = 1589155200;

    // We are going to have one interval, with a weight of 100%.
    uint256[] internal beaconIntervalWeight = [100];

    // 136 days between the genesis of the old and the new random beacon
    // contract versions:
    // https://etherscan.io/tx/0x5c0387a2402be57dae95d5f5c3745afb3a770462df13fceccf3967a1eecf6136
    // https://etherscan.io/tx/0xe2e8ab5631473a3d7d8122ce4853c38f5cc7d3dcbfab3607f6b27a7ef3b86da2
    uint256 internal constant beaconTermLength = 136 days;

    // There were three beacon groups created during those 135 days:
    // 0x2e490c9c6d822341a23a2c37c203cff8530345ce59c8f3d218cd7f2a21bf5ac51c6f...827,
    // 0x065d0e58684df0fc3fad2155e07fb1861b521679f267e440028ec1237a8be58e0e2f...49f,
    // 0x118e601ef5f594cd29053ee47490edbaae895109704af19d57114c4a77fa73041d44...652.  
    //
    // We hardcode this number because the previous KeepRandomBeaconOperator
    // contract version had no easy way to get the number of all groups created.
    uint256 internal constant numberOfCreatedGroups = 3;

    // We allocate all rewards to those groups.
    uint256 internal constant minimumBeaconGroupsPerInterval = numberOfCreatedGroups;

    KeepRandomBeaconOperator operatorContract;
    TokenStaking tokenStaking;

    constructor (
        address _token,
        address _operatorContract,
        address _stakingContract
    ) public Rewards(
        _token,
        beaconIntervalStart,
        beaconIntervalWeight,
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

    function _getKeepCount() internal view returns (uint256) {
        return numberOfCreatedGroups;
    }

    function _getKeepAtIndex(uint256 i) internal view returns (bytes32) {
        return bytes32(i);
    }

    function _getCreationTime(bytes32) internal view returns (uint256) {
        // Assign each group to the starting timestamp of its interval
        return startOf(0);
    }

    function _isClosed(bytes32) internal view returns (bool) {
        // All groups within the eligible range are considered happily closed.
        return true;
    }

    function _isTerminated(bytes32 groupIndexBytes) internal view returns (bool) {
        return false;
    }

    function _recognizedByFactory(bytes32 groupIndexBytes) internal view returns (bool) {
        return numberOfCreatedGroups > uint256(groupIndexBytes);
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
