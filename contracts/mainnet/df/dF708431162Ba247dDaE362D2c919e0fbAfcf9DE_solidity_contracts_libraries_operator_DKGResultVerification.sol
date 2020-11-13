pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "../../utils/BytesLib.sol";
import "./GroupSelection.sol";

library DKGResultVerification {
    using BytesLib for bytes;
    using ECDSA for bytes32;
    using GroupSelection for GroupSelection.Storage;

    struct Storage {
        // Time in blocks after which DKG result is complete and ready to be
        // published by clients.
        uint256 timeDKG;

        // Time in blocks after which the next group member is eligible
        // to submit DKG result.
        uint256 resultPublicationBlockStep;

        // Size of a group in the threshold relay.
        uint256 groupSize;

        // The minimum number of signatures required to support DKG result.
        // This number needs to be at least the same as the signing threshold
        // and it is recommended to make it higher than the signing threshold
        // to keep a safety margin for misbehaving members.
        uint256 signatureThreshold;
    }

    /// @notice Verifies the submitted DKG result against supporting member
    /// signatures and if the submitter is eligible to submit at the current
    /// block. Every signature supporting the result has to be from a unique
    /// group member.
    ///
    /// @param submitterMemberIndex Claimed submitter candidate group member index
    /// @param groupPubKey Generated candidate group public key
    /// @param misbehaved Bytes array of misbehaved (disqualified or inactive)
    /// group members indexes; Indexes reflect positions of members in the group,
    /// as outputted by the group selection protocol.
    /// @param signatures Concatenation of signatures from members supporting the
    /// result.
    /// @param signingMemberIndices Indices of members corresponding to each
    /// signature. Indices have to be unique.
    /// @param members Addresses of candidate group members as outputted by the
    /// group selection protocol.
    /// @param groupSelectionEndBlock Block height at which the group selection
    /// protocol ended.
    function verify(
        Storage storage self,
        uint256 submitterMemberIndex,
        bytes memory groupPubKey,
        bytes memory misbehaved,
        bytes memory signatures,
        uint256[] memory signingMemberIndices,
        address[] memory members,
        uint256 groupSelectionEndBlock
    ) public view {
        require(submitterMemberIndex > 0, "Invalid submitter index");
        require(
            members[submitterMemberIndex - 1] == msg.sender,
            "Unexpected submitter index"
        );

        uint T_init = groupSelectionEndBlock + self.timeDKG;
        require(
            block.number >= (T_init + (submitterMemberIndex-1) * self.resultPublicationBlockStep),
            "Submitter not eligible"
        );

        require(groupPubKey.length == 128, "Malformed group public key");

        require(
            misbehaved.length <= self.groupSize - self.signatureThreshold,
            "Malformed misbehaved bytes"
        );

        uint256 signaturesCount = signatures.length / 65;
        require(signatures.length >= 65, "Too short signatures array");
        require(signatures.length % 65 == 0, "Malformed signatures array");
        require(signaturesCount == signingMemberIndices.length, "Unexpected signatures count");
        require(signaturesCount >= self.signatureThreshold, "Too few signatures");
        require(signaturesCount <= self.groupSize, "Too many signatures");

        bytes32 resultHash = keccak256(abi.encodePacked(groupPubKey, misbehaved));

        bytes memory current; // Current signature to be checked.

        bool[] memory usedMemberIndices = new bool[](self.groupSize);

        for(uint i = 0; i < signaturesCount; i++){
            uint256 memberIndex = signingMemberIndices[i];
            require(memberIndex > 0, "Invalid index");
            require(memberIndex <= members.length, "Index out of range");

            require(!usedMemberIndices[memberIndex - 1], "Duplicate member index");
            usedMemberIndices[memberIndex - 1] = true;

            current = signatures.slice(65*i, 65);
            address recoveredAddress = resultHash.toEthSignedMessageHash().recover(current);
            require(members[memberIndex - 1] == recoveredAddress, "Invalid signature");
        }
    }
}
