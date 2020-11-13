pragma solidity ^0.6.0;

import "../oracle/implementation/Finder.sol";
import "../oracle/implementation/Constants.sol";
import "../oracle/implementation/Voting.sol";


/**
 * @title A contract to track a whitelist of addresses.
 */
contract Umip15Upgrader {
    // Existing governor is the only one who can initiate the upgrade.
    address public governor;

    // Existing Voting contract needs to be informed of the address of the new Voting contract.
    Voting public existingVoting;

    // New governor will be the new owner of the finder.

    // Finder contract to push upgrades to.
    Finder public finder;

    // Addresses to upgrade.
    address public newVoting;

    constructor(
        address _governor,
        address _existingVoting,
        address _newVoting,
        address _finder
    ) public {
        governor = _governor;
        existingVoting = Voting(_existingVoting);
        newVoting = _newVoting;
        finder = Finder(_finder);
    }

    function upgrade() external {
        require(msg.sender == governor, "Upgrade can only be initiated by the existing governor.");

        // Change the addresses in the Finder.
        finder.changeImplementationAddress(OracleInterfaces.Oracle, newVoting);
        // Set current Voting contract to migrated.
        existingVoting.setMigrated(newVoting);

        // Transfer back ownership of old voting contract and the finder to the governor.
        existingVoting.transferOwnership(governor);
        finder.transferOwnership(governor);
    }
}
