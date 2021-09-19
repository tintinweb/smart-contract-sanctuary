/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;


/// @title Ownable Contract
contract Ownable {
    /// @notice Storage position of the owner address
    /// @dev The address of the current owner is stored in a
    /// constant pseudorandom slot of the contract storage
    /// (slot number obtained as a result of hashing a certain message),
    /// the probability of rewriting which is almost zero
    bytes32 private constant OWNER_POSITION = keccak256("owner");

    /// @notice Contract constructor
    /// @dev Sets msg sender address as owner address
    constructor() {
        setOwner(msg.sender);
    }

    /// @notice Returns contract owner address
    /// @return owner Owner address
    function getOwner() public view returns (address owner) {
        bytes32 position = OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /// @notice Check that requires msg.sender to be the current owner
    modifier onlyOwner() {
        require(msg.sender == getOwner(), "55f1136901"); // 55f1136901 - sender must be owner
        _;
    }

    /// @notice Sets new owner address
    /// @param _newOwner New owner address
    function setOwner(address _newOwner) internal {
        bytes32 position = OWNER_POSITION;
        assembly {
            sstore(position, _newOwner)
        }
    }

    /// @notice Transfers the control of the contract to new owner
    /// @dev msg.sender must be the current owner
    /// @param _newOwner New owner address
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "f2fde38b01"); // f2fde38b01 - new owner cant be zero address
        setOwner(_newOwner);
    }
}

/// @title Upgradeable contract
contract Upgradeable is Ownable {
    /// @notice Storage position of the current implementation address.
    /// @dev The address of the current implementation is stored in a
    /// constant pseudorandom slot of the contract proxy contract storage
    /// (slot number obtained as a result of hashing a certain message),
    /// the probability of rewriting which is almost zero
    bytes32 private constant IMPLEMENTAION_POSITION = keccak256(
        "implementation"
    );

    /// @notice Returns the current implementation contract address
    /// @return implementation - Implementaion contract address
    function getImplementation() public view returns (address implementation) {
        bytes32 position = IMPLEMENTAION_POSITION;
        assembly {
            implementation := sload(position)
        }
    }

    /// @notice Sets new implementation contract address as current
    /// @param _newImplementation New implementation contract address
    function setImplementation(address _newImplementation) public onlyOwner {
        require(_newImplementation != address(0), "d784d42601"); // d784d42601 - new implementation must have non-zero address
        address currentImplementation = getImplementation();
        require(currentImplementation != _newImplementation, "d784d42602"); // d784d42602 - new implementation must have new address
        bytes32 position = IMPLEMENTAION_POSITION;
        assembly {
            sstore(position, _newImplementation)
        }
    }
}

/// @title Upgradeable Proxy Contract
contract Proxy is Upgradeable {
    /// @notice Performs a delegatecall to the implementation contract.
    /// @dev Fallback function allows to perform a delegatecall to the given implementation.
    /// This function will return whatever the implementation call returns
    fallback() external payable {
        require(msg.data.length > 0, "9d96e2df01"); // 9d96e2df01 - calldata must not be empty
        address _impl = getImplementation();
        assembly {
            // The pointer to the free memory slot
            let ptr := mload(0x40)
            // Copy function signature and arguments from calldata at zero position into memory at pointer position
            calldatacopy(ptr, 0x0, calldatasize())
            // Delegatecall method of the implementation contract, returns 0 on error
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0x0, 0)
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