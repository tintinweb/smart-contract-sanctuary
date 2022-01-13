/**
 *Submitted for verification at arbiscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract generalisedGatekeeper {

    bool internal canPublishBool = false;

    constructor() {        
    }

    function canPublish(address user) external view returns (bool) {
        return canPublishBool;
    }

    function makeCanPublishBoolTrue() public {
        canPublishBool=true;
    }

    function makeCanPublishBoolFalse() public {
        canPublishBool=false;
    }

}