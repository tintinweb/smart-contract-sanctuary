/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

pragma solidity ^0.5.16;

/**
 * @title Comptroller
 * @notice Built solely to toggle admin rights on old Unitrollers.
 */
contract Comptroller {
    /**
     * @notice Administrator for Fuse
     */
    address internal constant fuseAdmin = 0xa731585ab05fC9f83555cf9Bff8F58ee94e18F85;

    /**
    * @notice Administrator for this contract
    */
    address internal admin;

    /**
    * @notice Pending administrator for this contract
    */
    address internal pendingAdmin;

    /**
     * @notice Whether or not the Fuse admin has admin rights
     */
    bool internal fuseAdminHasRights;

    /**
     * @notice Whether or not the admin has admin rights
     */
    bool internal adminHasRights;

    /**
      * @notice Event emitted when the admin rights are changed
      */
    event AdminRightsToggled(bool hasRights);

    /**
      * @notice Toggles admin rights.
      * @param hasRights Boolean indicating if the admin is to have rights.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _toggleAdminRights(bool hasRights) external returns (uint) {
        // Check sender is Fuse admin
        require(msg.sender == fuseAdmin, "Sender not Fuse admin.");

        // Check that rights have not already been set to the desired value
        if (adminHasRights == hasRights) return 0;

        // Set adminHasRights
        adminHasRights = hasRights;

        // Emit AdminRightsToggled()
        emit AdminRightsToggled(hasRights);

        // Return no error
        return 0;
    }
}