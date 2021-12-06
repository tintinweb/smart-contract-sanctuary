/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/// @title Ownable Contract
contract Ownable {
    // Storage slot with the admin of the contract.
    // This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
    // validated in the constructor.
    bytes32 private constant OWNER_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// Contract constructor
    /// @dev Sets msg sender address as owner address
    constructor() {
        setOwner(msg.sender);
    }

    /// Check that requires msg.sender to be the current owner
    modifier onlyOwner() {
        require(msg.sender == getOwner(), "55f1136901"); // 55f1136901 - sender must be owner
        _;
    }
    
    /// Returns contract owner address
    /// @return owner Owner address
    function getOwner() public view returns (address owner) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            owner := sload(slot)
        }
    }

    

    /// Sets new owner address
    /// @param newOwner New owner address
    function setOwner(address newOwner) internal {
        bytes32 slot = OWNER_SLOT;
        assembly {
            sstore(slot, newOwner)
        }
    }

    /// Transfers the control of the contract to new owner
    /// @dev msg.sender must be the current owner
    /// @param newOwner New owner address
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "f2fde38b01"); // f2fde38b01 - new owner cant be zero address
        setOwner(newOwner);
    }
}


// Upgradeable contract
contract Upgradeable is Ownable {
    // Storage slot with the address of the current implementation.
    // This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
    // validated in the constructor.
    bytes32 private constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;


    // Returns the current implementation contract address
    // return implementation - Implementaion contract address
    function getImplementation() public view returns (address implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            implementation := sload(slot)
        }
    }

    // Sets new implementation contract address as current
    // param newImplementation New implementation contract address
    function setImplementation(address newImplementation) external onlyOwner {
        require(newImplementation != address(0), "d784d42601"); // d784d42601 - new implementation must have non-zero address
        address currentImplementation = getImplementation();
        require(currentImplementation != newImplementation, "d784d42602"); // d784d42602 - new implementation must have new address
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
}


/// @title Upgradeable Proxy Contract
contract Proxy is Upgradeable {
    /// @notice Performs a delegatecall to the implementation contract.
    /// @dev Fallback function allows to perform a delegatecall to the given implementation.
    /// This function will return whatever the implementation call returns
    fallback() external {
        require(msg.data.length > 0, "9d96e2df01"); // 9d96e2df01 - calldata must not be empty
        address _impl = getImplementation();
        assembly {
            // The pointer to the free memory slot
            let ptr := mload(0x40)
            // Copy function signature and arguments from calldata at zero position into memory at pointer position
            calldatacopy(ptr, 0x0, calldatasize())
            // Delegatecall method of the implementation contract, returns 0 on error
            let result := delegatecall(
                gas(),
                _impl,
                ptr,
                calldatasize(),
                0x0,
                0
            )
            // Get the size of the last return data
            let size := returndatasize()
            // Copy the size length of bytes from return data at zero position to pointer position
            returndatacopy(ptr, 0x0, size)
            // Depending on result value
            switch result
            case 0 {
                // End execution and revert state changes
                revert(ptr, size)
            }
            default {
                // Return data with length of size at pointers position
                return(ptr, size)
            }
        }
    }
}