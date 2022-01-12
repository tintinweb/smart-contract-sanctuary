/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// File: TestContracts/Proxy.sol

pragma solidity 0.8.7;

/// @dev Proxy for NFT Factory
contract Proxy {

    // Storage for this proxy
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
    bytes32 private constant ADMIN_SLOT          = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    constructor(address impl) {
        require(impl != address(0));

        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(impl))));
        _setSlotValue(ADMIN_SLOT, bytes32(uint256(uint160(msg.sender))));
    }

    function setImplementation(address newImpl) public {
        require(msg.sender == _getAddress(ADMIN_SLOT));
        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(newImpl))));
    }
    
    function implementation() public view returns (address impl) {
        impl = address(uint160(uint256(_getSlotValue(IMPLEMENTATION_SLOT))));
    }

    function _getAddress(bytes32 key) internal view returns (address add) {
        add = address(uint160(uint256(_getSlotValue(key))));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation__) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation__, 0, calldatasize(), 0, 0)

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
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _delegate(_getAddress(IMPLEMENTATION_SLOT));
    }

}