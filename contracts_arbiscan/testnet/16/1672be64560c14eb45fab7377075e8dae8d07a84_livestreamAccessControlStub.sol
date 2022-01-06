/**
 *Submitted for verification at arbiscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract livestreamAccessControlStub {

    mapping(address => bool) public readAccessPermissionList;

    string internal constant ALREADY_PERMITTED = "ACCESS_IS_ALREADY_PERMITTED";
    string internal constant ALREADY_DENIED = "ACCESS_IS_ALREADY_DENIED";

    constructor() public {
    }

    function permitReadAccess(address viewerAddress) public {
        require(readAccessPermissionList[viewerAddress]==false,ALREADY_PERMITTED);
        readAccessPermissionList[viewerAddress] = true;
    }

    function denyReadAccess(address viewerAddress) public {
        require(readAccessPermissionList[viewerAddress]==true,ALREADY_DENIED);
        readAccessPermissionList[viewerAddress] = false;
    }

}