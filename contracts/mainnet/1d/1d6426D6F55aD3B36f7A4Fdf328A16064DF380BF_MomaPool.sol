pragma solidity 0.5.17;

import "./ErrorReporter.sol";
import "./MomaMasterStorage.sol";
import "./MomaFactoryInterface.sol";

/**
 * @title MomaMasterCore
 * @dev Storage for the MomaMaster is at this address, while execution is delegated to the `momaMasterImplementation`.
 * MTokens should reference this contract as their MomaMaster.
 */
contract MomaPool is MomaPoolAdminStorage, MomaMasterErrorReporter {

    /**
      * @notice Emitted when pendingMomaMasterImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingMomaMasterImplementation is accepted, which means momaMaster implementation is updated
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
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address admin_, address implementation_) external {
        require(msg.sender == factory && admin == address(0), 'MomaPool: FORBIDDEN'); // sufficient check
        require(implementation_ != address(0), 'MomaPool: ZERO FORBIDDEN');
        admin = admin_;
        momaMasterImplementation = implementation_;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {

        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        // Check is momaMaster
        require(MomaFactoryInterface(factory).isMomaMaster(newPendingImplementation) == true, 'MomaPool: NOT MOMAMASTER');

        address oldPendingImplementation = pendingMomaMasterImplementation;

        pendingMomaMasterImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingMomaMasterImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
    * @notice Accepts new implementation of momaMaster. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
    */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        if (msg.sender != pendingMomaMasterImplementation || pendingMomaMasterImplementation == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Check is momaMaster
        require(MomaFactoryInterface(factory).isMomaMaster(msg.sender) == true, 'MomaPool: NOT MOMAMASTER');

        // Save current values for inclusion in log
        address oldImplementation = momaMasterImplementation;
        address oldPendingImplementation = pendingMomaMasterImplementation;

        momaMasterImplementation = pendingMomaMasterImplementation;

        pendingMomaMasterImplementation = address(0);

        emit NewImplementation(oldImplementation, momaMasterImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingMomaMasterImplementation);

        return uint(Error.NO_ERROR);
    }


    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Check is timelock
        require(MomaFactoryInterface(factory).isTimelock(newPendingAdmin) == true, 'MomaPool: NOT TIMELOCK');

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Check is timelock
        require(MomaFactoryInterface(factory).isTimelock(msg.sender) == true, 'MomaPool: NOT TIMELOCK');

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function () payable external {
        // delegate all other functions to current implementation
        (bool success, ) = momaMasterImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }
}