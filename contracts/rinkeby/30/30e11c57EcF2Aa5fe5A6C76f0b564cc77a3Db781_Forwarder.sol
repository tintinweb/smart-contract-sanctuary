// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

/// @dev This contract exists to act as a guard before a transaction is executed
/// so that the caller is guaranteed that no code exists at the target address
/// at the time of the call. This is useful for deterministic deployments: many
/// deterministic deployer contracts revert if the deterministic contract
/// address already has some code before the deployment.
/// However, this might not be a desired behavior in certain scenarios, for
/// example when deploying deterministically in a DAO proposal, as a revert
/// would halt the execution of the remaining transactions.
/// @title Call Forwarder
/// @author CoW Protocol Developers
contract Forwarder {
    /// @dev Forwards a call to a contract if no code is present at the address
    /// to test. Otherwise, the transaction succeeds without any side effects,
    /// in particular without forwarding the transaction.
    /// @param addressToTest Address to test for the presence of bytecode.
    /// @param data The calldata of the function that will be forwarded.
    /// @param callTarget The address that will be the target of the call.
    function forwardIfNoCodeAt(
        address addressToTest,
        bytes calldata data,
        address callTarget
    ) external {
        if (addressToTest.code.length == 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = callTarget.call(data);
            require(success, "Forwarded call failed");
        }
    }
}