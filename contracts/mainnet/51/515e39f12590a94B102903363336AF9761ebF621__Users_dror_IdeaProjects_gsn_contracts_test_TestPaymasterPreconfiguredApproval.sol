// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterPreconfiguredApproval is TestPaymasterEverythingAccepted {

    bytes public expectedApprovalData;

    function setExpectedApprovalData(bytes memory val) public {
        expectedApprovalData = val;
    }

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    returns (bytes memory, bool) {
        (relayRequest, signature, approvalData, maxPossibleGas);
        _verifyForwarder(relayRequest);
        require(keccak256(expectedApprovalData) == keccak256(approvalData),
            string(abi.encodePacked(
                "test: unexpected approvalData: '", approvalData, "' instead of '", expectedApprovalData, "'")));
        return ("",false);
    }
}
