// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterOwnerSignature is TestPaymasterEverythingAccepted {
    using ECDSA for bytes32;

    /**
     * This demonstrates how dapps can provide an off-chain signatures to relayed transactions.
     */
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    returns (bytes memory, bool) {
        (signature, maxPossibleGas);
        _verifyForwarder(relayRequest);

        address signer =
            keccak256(abi.encodePacked("I approve", relayRequest.request.from))
            .toEthSignedMessageHash()
            .recover(approvalData);
        require(signer == owner(), "test: not approved");
        return ("",false);
    }
}
