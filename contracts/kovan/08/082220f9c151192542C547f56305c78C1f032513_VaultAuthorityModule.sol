/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/modules/VaultAuthorityModule.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.10 >=0.7.0;

////// lib/solmate/src/auth/Auth.sol
/* pragma solidity >=0.7.0; */

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed owner);

    event AuthorityUpdated(Authority indexed authority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(_owner);
        emit AuthorityUpdated(_authority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(owner);
    }

    function setAuthority(Authority newAuthority) public virtual requiresAuth {
        authority = newAuthority;

        emit AuthorityUpdated(authority);
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority cachedAuthority = authority;

        if (address(cachedAuthority) != address(0)) {
            try cachedAuthority.canCall(user, address(this), functionSig) returns (bool canCall) {
                if (canCall) return true;
            } catch {}
        }

        return user == owner;
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }
}

////// src/modules/VaultAuthorityModule.sol
/* pragma solidity 0.8.10; */

/* import {Auth, Authority} from "solmate/auth/Auth.sol"; */

/// @title Rari Vault Authority Module
/// @notice Module for managing access to secured Vault operations.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
contract VaultAuthorityModule is Auth, Authority {
    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a Vault configuration module.
    /// @param _owner The owner of the module.
    /// @param _authority The Authority of the module.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                       CUSTOM TARGET AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps targets to a custom Authority to use for authorization.
    mapping(address => Authority) public getTargetCustomAuthority;

    /*///////////////////////////////////////////////////////////////
                             USER ROLE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps users to a bytes32 set of all the roles assigned to them.
    mapping(address => bytes32) public getUserRoles;

    /// @notice Gets whether a user has a specific role.
    /// @param user The user to check for.
    /// @param role The role to check if the user has.
    /// @return A boolean indicating whether the user has the role.
    function doesUserHaveRole(address user, uint8 role) external view returns (bool) {
        unchecked {
            // Generate a mask for the role.
            bytes32 shifted = bytes32(uint256(uint256(2)**uint256(role)));

            // Check if the user has the role using the generated mask.
            return bytes32(0) != getUserRoles[user] & shifted;
        }
    }

    /*///////////////////////////////////////////////////////////////
                        ROLE CAPABILITY STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps function signatures to a set of all roles that can call the given function.
    mapping(bytes4 => bytes32) public getRoleCapabilities;

    /// @notice Maps function signatures to a boolean indicating whether anyone can call the given function.
    mapping(bytes4 => bool) public isCapabilityPublic;

    /// @notice Gets whether a role has a specific capability.
    /// @param role The role to check for.
    /// @param functionSig function to check the role is capable of calling.
    /// @return A boolean indicating whether the role has the capability.
    function doesRoleHaveCapability(uint8 role, bytes4 functionSig) external view virtual returns (bool) {
        unchecked {
            // Generate a mask for the role.
            bytes32 shifted = bytes32(uint256(uint256(2)**uint256(role)));

            // Check if the role has the capability using the generated mask.
            return bytes32(0) != getRoleCapabilities[functionSig] & shifted;
        }
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns if a user can call a given target's function.
    /// @param user The user to check for.
    /// @param target The target the user is trying to call.
    /// @param functionSig The function signature the user is trying to call.
    /// @return A boolean indicating if the user can call the function on the target.
    /// @dev First checks whether the target has a custom Authority assigned to it, if so returns
    /// whether the custom Authority would allow the user to call the desired function on the target,
    /// otherwise returns whether the user is able to call the desired function on any target contract.
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view override returns (bool) {
        // Get the target's custom Authority. Will be address(0) if none.
        Authority customAuthority = getTargetCustomAuthority[target];

        // If a custom Authority is set, return whether the Authority allows the user to call the function.
        if (address(customAuthority) != address(0)) return customAuthority.canCall(user, target, functionSig);

        // Return whether the user has an authorized role or the capability is publicly accessible.
        return bytes32(0) != getUserRoles[user] & getRoleCapabilities[functionSig] || isCapabilityPublic[functionSig];
    }

    /*///////////////////////////////////////////////////////////////
               CUSTOM TARGET AUTHORITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a custom Authority is set for a target.
    /// @param target The target who had a custom Authority set.
    /// @param authority The custom Authority set for the target.
    event TargetCustomAuthorityUpdated(address indexed target, Authority indexed authority);

    /// @notice Sets a custom Authority for a target.
    /// @param target The target to set a custom Authority for.
    /// @param customAuthority The custom Authority to set.
    function setTargetCustomAuthority(address target, Authority customAuthority) external requiresAuth {
        // Update the target's custom Authority.
        getTargetCustomAuthority[target] = customAuthority;

        emit TargetCustomAuthorityUpdated(target, customAuthority);
    }

    /*///////////////////////////////////////////////////////////////
                  ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a role's capabilities are updated.
    /// @param role The role whose capabilities were updated.
    /// @param functionSig The function the role was enabled to call or not.
    /// @param enabled Whether the role is now able to call the function or not.
    event RoleCapabilityUpdated(uint8 indexed role, bytes4 indexed functionSig, bool enabled);

    /// @notice Sets a capability for a role.
    /// @param role The role to set a capability for.
    /// @param functionSig The function to enable the role to call or not.
    /// @param enabled Whether the role should be able to call the function or not.
    function setRoleCapability(
        uint8 role,
        bytes4 functionSig,
        bool enabled
    ) external requiresAuth {
        // Get the previous set of role capabilities.
        bytes32 lastCapabilities = getRoleCapabilities[functionSig];

        unchecked {
            // Generate a mask for the role.
            bytes32 shifted = bytes32(uint256(uint256(2)**uint256(role)));

            // Update the role's capability set with the role mask.
            getRoleCapabilities[functionSig] = enabled ? lastCapabilities | shifted : lastCapabilities & ~shifted;
        }

        emit RoleCapabilityUpdated(role, functionSig, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                  PUBLIC CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when whether a capability is public is updated.
    /// @param functionSig The function that was made public or not.
    /// @param enabled Whether the function is not publicly callable or not.
    event PublicCapabilityUpdated(bytes4 indexed functionSig, bool enabled);

    /// @notice Sets whether a capability is public or not.
    /// @param functionSig The function make public or not.
    /// @param enabled Whether the function should be public or not.
    function setPublicCapability(bytes4 functionSig, bool enabled) external requiresAuth {
        // Update whether the capability is public.
        isCapabilityPublic[functionSig] = enabled;

        emit PublicCapabilityUpdated(functionSig, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                      USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a user's role is updated.
    /// @param user The user who had their role updated.
    /// @param role The role the user had assigned/removed.
    /// @param enabled Whether the user had the role assigned/removed.
    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    /// @notice Assigns a role to a user.
    /// @param user The user to assign a role to.
    /// @param role The role to assign to the user.
    /// @param enabled Whether the user should have the role or not.
    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) external requiresAuth {
        // Get the previous set of roles.
        bytes32 lastRoles = getUserRoles[user];

        unchecked {
            // Generate a mask for the role.
            bytes32 shifted = bytes32(uint256(uint256(2)**uint256(role)));

            // Update the user's role set with the role mask.
            getUserRoles[user] = enabled ? lastRoles | shifted : lastRoles & ~shifted;
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}