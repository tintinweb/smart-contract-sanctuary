// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { SnowPatrolBase } from "./SnowPatrolBase.sol";
import { ISnowPatrol } from "./ISnowPatrol.sol";

contract SnowPatrol is ISnowPatrol, SnowPatrolBase {
    bytes32 public override constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public override constant LGE_ROLE = keccak256("LGE");
    bytes32 public override constant FROST_ROLE = keccak256("FROST");
    bytes32 public override constant SLOPES_ROLE = keccak256("SLOPES");
    bytes32 public override constant LODGE_ROLE = keccak256("LODGE");

    constructor(address addressRegistry)
        public
        SnowPatrolBase(addressRegistry)
    {
        // make owner user the sole superuser
        _initializeRoles(msg.sender);
        _initializeAdmins(msg.sender);
    }

    // inititalize all default roles, make the contract the superuser
    function _initializeRoles(address _deployer) private {
        _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
        _setupRole(ADMIN_ROLE, _deployer);
        _setupRole(LGE_ROLE, _deployer);
        _setupRole(FROST_ROLE, _deployer);
        _setupRole(SLOPES_ROLE, _deployer);
        _setupRole(LODGE_ROLE, _deployer);
    }

     // grant admin role to dev addresses
    function _initializeAdmins(address _deployer) private {
        grantRole(ADMIN_ROLE, _deployer);
       
    }

    function setCoreRoles() 
        external
        override
    {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "Only Admins can update contract roles"
        );

        // if 
    }
}