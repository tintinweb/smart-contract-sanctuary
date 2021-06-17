// SPDX-License-Identifier: UNLICENSED;
pragma solidity ^0.8.0;

import "./EIP3074Simulation.sol";

contract MaliciousInvoker is EIP3074Simulation {

    function test(address who, string memory what, bytes32 commit, uint8 _v, bytes32 _r, bytes32 _s) public returns(bool success) {
        require(authTest(commit, _v, _r, _s) == who, "wrong signer");
        // No not checking for replay, nor for association between the commit and the what.
        success = authcallTestAndReset(what);
        return success;
    }
    
}