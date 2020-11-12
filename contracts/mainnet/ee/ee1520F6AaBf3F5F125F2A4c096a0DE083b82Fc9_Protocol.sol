// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./IProtocol.sol";
import "./ManagedContract.sol";

contract Protocol is IProtocol, ManagedContract {

    struct DeploymentSubset {
        bool exists;
        uint256 nextVersion;
        uint fromTimestamp;
        uint256 currentVersion;
    }

    mapping(string => DeploymentSubset) public deploymentSubsets;

    constructor(IContractRegistry _contractRegistry, address _registryAdmin) ManagedContract(_contractRegistry, _registryAdmin) public {}

    /*
     * External functions
     */

    function deploymentSubsetExists(string calldata deploymentSubset) external override view returns (bool) {
        return deploymentSubsets[deploymentSubset].exists;
    }

    function getProtocolVersion(string calldata deploymentSubset) external override view returns (uint256 currentVersion) {
        (, currentVersion) = checkPrevUpgrades(deploymentSubset);
    }

    function createDeploymentSubset(string calldata deploymentSubset, uint256 initialProtocolVersion) external override onlyFunctionalManager {
        require(!deploymentSubsets[deploymentSubset].exists, "deployment subset already exists");

        deploymentSubsets[deploymentSubset].currentVersion = initialProtocolVersion;
        deploymentSubsets[deploymentSubset].nextVersion = initialProtocolVersion;
        deploymentSubsets[deploymentSubset].fromTimestamp = now;
        deploymentSubsets[deploymentSubset].exists = true;

        emit ProtocolVersionChanged(deploymentSubset, initialProtocolVersion, initialProtocolVersion, now);
    }

    function setProtocolVersion(string calldata deploymentSubset, uint256 nextVersion, uint256 fromTimestamp) external override onlyFunctionalManager {
        require(deploymentSubsets[deploymentSubset].exists, "deployment subset does not exist");
        require(fromTimestamp > now, "a protocol update can only be scheduled for the future");

        (bool prevUpgradeExecuted, uint256 currentVersion) = checkPrevUpgrades(deploymentSubset);

        require(nextVersion >= currentVersion, "protocol version must be greater or equal to current version");

        deploymentSubsets[deploymentSubset].nextVersion = nextVersion;
        deploymentSubsets[deploymentSubset].fromTimestamp = fromTimestamp;
        if (prevUpgradeExecuted) {
            deploymentSubsets[deploymentSubset].currentVersion = currentVersion;
        }

        emit ProtocolVersionChanged(deploymentSubset, currentVersion, nextVersion, fromTimestamp);
    }

    /*
     * Private functions
     */

    function checkPrevUpgrades(string memory deploymentSubset) private view returns (bool prevUpgradeExecuted, uint256 currentVersion) {
        prevUpgradeExecuted = deploymentSubsets[deploymentSubset].fromTimestamp <= now;
        currentVersion = prevUpgradeExecuted ? deploymentSubsets[deploymentSubset].nextVersion :
                                               deploymentSubsets[deploymentSubset].currentVersion;
    }

    /*
     * Contracts topology / registry interface
     */

    function refreshContracts() external override {}
}
