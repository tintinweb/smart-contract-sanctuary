pragma solidity ^0.5.16;

import "./RegistryStorage.sol";

/**
 * @title RegistryCore
 * @dev Storage for the Registry is at this address, while execution is delegated to the `implementation`.
 * OTokens and Unitrollers should reference this contract as their Registry.
 */
contract Ministry is UnistryAdminStorage {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingImplementation is accepted, which means Registry implementation is updated
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

    constructor(bool _blocksBased) public {
        // Set admin to caller
        admin = msg.sender;

        // Set the calculation base for this blockchain contracts
        blocksBased = _blocksBased;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {

        require(msg.sender == admin, "Not Admin");

        address oldPendingImplementation = pendingImplementation;

        pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);

//        return uint(Error.NO_ERROR);
        return 0;
    }

    /**
    * @notice Accepts new implementation of Registry. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
    */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == pendingImplementation && pendingImplementation != address(0), "Not the EXISTING registry implementation");

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingImplementation;

        implementation = pendingImplementation;

        pendingImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);

        return 0;
    }


    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        require(msg.sender == admin, "Not Admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

//        return uint(Error.NO_ERROR);
        return 0;
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && pendingAdmin != address(0), "Not the EXISTING pending admin");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

//        return uint(Error.NO_ERROR);
        return 0;
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function () payable external {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }
}

pragma solidity ^0.5.16;

contract UnistryAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Ministry
    */
    address public implementation;

    /**
    * @notice Pending brains of Ministry
    */
    address public pendingImplementation;

    // Indicates if calculations should be block based or time based
    bool public blocksBased;
}

contract RegistryV0Storage is UnistryAdminStorage {
    // The address to send the 'Ola Part' when reducing reserves.
    address public olaBankAddress;

    // Part of reserves that are allocated to Ola (Deprecated)
    uint256 public olaReservesFactorMantissa;

    // Asset address -> Price oracle address
    mapping(address => address) public priceOracles;

    // The latest system version
    uint256 public latestSystemVersion;

    // Unitroller address -> System version (MAX_INT means always take latest)
    mapping(address => uint256) public lnVersions;

    // System version -> (contract name hash -> implementation)
    mapping(uint256 => mapping(bytes32 => address)) public implementations;

    // System versions => isSupported
    mapping(uint256 => bool) public supportedSystemVersions;

    // Interest rate model address => isSupported
    mapping(address => bool) public supportedInterestRateModels;
}

contract RegistryV1Storage is RegistryV0Storage {
    // System version -> OTokens Factory
    mapping(uint256 => address) public tokenFactories;

    // Contract name hash => Contract factory
    mapping(bytes32 => address) public peripheralFactories;
}