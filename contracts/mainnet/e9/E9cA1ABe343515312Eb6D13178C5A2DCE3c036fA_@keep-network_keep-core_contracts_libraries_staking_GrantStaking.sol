pragma solidity 0.5.17;

import "../../TokenGrant.sol";
import "../../TokenStakingEscrow.sol";
import "../..//utils/BytesLib.sol";
import "../RolesLookup.sol";

/// @notice TokenStaking contract library allowing to capture the details of
/// delegated grants and offering functions allowing to check grantee
/// authentication for stake delegation management.
library GrantStaking {
    using BytesLib for bytes;
    using RolesLookup for address payable;

    /// @dev Grant ID is flagged with the most significant bit set, to
    /// distinguish the grant ID `0` from default (null) value. The flag is
    /// toggled with bitwise XOR (`^`) which keeps all other bits intact but
    /// flips the flag bit. The flag should be set before writing to
    /// `operatorToGrant`, and unset after reading from `operatorToGrant`
    /// before using the value.
    uint256 constant GRANT_ID_FLAG = 1 << 255;

    struct Storage {
        /// @dev Do not read or write this mapping directly; please use
        /// `hasGrantDelegated`, `setGrantForOperator`, and `getGrantForOperator`
        /// instead.
        mapping (address => uint256) _operatorToGrant;
    }

    /// @notice Tries to capture delegation data if the pending delegation has
    /// been created from a grant. There are only two possibilities and they
    /// need to be handled differently: delegation comes from the TokenGrant
    /// contract or delegation comes from TokenStakingEscrow. In those two cases
    /// grant ID has to be captured in a different way.
    /// @dev In case of a delegation from the escrow, it is expected that grant
    /// ID is passed in extraData bytes array. When the delegation comes from
    /// the TokenGrant contract, delegation data are obtained directly from that
    /// contract using `tryCapturingGrantId` function.
    /// @param tokenGrant KEEP token grant contract reference.
    /// @param escrow TokenStakingEscrow contract address.
    /// @param from The owner of the tokens who approved them to transfer.
    /// @param operator The operator tokens are delegated to.
    /// @param extraData Data for stake delegation, as passed to
    /// `receiveApproval` of `TokenStaking`.
    function tryCapturingDelegationData(
        Storage storage self,
        TokenGrant tokenGrant,
        address escrow,
        address from,
        address operator,
        bytes memory extraData
    ) public returns (bool, uint256) {
        if (from == escrow) {
            require(extraData.length == 92, "Corrupted delegation data from escrow");
            uint256 grantId = extraData.toUint(60);
            setGrantForOperator(self, operator, grantId);
            return (true, grantId);
        } else {
            return tryCapturingGrantId(self, tokenGrant, operator);
        }
    }

    /// @notice Checks if the delegation for the given operator has been created
    /// from a grant defined in the passed token grant contract and if so,
    /// captures the grant ID for that delegation.
    /// Grant ID can be later retrieved based on the operator address and used
    /// to authenticate grantee or to fetch the information about grant
    /// unlocking schedule for escrow.
    /// @param tokenGrant KEEP token grant contract reference.
    /// @param operator The operator tokens are delegated to.
    function tryCapturingGrantId(
        Storage storage self,
        TokenGrant tokenGrant,
        address operator
    ) internal returns (bool, uint256) {
        (bool success, bytes memory data) = address(tokenGrant).call(
            abi.encodeWithSignature("getGrantStakeDetails(address)", operator)
        );
        if (success) {
            (uint256 grantId,,address grantStakingContract) = abi.decode(
                data, (uint256, uint256, address)
            );
            // Double-check if the delegation in TokenGrant has been defined
            // for this staking contract. If not, it means it's an old
            // delegation and the current one does not come from a grant.
            // The scenario covered here is:
            // - grantee delegated to operator A from a TokenGrant using another
            //   staking contract,
            // - someone delegates to operator A using liquid tokens and this
            //   staking contract.
            // Without this check, we'd consider the second delegation as coming
            // from a grant.
            if (address(this) != grantStakingContract) {
                return (false, 0);
            }

            setGrantForOperator(self, operator, grantId);
            return (true, grantId);
        }

        return (false, 0);
    }

    /// @notice Returns true if the given operator operates on stake delegated
    /// from a grant. false is returned otherwise.
    /// @param operator The operator to which tokens from a grant are
    /// potentially delegated to.
    function hasGrantDelegated(
        Storage storage self,
        address operator
    ) public view returns (bool) {
        return self._operatorToGrant[operator] != 0;
    }

    /// @notice Associates operator with the provided grant ID. It means that
    /// the given operator delegates on stake from the grant with this ID.
    /// @param operator The operator tokens are delegate to.
    /// @param grantId Identifier of a grant from which the tokens are delegated
    /// to.
    function setGrantForOperator(
        Storage storage self,
        address operator,
        uint256 grantId
    ) public {
        self._operatorToGrant[operator] = grantId ^ GRANT_ID_FLAG;
    }

    /// @notice Returns grant ID for the provided operator. If the operator
    /// does not operate on stake delegated from a grant, function reverts.
    /// @dev To avoid reverting in case the grant ID for the operator does not
    /// exist, consider calling hasGrantDelegated before.
    /// @param operator The operator tokens are delegate to.
    function getGrantForOperator(
        Storage storage self,
        address operator
    ) public view returns (uint256) {
        uint256 grantId = self._operatorToGrant[operator];
        require (grantId != 0, "No grant for the operator");
        return grantId ^ GRANT_ID_FLAG;
    }

    /// @notice Returns true if msg.sender is grantee eligible to trigger stake
    /// undelegation for this operator. Function checks both standard grantee
    /// and managed grantee case.
    /// @param operator The operator tokens are delegated to.
    /// @param tokenGrant KEEP token grant contract reference.
    function canUndelegate(
        Storage storage self,
        address operator,
        TokenGrant tokenGrant
    ) public returns (bool) {
        // First of all, we need to see if the operator has grant delegated.
        // If not, we don't need to bother about checking grantee or
        // managed grantee and we just return false.
        if (!hasGrantDelegated(self, operator)) {
            return false;
        }

        uint256 grantId = getGrantForOperator(self, operator);
        (,,,,uint256 revokedAt, address grantee) = tokenGrant.getGrant(grantId);

        // Is msg.sender grantee of a standard grant?
        if (msg.sender == grantee) {
            return true;
        }

        // If not, we need to dig deeper and see if we are dealing with
        // a grantee from a managed grant.
        if ((msg.sender).isManagedGranteeForGrant(grantId, tokenGrant)) {
            return true;
        }

        // There is only one possibility left - grant has been revoked and
        // grant manager wants to take back delegated tokens.
        if (revokedAt == 0) {
            return false;
        }
        (address grantManager,,,,) = tokenGrant.getGrantUnlockingSchedule(grantId);
        return msg.sender == grantManager;
    }
}