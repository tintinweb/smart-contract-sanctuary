/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

contract FinaProxy {
    bytes32 private constant implementationPosition = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
    bytes32 private constant proxyOwnerPosition = keccak256("com.force.proxy.owner");

    event Upgraded(address indexed implementation);

    constructor() {
        _setUpgradeableOwner(msg.sender);
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    modifier onlyProxyOwner() {
        require(
            msg.sender == proxyOwner(),
            "FinaProxy: Only the proxy owner is permitted to do this action"
        );
        _;
    }

    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(
            newOwner != address(0),
            "FinaProxy: NewOwner cannot be the null address"
        );
        _setUpgradeableOwner(newOwner);
    }

    function _setUpgradeableOwner(address newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    function setImplementation(address newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, newImplementation)
        }
    }

    function upgradeTo(address impl) public onlyProxyOwner {
        require(impl != address(0));
        address currentImplementation = implementation();
        require(currentImplementation != impl);
        setImplementation(impl);
        emit Upgraded(impl);
    }

    fallback () external {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}