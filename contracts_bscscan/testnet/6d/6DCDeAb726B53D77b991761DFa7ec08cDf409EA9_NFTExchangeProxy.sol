/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTExchangeProxy {

    bytes32 private constant implementationPosition = keccak256("implementation.contract:2021");
    bytes32 private constant proxyOwnerPosition = keccak256("owner.contract:2021");

    event Upgraded(address indexed implementation);
    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        setUpgradabilityOwner(msg.sender);
    }

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    // To get the address of the proxy contract's owner
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)    // load the data in position from the storage
        }
    }

    // To get the address of the proxy contract
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)     // load the data in position from storage
        }
    }

    function setImplementation(address _impl) internal {
        bytes32 position = implementationPosition;  // get the current position of the proxy contract stored
        assembly {
            sstore(position, _impl)     // store the data _impl into the position
        }
    }

    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation, "NFTExchangeProxy: Upgrade the current proxy contract");
        setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }

    // To upgrade the logic contract to new one
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    // To set new proxy contract's owner
    function setUpgradabilityOwner(address _newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    // To transfer proxy ownership to new owner
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0), "NFTExchangeProxy: Transfer proxy ownership to zero address");
        require(_newOwner != proxyOwner(), "NFTExchangeProxy: Transfer proxy ownership to current owner");

        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
        setUpgradabilityOwner(_newOwner);
    }

    fallback() external payable {
        address _impl = implementation();
        require(_impl != address(0), "NFTExchangeProxy: Not set the implementation yet");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            
            default {
                return(ptr, size)
            }
        }
    }

    function setAdmin(
        address, 
        bool
    ) public onlyProxyOwner {
        address _impl = implementation();
        require(_impl != address(0), "NFTExchangeProxy: Implementation is zero address");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}