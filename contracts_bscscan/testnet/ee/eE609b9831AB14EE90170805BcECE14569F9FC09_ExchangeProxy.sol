/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ExchangeProxy {
    bytes32 private constant implementationPosition =
        keccak256("implementation.contract.pestaking:2021");
    bytes32 private constant proxyOwnerPosition =
        keccak256("owner.contract.pestaking:2021");

    event Upgraded(address indexed implementation);
    event ProxyOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        setUpgradeabilityOwner(msg.sender);
    }

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
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

    function setImplementation(address newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, newImplementation)
        }
    }

    function _upgradeTo(address newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != newImplementation);
        setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function setUpgradeabilityOwner(address newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0));
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }
    
    function setAdmin(address /*_address*/, bool /*value*/) external onlyProxyOwner {
        _delegateCall();
    }
     
    function setSigner(address /*_address*/, bool /*_value*/) external onlyProxyOwner { 
       _delegateCall();
    }
    
    function setSignatureUtilsAddress(address /*_signatureUtils*/) external onlyProxyOwner {
       _delegateCall();
    }
    
    function setNftCollection(address /*_nftCollection*/) external onlyProxyOwner {
        _delegateCall();
    }
    
    function setRewardToken(address /*_rewardToken*/) external onlyProxyOwner {
        _delegateCall();
    }
    
    function initPool(address /*_signatureUtils*/, address /*_nftCollection*/, address /*_rewardToken*/) external onlyProxyOwner {
        _delegateCall();
    }
    
    function _delegateCall() internal {
        address _impl = implementation();
        require(_impl != address(0), "Impl address is 0");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(sub(gas(), 10000), _impl, ptr, calldatasize(), 0, 0)
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
        _delegateCall();
    }
}