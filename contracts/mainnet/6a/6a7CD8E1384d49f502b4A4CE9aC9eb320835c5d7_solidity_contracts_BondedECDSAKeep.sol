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

pragma solidity 0.5.17;

import "./AbstractBondedECDSAKeep.sol";
import "./BondedECDSAKeepFactory.sol";

import "@keep-network/keep-core/contracts/TokenStaking.sol";

/// @title Bonded ECDSA Keep
/// @notice ECDSA keep with additional signer bond requirement.
/// @dev This contract is used as a master contract for clone factory in
/// BondedECDSAKeepFactory as per EIP-1167. It should never be removed after
/// initial deployment as this will break functionality for all created clones.
contract BondedECDSAKeep is AbstractBondedECDSAKeep {
    // Stake that was required from each keep member on keep creation.
    // The value is used for keep members slashing.
    uint256 public memberStake;

    // Emitted when KEEP token slashing failed when submitting signature
    // fraud proof. In practice, this situation should never happen but we want
    // to be very explicit in this contract and protect the owner that even if
    // it happens, the transaction submitting fraud proof is not going to fail
    // and keep owner can seize and liquidate bonds in the same transaction.
    event SlashingFailed();

    TokenStaking tokenStaking;

    /// @notice Initialization function.
    /// @dev We use clone factory to create new keep. That is why this contract
    /// doesn't have a constructor. We provide keep parameters for each instance
    /// function after cloning instances from the master contract.
    /// @param _owner Address of the keep owner.
    /// @param _members Addresses of the keep members.
    /// @param _honestThreshold Minimum number of honest keep members.
    /// @param _memberStake Stake required from each keep member.
    /// @param _stakeLockDuration Stake lock duration in seconds.
    /// @param _tokenStaking Address of the TokenStaking contract.
    /// @param _keepBonding Address of the KeepBonding contract.
    /// @param _keepFactory Address of the BondedECDSAKeepFactory that created
    /// this keep.
    function initialize(
        address _owner,
        address[] memory _members,
        uint256 _honestThreshold,
        uint256 _memberStake,
        uint256 _stakeLockDuration,
        address _tokenStaking,
        address _keepBonding,
        address payable _keepFactory
    ) public {
        super.initialize(_owner, _members, _honestThreshold, _keepBonding);

        memberStake = _memberStake;
        tokenStaking = TokenStaking(_tokenStaking);

        tokenStaking.claimDelegatedAuthority(_keepFactory);

        lockMemberStakes(_stakeLockDuration);
    }

    /// @notice Closes keep when owner decides that they no longer need it.
    /// Releases bonds to the keep members. Keep can be closed only when
    /// there is no signing in progress or requested signing process has timed out.
    /// @dev The function can be called only by the owner of the keep and only
    /// if the keep has not been already closed.
    function closeKeep() public onlyOwner onlyWhenActive {
        super.closeKeep();
        unlockMemberStakes();
    }

    /// @notice Terminates the keep.
    function terminateKeep() internal {
        super.terminateKeep();
        unlockMemberStakes();
    }

    function slashForSignatureFraud() internal {
        /* solium-disable-next-line */
        (bool success, ) = address(tokenStaking).call(
            abi.encodeWithSignature(
                "slash(uint256,address[])",
                memberStake,
                members
            )
        );

        // Should never happen but we want to protect the owner and make sure the
        // fraud submission transaction does not fail so that the owner can
        // seize and liquidate bonds in the same transaction.
        if (!success) {
            emit SlashingFailed();
        }
    }

    /// @notice Creates locks on members' token stakes.
    /// @param _stakeLockDuration Stake lock duration in seconds.
    function lockMemberStakes(uint256 _stakeLockDuration) internal {
        for (uint256 i = 0; i < members.length; i++) {
            tokenStaking.lockStake(members[i], _stakeLockDuration);
        }
    }

    /// @notice Releases locks the keep had previously placed on the members'
    /// token stakes.
    function unlockMemberStakes() internal {
        for (uint256 i = 0; i < members.length; i++) {
            tokenStaking.unlockStake(members[i]);
        }
    }

    /// @notice Gets the beneficiary for the specified member address.
    /// @param _member Member address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _member)
        internal
        view
        returns (address payable)
    {
        return tokenStaking.beneficiaryOf(_member);
    }
}
