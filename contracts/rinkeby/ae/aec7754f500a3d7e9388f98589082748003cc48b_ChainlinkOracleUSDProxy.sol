/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: CC0-1.0

// File: contracts/Proxy.sol


// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

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

// File: contracts/ChainlinkOracleUSDProxy.sol


pragma solidity 0.8.7;


enum ModuleType { Version, Controller, Strategy, MintMaster, Oracle }

/**
 * @title ChainlinkOracleUSDProxy
 * @dev Initialize and deploy a EIP-1167 minimal proxy for the ICHI ChainlinkOracleUSD contract
 */
contract ChainlinkOracleUSDProxy is Proxy {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ModuleDeployed(address sender, ModuleType moduleType, string description);
    event OracleDeployed(address sender, string description, address indexToken);
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address internal immutable _target;

    // Canonical mainnet deployment parameters:
    // "0xa5DEc9155960C278773BAE4aef071379Ca0a890B","0xC1bDb21402707941515765d1E033c94094c65FB4","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    // target: 0xa5DEc9155960C278773BAE4aef071379Ca0a890B
    // owner: 0xC1bDb21402707941515765d1E033c94094c65FB4
    // indexToken: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    // description is hardcoded to "Chainlink Oracle USD" for implementation convenience
    constructor(address target, address owner, address indexToken) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)); 
        _target = target;

        // ChainlinkOracleUSD initialization
        bytes32 ownerBytes = bytes32(uint256(uint160(owner)));
        bytes32 indexTokenBytes = bytes32(uint256(uint160(indexToken)));
        assembly {
            // Initialize storage slots set by the ChainlinkOracleUSD constructor
            sstore(0x0000000000000000000000000000000000000000000000000000000000000000, ownerBytes)
            sstore(0x0000000000000000000000000000000000000000000000000000000000000001, 0x436861696e6c696e6b204f7261636c6520555344000000000000000000000028)
            sstore(0x0000000000000000000000000000000000000000000000000000000000000002, indexTokenBytes)
        }
        emit OwnershipTransferred(address(0), owner);
        emit ModuleDeployed(msg.sender, ModuleType.Oracle, "Chainlink Oracle USD");
        emit OracleDeployed(msg.sender, "Chainlink Oracle USD", indexToken);

        // EIP-1967 proxy metadata initialization
        bytes32 targetBytes = bytes32(uint256(uint160(target)));
        assembly {
            sstore(_IMPLEMENTATION_SLOT, targetBytes)
        }
        emit Upgraded(target);
    }

    function _implementation() internal view virtual override returns (address) {
        return _target;
    }
}