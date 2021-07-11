/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

// File: @openzeppelin/contracts/proxy/Proxy.sol
// SPDX-License-Identifier: GPL-3.0

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

// File: contracts/proxies/DelegateCallProxyOneToOne.sol


pragma solidity ^0.6.0;



/**
 * @dev Upgradeable delegatecall proxy for a single contract.
 *
 * This proxy stores an implementation address which can be upgraded by the proxy manager.
 *
 * To upgrade the implementation, the manager calls the proxy with the abi encoded implementation address.
 *
 * If any other account calls the proxy, it will delegatecall the implementation address with the received
 * calldata and ether. If the call succeeds, it will return with the received returndata.
 * If it reverts, it will revert with the received revert data.
 *
 * Note: The storage slot for the implementation address is:
 * `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`
 * This slot must not be used by the implementation contract.
 *
 * Note: This contract does not verify that the implementation address is a valid delegation target.
 * The manager must perform this safety check.
 */
contract DelegateCallProxyOneToOne is Proxy {
/* ==========  Constants  ========== */
  address internal immutable _manager;

/* ==========  Constructor  ========== */
  constructor() public {
    _manager = msg.sender ;
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Reads the implementation address from storage.
   */
  function _implementation() internal override view returns (address) {
    address implementation;
    assembly {
      implementation := sload(
        // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
        0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a
      )
    }
    return implementation;
  }

  /**
    * @dev Hook that is called before falling back to the implementation.
    *
    * Checks if the call is from the owner.
    * If it is, reads the abi-encoded implementation address from calldata and stores
    * it at the slot `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`,
    * then returns with no data.
    * If it is not, continues execution with the fallback function.
    */
  function _beforeFallback() internal override {
    if (msg.sender != _manager) {
      super._beforeFallback();
    } else {
      assembly {
        sstore(
          // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
          0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a,
          calldataload(0)
        )
        return(0, 0)
      }
    }
  }
}