/**
 *Submitted for verification at arbiscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract livestreamServerConfigurationDatabase {

    struct AccessPermissionsSet {
        bool consumeVideo;
        bool consumeAudio;
        bool publishVideo;
        bool publishAudio;
        bool editPermissions;
    }

    mapping(address => AccessPermissionsSet) public accessPermissionsList;

    string internal constant ALREADY_GRANTED = "ACCESS_IS_ALREADY_GRANTED";
    string internal constant ALREADY_REVOKED = "ACCESS_IS_ALREADY_REVOKED";
    string internal constant NOT_AUTHORISED = "YOU_ARE_NOT_AUTHORISED_TO_DO_THAT";

    constructor() {
        accessPermissionsList[msg.sender] = AccessPermissionsSet(false, false, false, false, true);
    }

    function grantConsumeVideoAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.consumeVideo==false,ALREADY_GRANTED);

        userAddressAccessPermissionsSet.consumeVideo = true;
    }

    function revokeConsumeVideoAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.consumeVideo==true,ALREADY_REVOKED);

        userAddressAccessPermissionsSet.consumeVideo = false;
    }

    function grantConsumeAudioAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.consumeAudio==false,ALREADY_GRANTED);

        userAddressAccessPermissionsSet.consumeAudio = true;
    }

    function revokeConsumeAudioAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.consumeAudio==true,ALREADY_REVOKED);

        userAddressAccessPermissionsSet.consumeAudio = false;
    }

    function grantPublishVideoAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.publishVideo==false,ALREADY_GRANTED);

        userAddressAccessPermissionsSet.publishVideo = true;
    }

    function revokePublishVideoAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.publishVideo==true,ALREADY_REVOKED);

        userAddressAccessPermissionsSet.publishVideo = false;
    }

    function grantPublishAudioAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.publishAudio==false,ALREADY_GRANTED);

        userAddressAccessPermissionsSet.publishVideo = true;
    }

    function revokePublishAudioAccess(address userAddress) public {
        AccessPermissionsSet storage requestorAddressAccessPermissionsSet = accessPermissionsList[msg.sender];
        require(requestorAddressAccessPermissionsSet.editPermissions==true,NOT_AUTHORISED);

        AccessPermissionsSet storage userAddressAccessPermissionsSet = accessPermissionsList[userAddress];
        require(userAddressAccessPermissionsSet.publishAudio==true,ALREADY_REVOKED);

        userAddressAccessPermissionsSet.publishAudio = false;
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