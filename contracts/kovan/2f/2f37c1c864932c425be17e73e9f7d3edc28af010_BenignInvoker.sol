// SPDX-License-Identifier: UNLICENSED;
pragma solidity ^0.8.0;

import "./EIP3074Simulation.sol";

contract BenignInvoker is EIP3074Simulation {
    mapping (bytes32 => bool) public replayProtection;

    function test(address who, string memory what, bytes32 commit, uint8 _v, bytes32 _r, bytes32 _s) public returns(bool success) {
        require(authTest(commit, _v, _r, _s) == who, "wrong signer");
        require(replayProtection[commit] == false, "replay");
        replayProtection[commit] = true;
        require(keccak256(abi.encodePacked(what)) == commit, "action does not match commit");
        success = authcallTestAndReset(what);
        return success;
    }
    
}