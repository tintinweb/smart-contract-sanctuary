// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./Adminable.sol";
import "./DelegatorInterface.sol";


/**
  * @title OpenLevDelegator
  * @author OpenLeverage
  */
contract OpenLevDelegator is DelegatorInterface, Adminable {

    constructor(
        address _controller,
        address _dexAggregator,
        address[] memory _depositTokens,
        address _wETH,
        address _xOLE,
        uint8[] memory _supportDexs,
        address payable _admin,
        address implementation_){
        admin = msg.sender;
        // Creator of the contract is admin during initialization
        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation_, abi.encodeWithSignature("initialize(address,address,address[],address,address,uint8[])",
            _controller,
            _dexAggregator,
            _depositTokens,
            _wETH,
            _xOLE,
            _supportDexs
            ));
        implementation = implementation_;

        // Set the proper admin now that initialization is done
        admin = _admin;
    }

    /**
     * Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) public override onlyAdmin {
        address oldImplementation = implementation;
        implementation = implementation_;
        emit NewImplementation(oldImplementation, implementation);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


abstract contract DelegatorInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;

    /**
     * Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) public virtual;


    /**
    * Internal method to delegate execution to another contract
    * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    * @param callee The contract to delegatecall
    * @param data The raw data to delegatecall
    * @return The returned bytes from the delegatecall
    */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {revert(add(returnData, 0x20), returndatasize())}
        }
        return returnData;
    }

    /**
     * Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {revert(add(returnData, 0x20), returndatasize())}
        }
        return abi.decode(returnData, (bytes));
    }
    /**
    * Delegates execution to an implementation contract
    * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    */
    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        // delegate all other functions to current implementation
        if (msg.data.length > 0) {
            (bool success,) = implementation.delegatecall(msg.data);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize())
                switch success
                case 0 {revert(free_mem_ptr, returndatasize())}
                default {return (free_mem_ptr, returndatasize())}
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.7.6;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;
    address payable public developer;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);
    constructor () {
        developer = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller must be admin");
        _;
    }
    modifier onlyAdminOrDeveloper() {
        require(msg.sender == admin || msg.sender == developer, "caller must be admin or developer");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual {
        require(msg.sender == pendingAdmin, "only pendingAdmin can accept admin");
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

}