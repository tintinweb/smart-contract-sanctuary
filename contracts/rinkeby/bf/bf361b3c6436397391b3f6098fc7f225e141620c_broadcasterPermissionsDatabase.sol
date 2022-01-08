/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

// A simple database for storing and updating user permissions.
// Permissions relate to publish to, and consuming from a broadcaster.

pragma solidity ^0.8.6;

contract broadcasterPermissionsDatabase {

// broadcaster can read from the database, and permit authenticated users to operate.
// If broadcaster has an address itself, it can also write to the database.
// A broadcaster may also wish to deploy its own instance of the database.

    // this is the basic set of permissions stored in the database.
    struct PermissionsSet {
        bool canPublish;
        bool canConsume;
        bool isAdmin;
    }

    // create a mapping of any address onto a PermissionsSet
    mapping(address => PermissionsSet) public permissionsSet;

    // declare some error messages to be thrown, for debugging and visibility
    string internal constant ALREADY_GRANTED = "ACCESS_IS_ALREADY_GRANTED";
    string internal constant ALREADY_REVOKED = "ACCESS_IS_ALREADY_REVOKED";
    string internal constant NOT_AUTHORISED = "YOU_ARE_NOT_AUTHORISED_TO_DO_THAT";

    // function is used to set up the contract
    // grants admin rights to address deploying the database contract
    constructor() {
        permissionsSet[msg.sender] = PermissionsSet(false, false, true);
    }

    // updates the database
    // grants the user's permission to publish to the broadcaster
    function grantPublishPermission(address user) public {

        // verify that caller is admin
        PermissionsSet storage requestorPermissionsSet = permissionsSet[msg.sender];
        require(requestorPermissionsSet.isAdmin==true,NOT_AUTHORISED);

        // make sure user does not already have permission to publish granted
        PermissionsSet storage userPermissionsSet = permissionsSet[user];
        require(userPermissionsSet.canPublish==false,ALREADY_GRANTED);

        // let user publish content
        permissionsSet[user].canPublish = true;
    }

    // updates the database
    // revokes the user's permission to publish to the broadcaster
    function revokePublishPermission(address user) public {

        // verify that caller is admin
        PermissionsSet storage requestorPermissionsSet = permissionsSet[msg.sender];
        require(requestorPermissionsSet.isAdmin==true,NOT_AUTHORISED);

        // make sure user's permission to publish is not already revoked
        PermissionsSet storage userPermissionsSet = permissionsSet[user];
        require(userPermissionsSet.canPublish==true,NOT_AUTHORISED);

        // don't let user publish content
        permissionsSet[user].canPublish = false;
    }

    // updates the database
    // grants the user's permission to consume from the broadcaster
    function grantConsumePermission(address user) public {

        // verify that caller is admin
        PermissionsSet storage requestorPermissionsSet = permissionsSet[msg.sender];
        require(requestorPermissionsSet.isAdmin==true,NOT_AUTHORISED);

        // make sure user's permission to consume is not already granted
        PermissionsSet storage userPermissionsSet = permissionsSet[user];
        require(userPermissionsSet.canConsume==false,ALREADY_GRANTED);

        // let user consume content
        permissionsSet[user].canConsume = true;
    }

    // updates the database
    // revokes the user's permission to consume from the broadcaster
    function revokeConsumePermission(address user) public {

        // verify that caller is admin
        PermissionsSet storage requestorPermissionsSet = permissionsSet[msg.sender];
        require(requestorPermissionsSet.isAdmin==true,NOT_AUTHORISED);

        // make sure user's permission to consume is not already revoked
        PermissionsSet storage userPermissionsSet = permissionsSet[user];
        require(userPermissionsSet.canConsume==true,ALREADY_REVOKED);

        // don't let user consume content
        permissionsSet[user].canConsume = false;
    }

    // updates the database
    // grants the user's permission to administer the database
    function grantAdmin(address user) public {

        // verify that caller is admin
        PermissionsSet storage requestorPermissionsSet = permissionsSet[msg.sender];
        require(requestorPermissionsSet.isAdmin==true,NOT_AUTHORISED);

        // make sure user's permission to administer the database is not already granted
        PermissionsSet storage userPermissionsSet = permissionsSet[user];
        require(userPermissionsSet.isAdmin==false,ALREADY_GRANTED);

        // permit user to be able to do exactly what you can do yourself on this database
        permissionsSet[user].isAdmin = true;
    }

    // for reading the user's canPublish permission
    function canPublish(address user) external view returns (bool) {
        return permissionsSet[user].canPublish;
    }

    // for reading the user's canConsume permission
    function canConsume(address user) external view returns (bool) {
        return permissionsSet[user].canConsume;
    }

    // for reading the user's isAdmin permission
    function isAdmin(address user) external view returns (bool) {
        return permissionsSet[user].isAdmin;
    }
}