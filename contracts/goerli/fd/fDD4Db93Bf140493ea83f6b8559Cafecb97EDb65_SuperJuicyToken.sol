/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// File: @openzeppelin/contracts/proxy/Proxy.sol


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

// File: contracts/UUPSProxy.sol


pragma solidity ^0.8.0;


contract UUPSProxy is Proxy {
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    function initializeProxy(address initialAddress) external {
        require(initialAddress != address(0), "UUPSProxy: zero address");
        require(_implementation() == address(0), "UUPS: already initialized");
        assembly {
            sstore(_IMPLEMENTATION_SLOT, initialAddress)
        }
    }

    function _implementation() internal virtual override view returns (address impl) {
        assembly {
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }
}

// File: contracts/SuperTokenBase.sol


pragma solidity ^0.8.0;

abstract contract SuperTokenBase {
    // This reserves state slots written to by the logic contract
    uint256[32] internal _storagePaddings;
}

// File: contracts/Token.sol


pragma solidity ^0.8.0;



contract SuperJuicyToken is SuperTokenBase, UUPSProxy {
    address internal _deployer;
    function initialize(string calldata name, string calldata symbol, uint256 initialSupply) external {
        _deployer = msg.sender;
        bool success;
        (success, ) = address(this).call(
            abi.encodeWithSignature(
                "initialize(address,uint8,string,string)",
                address(0),
                18,
                name,
                symbol
            )
        );
        require(success);
        (success, ) = address(this).call(
            abi.encodeWithSignature(
                "selfMint(address,uint256,bytes)",
                msg.sender,
                initialSupply,
                new bytes(0)
            )
        );
        require(success);
    }

    function whoDeployedMe() public view returns (address deployer) {
        return _deployer;
    }
}