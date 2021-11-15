// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
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
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
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
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

interface IClaim {
  function claim(uint256 tokenId) external;
}

contract LootProxy is Proxy {
  address immutable _impl;

  string private _name;
  string private _symbol;
  uint private _slot2;
  uint private _slot3;
  uint private _slot4;
  uint private _slot5;
  uint private _slot6;
  uint private _slot7;
  uint private _slot8;
  uint private _slot9;
  uint private _slot10;
  address private _owner;

  constructor(address impl) {
    _impl = impl;
    _name = "Loot ExplorerTH";
    _symbol = "LETH";
    _owner = msg.sender;
  }

  function contractURI() external pure returns (string memory) {
    return "https://ipfs.io/ipfs/QmQSkBuQ8g8tiMeZ3QEPHqFkGuF3GLqLWafhVMRtJvUvHy";
    // return "ipfs://QmQSkBuQ8g8tiMeZ3QEPHqFkGuF3GLqLWafhVMRtJvUvHy";
  }

  function _implementation() internal view override returns (address) {
    return _impl;
  }

  function claim(uint256 tokenId) external {
    IClaim(_impl).claim(tokenId);
  }
}

