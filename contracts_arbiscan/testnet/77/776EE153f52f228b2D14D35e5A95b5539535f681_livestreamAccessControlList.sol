/**
 *Submitted for verification at arbiscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract livestreamAccessControlList {

    struct AccessPermissionsSet {
        bool consume;
        bool publish;
        bool editPermissions;
    }

    mapping(address => AccessPermissionsSet) public accessPermissionsList;

    string internal constant ALREADY_GRANTED = "ACCESS_IS_ALREADY_GRANTED";
    string internal constant ALREADY_REVOKED = "ACCESS_IS_ALREADY_REVOKED";
    string internal constant NOT_AUTHORISED = "YOU_ARE_NOT_AUTHORISED_TO_DO_THAT";

    constructor() {
        accessPermissionsList[msg.sender] = AccessPermissionsSet(false, false, true);
    }

    function grantConsumeAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.consume==false,ALREADY_GRANTED);

        userAddressAccessPermissionsSet.consume = true;
    }

    function revokeConsumeAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.consume==true,ALREADY_REVOKED);

        userAddressAccessPermissionsSet.consume = false;
    }

    function grantPublishAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.publish==false,ALREADY_GRANTED);

        userAddressAccessPermissionsSet.publish = true;
    }

    function revokePublishAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.publish==true,ALREADY_REVOKED);

        userAddressAccessPermissionsSet.publish = false;
    }

    function grantEditPermissionsAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.editPermissions==false,ALREADY_GRANTED);

        userAddressAccessPermissionsSet.editPermissions = true;
    }

    function revokeEditPermissionsAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.editPermissions==true,ALREADY_REVOKED);

        userAddressAccessPermissionsSet.editPermissions = false;
    }

}