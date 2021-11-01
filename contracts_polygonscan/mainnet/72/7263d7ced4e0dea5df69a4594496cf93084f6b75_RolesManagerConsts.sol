/**
 *Submitted for verification at polygonscan.com on 2021-11-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract RolesManagerConsts {
    /**
        @notice It is the AccessControl.DEFAULT_ADMIN_ROLE role.
     */
    bytes32 public constant OWNER_ROLE = keccak256("");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant PIXU_MINTER_ROLE = keccak256("PIXU_MINTER_ROLE");

    bytes32 public constant PIXUCATS_MINTER_ROLE = keccak256("PIXUCATS_MINTER_ROLE");

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    bytes32 public constant SKULLOIDS_MINTER_ROLE = keccak256("SKULLOIDS_MINTER_ROLE");
}