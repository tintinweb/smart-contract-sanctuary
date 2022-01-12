/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Proxy {
    bytes32 private constant implementationPosition =
        keccak256("implementation.contract:2022");
    bytes32 private constant proxyOwnerPosition =
        keccak256("owner.contract:2022");

    event Upgraded(address indexed implementation);
    event ProxyOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address _impl) {
        _setUpgradeabilityOwner(msg.sender);
        _setImplementation(_impl);
    }

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "Proxy: Caller not proxy owner");
        _;
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0), "Proxy: new owner is address zero");
        require(_newOwner != proxyOwner(), "Proxy: new owner is the current owner");
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

    function upgradeTo(address _newImplementation) public onlyProxyOwner {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation, "Proxy: new implementation is the current implementation");
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }

    function _setImplementation(address _newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    function pause() external onlyProxyOwner {
        _delegatecall();
    }

    function unpause() external onlyProxyOwner {
        _delegatecall();
    }

    function finishMinting() external onlyProxyOwner returns (bool) {
        _delegatecall();
    }

    function finishBurning() external onlyProxyOwner returns (bool) {
        _delegatecall();
    }

    function transferOwnership(address /*_account */) external onlyProxyOwner{
        _delegatecall();
    }

    function grantRole(
        bytes32 /*role*/, 
        address /*_account*/
    ) external onlyProxyOwner {
        _delegatecall();
    }

    function _delegatecall() internal {
        address _impl = implementation();
        require(_impl != address(0), "Impl address is 0");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                _impl,
                ptr,
                calldatasize(),
                0,
                0
            )
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

    fallback() external payable {
        _delegatecall();
    }
}