pragma solidity 0.5.17;

import "./MomaFactoryStorage.sol";
/**
 * @title MomaFactoryProxy
 * @dev Storage for the MomaFactory is at this address, while execution is delegated to the `momaFactoryImplementation`.
 */

contract MomaFactoryProxy is MomaFactoryProxyStorage {

    /**
      * @notice Emitted when pendingMomaFactoryImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingMomaFactoryImplementation is accepted, which means momaFactory implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when pendingAdmin is changed
      */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        // Set admin to caller
        admin = msg.sender;
        feeAdmin = msg.sender;
        defualtFeeReceiver = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public {

        require(msg.sender == admin, 'MomaFactory: admin check');

        address oldPendingImplementation = pendingMomaFactoryImplementation;

        pendingMomaFactoryImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingMomaFactoryImplementation);
    }

    /**
    * @notice Accepts new implementation of momaFactory. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == pendingMomaFactoryImplementation && msg.sender != address(0), 'MomaFactory: pendingImplementation check');

        // Save current values for inclusion in log
        address oldImplementation = momaFactoryImplementation;
        address oldPendingImplementation = pendingMomaFactoryImplementation;

        momaFactoryImplementation = pendingMomaFactoryImplementation;

        pendingMomaFactoryImplementation = address(0);

        emit NewImplementation(oldImplementation, momaFactoryImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingMomaFactoryImplementation);

        return 0;
    }


    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) public {
        // Check caller = admin
        require(msg.sender == admin, 'MomaFactory: admin check');

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() public {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), 'MomaFactory: pendingAdmin check');

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function () payable external {
        // delegate all other functions to current implementation
        (bool success, ) = momaFactoryImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }
}