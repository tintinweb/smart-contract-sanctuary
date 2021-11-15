// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/PrismProxy.sol";

/**
 * @title VotingPowerPrism
 * @dev Storage for voting power is at this address, while execution is delegated to the prism proxy implementation contract
 * All contracts that use voting power should reference this contract.
 */
contract VotingPowerPrism is PrismProxy {

    /**
     * @notice Construct a new Voting Power Prism Proxy
     * @dev Sets initial proxy admin to `msg.sender`
     */
    constructor() {
        // Initialize storage
        ProxyStorage storage s = proxyStorage();
        // Set initial proxy admin
        s.admin = msg.sender;
    }

    /**
     * @notice Forwards call to implementation contract
     */
    receive() external payable {
        _forwardToImplementation();
    }

    /**
     * @notice Forwards call to implementation contract
     */
    fallback() external payable {
        _forwardToImplementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PrismProxy {

    /// @notice Proxy admin and implementation storage variables
    struct ProxyStorage {
        // Administrator for this contract
        address admin;

        // Pending administrator for this contract
        address pendingAdmin;

        // Active implementation of this contract
        address implementation;

        // Pending implementation of this contract
        address pendingImplementation;

        // Implementation version of this contract
        uint8 version;
    }

    /// @dev Position in contract storage where prism ProxyStorage struct will be stored
    bytes32 constant PRISM_PROXY_STORAGE_POSITION = keccak256("prism.proxy.storage");

    /// @notice Emitted when pendingImplementation is changed
    event NewPendingImplementation(address indexed oldPendingImplementation, address indexed newPendingImplementation);

    /// @notice Emitted when pendingImplementation is accepted, which means implementation is updated
    event NewImplementation(address indexed oldImplementation, address indexed newImplementation);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address indexed oldPendingAdmin, address indexed newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);

    /**
     * @notice Load proxy storage struct from specified PRISM_PROXY_STORAGE_POSITION
     * @return ps ProxyStorage struct
     */
    function proxyStorage() internal pure returns (ProxyStorage storage ps) {        
        bytes32 position = PRISM_PROXY_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    /*** Admin Functions ***/
    
    /**
     * @notice Create new pending implementation for prism. msg.sender must be admin
     * @dev Admin function for proposing new implementation contract
     * @return boolean indicating success of operation
     */
    function setPendingProxyImplementation(address newPendingImplementation) public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        require(msg.sender == s.admin, "Prism::setPendingProxyImp: caller must be admin");

        address oldPendingImplementation = s.pendingImplementation;

        s.pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, s.pendingImplementation);

        return true;
    }

    /**
     * @notice Accepts new implementation for prism. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     * @return boolean indicating success of operation
     */
    function acceptProxyImplementation() public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == s.pendingImplementation && s.pendingImplementation != address(0), "Prism::acceptProxyImp: caller must be pending implementation");
 
        // Save current values for inclusion in log
        address oldImplementation = s.implementation;
        address oldPendingImplementation = s.pendingImplementation;

        s.implementation = s.pendingImplementation;

        s.pendingImplementation = address(0);
        s.version++;

        emit NewImplementation(oldImplementation, s.implementation);
        emit NewPendingImplementation(oldPendingImplementation, s.pendingImplementation);

        return true;
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return boolean indicating success of operation
     */
    function setPendingProxyAdmin(address newPendingAdmin) public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        // Check caller = admin
        require(msg.sender == s.admin, "Prism::setPendingProxyAdmin: caller must be admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = s.pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        s.pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return true;
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return boolean indicating success of operation
     */
    function acceptProxyAdmin() public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == s.pendingAdmin && msg.sender != address(0), "Prism::acceptProxyAdmin: caller must be pending admin");

        // Save current values for inclusion in log
        address oldAdmin = s.admin;
        address oldPendingAdmin = s.pendingAdmin;

        // Store admin with value pendingAdmin
        s.admin = s.pendingAdmin;

        // Clear the pending value
        s.pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, s.admin);
        emit NewPendingAdmin(oldPendingAdmin, s.pendingAdmin);

        return true;
    }

    /**
     * @notice Get current admin for prism proxy
     * @return admin address
     */
    function proxyAdmin() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.admin;
    }

    /**
     * @notice Get pending admin for prism proxy
     * @return admin address
     */
    function pendingProxyAdmin() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.pendingAdmin;
    }

    /**
     * @notice Address of implementation contract
     * @return implementation address
     */
    function proxyImplementation() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.implementation;
    }

    /**
     * @notice Address of pending implementation contract
     * @return pending implementation address
     */
    function pendingProxyImplementation() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.pendingImplementation;
    }

    /**
     * @notice Current implementation version for proxy
     * @return version number
     */
    function proxyImplementationVersion() public view returns (uint8) {
        ProxyStorage storage s = proxyStorage();
        return s.version;
    }

    /**
     * @notice Delegates execution to an implementation contract.
     * @dev Returns to the external caller whatever the implementation returns or forwards reverts
     */
    function _forwardToImplementation() internal {
        ProxyStorage storage s = proxyStorage();
        // delegate all other functions to current implementation
        (bool success, ) = s.implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }
}

