// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AccountImplementations {
    function getImplementation(bytes4 _sig) external view returns (address);
}

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`.
 */
contract InstaAccountV2 {

    AccountImplementations public immutable implementations;

    constructor(address _implementations) {
        implementations = AccountImplementations(_implementations);
    }

    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev Delegates the current call to the address returned by Implementations registry.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback(bytes4 _sig) internal {
        address _implementation = implementations.getImplementation(_sig);
        require(_implementation != address(0), "InstaAccountV2: Not able to find _implementation");
        _delegate(_implementation);
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by Implementations registry.
     */
    fallback () external payable {
        _fallback(msg.sig);
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by Implementations registry.
     */
    receive () external payable {
        if (msg.sig != 0x00000000) {
            _fallback(msg.sig);
        }
    }
}