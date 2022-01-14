/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// hevm: flattened sources of src/util/ForwardProxy.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-or-later
pragma solidity >=0.6.0 <0.8.0 >=0.6.12 <0.7.0;

////// lib/openzeppelin-contracts/contracts/proxy/Proxy.sol

/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

////// src/util/ForwardProxy.sol
/* pragma solidity ^0.6.12; */

/* import {Proxy} from "openzeppelin-contracts/proxy/Proxy.sol"; */

/**
 * @dev This contract provides a fallback function that forwards all calls to another contract using the EVM
 * instruction `call`.
 *
 * Additionally, delegation to the implementation can be triggered manually through the `_fallback` function, or to a
 * different contract through the `_delegate` function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
contract ForwardProxy is Proxy {
    address internal forwardTo;

    /**
     * @param forwardTo_ The contract to which the call is going to be forwarded to.
     */
    constructor(address forwardTo_) public {
        forwardTo = forwardTo_;
    }

    /**
     * @notice Updates the `forwardTo` address.
     * @param forwardTo_ The contract to which the call is going to be forwarded to.
     */
    function updateForwardTo(address forwardTo_) public {
        forwardTo = forwardTo_;
    }

    /**
     * @notice Delegates the current call to `implementation`.
     * @dev This function does not return to its internall call site, it will return directly to the external caller.
     * @param implementation The address of the implementation contract.
     */
    function _delegate(address implementation) internal virtual override {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            // let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            let result := call(gas(), implementation, 0, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // call returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function and {_fallback} should delegate.
     * @return forwardTo The address of the implementation contract.
     */
    function _implementation() internal view virtual override returns (address) {
        return forwardTo;
    }
}