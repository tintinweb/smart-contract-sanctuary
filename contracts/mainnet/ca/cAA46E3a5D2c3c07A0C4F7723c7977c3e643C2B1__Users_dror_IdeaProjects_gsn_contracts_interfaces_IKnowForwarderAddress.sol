// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

interface IKnowForwarderAddress {

    /**
     * return the forwarder we trust to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function getTrustedForwarder() external view returns(address);
}
