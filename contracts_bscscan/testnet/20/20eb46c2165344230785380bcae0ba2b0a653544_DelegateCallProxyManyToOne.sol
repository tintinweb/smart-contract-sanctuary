/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// File: @openzeppelin/contracts/proxy/Proxy.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/proxies/DelegateCallProxyManyToOne.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;



/**
 * @dev Proxy contract which uses an implementation address shared with many
 * other proxies.
 *
 * An implementation holder contract stores the upgradeable implementation address.
 * When the proxy is called, it queries the implementation address from the holder
 * contract and delegatecalls the returned address, forwarding the received calldata
 * and ether.
 *
 * Note: This contract does not verify that the implementation
 * address is a valid delegation target. The manager must perform
 * this safety check before updating the implementation on the holder.
 */
contract DelegateCallProxyManyToOne is Proxy {
/* ==========  Constants  ========== */

  // Address that stores the implementation address.
  address internal immutable _implementationHolder;

/* ==========  Constructor  ========== */

  constructor() public {
    // Calls the sender rather than receiving the address in the constructor
    // arguments so that the address is computable using create2.
    _implementationHolder = ProxyDeployer(msg.sender).getImplementationHolder();
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Queries the implementation address from the implementation holder.
   */
  function _implementation() internal override view returns (address) {
    // Queries the implementation address from the implementation holder.
    (bool success, bytes memory data) = _implementationHolder.staticcall("");
    require(success, string(data));
    address implementation = abi.decode((data), (address));
    require(implementation != address(0), "ERR_NULL_IMPLEMENTATION");
    return implementation;
  }
}

interface ProxyDeployer {
  function getImplementationHolder() external view returns (address);
}