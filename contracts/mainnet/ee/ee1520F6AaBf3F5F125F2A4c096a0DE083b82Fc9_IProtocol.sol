// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IProtocol {
    event ProtocolVersionChanged(string deploymentSubset, uint256 currentVersion, uint256 nextVersion, uint256 fromTimestamp);

    /*
     *   External functions
     */

    /// @dev returns true if the given deployment subset exists (i.e - is registered with a protocol version)
    function deploymentSubsetExists(string calldata deploymentSubset) external view returns (bool);

    /// @dev returns the current protocol version for the given deployment subset.
    function getProtocolVersion(string calldata deploymentSubset) external view returns (uint256);

    /*
     *   Governance functions
     */

    /// @dev create a new deployment subset.
    function createDeploymentSubset(string calldata deploymentSubset, uint256 initialProtocolVersion) external /* onlyFunctionalManager */;

    /// @dev schedules a protocol version upgrade for the given deployment subset.
    function setProtocolVersion(string calldata deploymentSubset, uint256 nextVersion, uint256 fromTimestamp) external /* onlyFunctionalManager */;
}
