pragma solidity 0.5.17;

import "../utils/AddressArrayUtils.sol";
import "../StakeDelegatable.sol";
import "../TokenGrant.sol";
import "../ManagedGrant.sol";

/// @title Roles Lookup
/// @notice Library facilitating lookup of roles in stake delegation setup.
library RolesLookup {
    using AddressArrayUtils for address[];

    /// @notice Returns true if the tokenOwner delegated tokens to operator
    /// using the provided stakeDelegatable contract. Othwerwise, returns false.
    /// This function works only for the case when tokenOwner own those tokens
    /// and those are not tokens from a grant.
    function isTokenOwnerForOperator(
        address tokenOwner,
        address operator,
        StakeDelegatable stakeDelegatable
    ) internal view returns (bool) {
        return stakeDelegatable.ownerOf(operator) == tokenOwner;
    }

    /// @notice Returns true if the grantee delegated tokens to operator
    /// with the provided tokenGrant contract. Otherwise, returns false.
    /// This function works only for the case when tokens were generated from
    /// a non-managed grant, that is, the grantee is a non-contract address to
    /// which the delegated tokens were granted.
    /// @dev This function does not validate the staking reltionship on
    /// a particular staking contract. It only checks whether the grantee
    /// staked at least one time with the given operator. If you are interested
    /// in a particular token staking contract, you need to perform additional
    /// check.
    function isGranteeForOperator(
        address grantee,
        address operator,
        TokenGrant tokenGrant
    ) internal view returns (bool) {
        address[] memory operators = tokenGrant.getGranteeOperators(grantee);
        return operators.contains(operator);
    }

    /// @notice Returns true if the grantee from the given managed grant contract
    /// delegated tokens to operator with the provided tokenGrant contract.
    /// Otherwise, returns false. In case the grantee declared by the managed
    /// grant contract does not match the provided grantee, function reverts.
    /// This function works only for cases when grantee, from TokenGrant's
    /// perspective, is a smart contract exposing grantee() function returning
    /// the final grantee. One possibility is the ManagedGrant contract.
    /// @dev This function does not validate the staking reltionship on
    /// a particular staking contract. It only checks whether the grantee
    /// staked at least one time with the given operator. If you are interested
    /// in a particular token staking contract, you need to perform additional
    /// check.
    function isManagedGranteeForOperator(
        address grantee,
        address operator,
        address managedGrantContract,
        TokenGrant tokenGrant
    ) internal view returns (bool) {
        require(
            ManagedGrant(managedGrantContract).grantee() == grantee,
            "Not a grantee of the provided contract"
        );

        address[] memory operators = tokenGrant.getGranteeOperators(
            managedGrantContract
        );
        return operators.contains(operator);
    }

    /// @notice Returns true if grant with the given ID has been created with
    /// managed grant pointing currently to the grantee passed as a parameter.
    /// @dev The function does not revert if grant has not been created with
    /// a managed grantee. This function is not a view because it uses low-level
    /// call to check if the grant has been created with a managed grant.
    /// It does not however modify any state.
    function isManagedGranteeForGrant(
        address grantee,
        uint256 grantId,
        TokenGrant tokenGrant
    ) internal returns (bool) {
        (,,,,, address managedGrant) = tokenGrant.getGrant(grantId);
        (, bytes memory result) = managedGrant.call(
            abi.encodeWithSignature("grantee()")
        );
        if (result.length == 0) {
            return false;
        }
        address managedGrantee = abi.decode(result, (address));
        return grantee == managedGrantee;
    }
}