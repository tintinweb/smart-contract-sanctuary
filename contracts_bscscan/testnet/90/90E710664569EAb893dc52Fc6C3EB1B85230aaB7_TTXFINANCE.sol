/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TTXFINANCE {
    bytes32 private constant implementationPosition =
        keccak256("implementation.contract.ttx:2021");
    bytes32 private constant proxyOwnerPosition =
        keccak256("owner.contract.ttx:2021");

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
        require(msg.sender == proxyOwner(), "Only proxy owner call execute this function");
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
        require(_newOwner != address(0), "New owner address must not be zero address");
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

    function upgradeTo(address _newImplementation) public onlyProxyOwner {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation, "New implementation address must not be the same as old implementation address");
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
    
    function setAdmin(address /*_address*/, bool /*value*/) external onlyProxyOwner {
        _delegatecall();
    }
     
    function emercencyWithdrawToken(string memory /*_poolId*/, address /*_account*/) external onlyProxyOwner {
        _delegatecall();
    }
    
    function withdrawFund(address /*_tokenAddress*/, address /*_account*/, uint256 /*_amount*/) external onlyProxyOwner {
        _delegatecall();
    }

    function transferController(address /*_newController*/) external onlyProxyOwner {
        _delegatecall();
    }
    
    function _delegatecall() internal {
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
        _delegatecall();
    }
}