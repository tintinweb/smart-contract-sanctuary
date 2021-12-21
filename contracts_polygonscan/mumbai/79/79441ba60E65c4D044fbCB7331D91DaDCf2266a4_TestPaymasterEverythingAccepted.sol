// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IForwarder.sol";
import "./BasePaymaster.sol";

contract TestPaymasterEverythingAccepted is BasePaymaster {

    event SampleRecipientPreCall();
    event SampleRecipientPostCall(bool success, uint actualCharge);

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
        external
        override
        virtual
        returns (bytes memory, bool)
    {
        (signature);
        _verifyForwarder(relayRequest);
        (approvalData, maxPossibleGas);

        emit SampleRecipientPreCall();

        return ("no revert here", false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
        external
        override
        virtual
    {
        (context, gasUseWithoutPost, relayData);

        emit SampleRecipientPostCall(success, gasUseWithoutPost);
    }

    function deposit() public payable {
        require(address(relayHub) != address(0), "relay hub address not set");

        relayHub.depositFor{value:msg.value}(address(this));
    }

    function withdrawAll(address payable destination) public {
        uint256 amount = relayHub.balanceOf(address(this));
        withdrawRelayHubDepositTo(amount, destination);
    }

    function versionPaymaster() external view override virtual returns (string memory) {
        return "2.2.3+opengsn.test-pea.ipaymaster";
    }
}