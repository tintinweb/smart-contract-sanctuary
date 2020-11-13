// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "./Ownable.sol";


/**
* @notice Base contract for upgradeable contract
* @dev Inherited contract should implement verifyState(address) method by checking storage variables
* (see verifyState(address) in Dispatcher). Also contract should implement finishUpgrade(address)
* if it is using constructor parameters by coping this parameters to the dispatcher storage
*/
abstract contract Upgradeable is Ownable {

    event StateVerified(address indexed testTarget, address sender);
    event UpgradeFinished(address indexed target, address sender);

    /**
    * @dev Contracts at the target must reserve the same location in storage for this address as in Dispatcher
    * Stored data actually lives in the Dispatcher
    * However the storage layout is specified here in the implementing contracts
    */
    address public target;

    /**
    * @dev Previous contract address (if available). Used for rollback
    */
    address public previousTarget;

    /**
    * @dev Upgrade status. Explicit `uint8` type is used instead of `bool` to save gas by excluding 0 value
    */
    uint8 public isUpgrade;

    /**
    * @dev Guarantees that next slot will be separated from the previous
    */
    uint256 stubSlot;

    /**
    * @dev Constants for `isUpgrade` field
    */
    uint8 constant UPGRADE_FALSE = 1;
    uint8 constant UPGRADE_TRUE = 2;

    /**
    * @dev Checks that function executed while upgrading
    * Recommended to add to `verifyState` and `finishUpgrade` methods
    */
    modifier onlyWhileUpgrading()
    {
        require(isUpgrade == UPGRADE_TRUE);
        _;
    }

    /**
    * @dev Method for verifying storage state.
    * Should check that new target contract returns right storage value
    */
    function verifyState(address _testTarget) public virtual onlyWhileUpgrading {
        emit StateVerified(_testTarget, msg.sender);
    }

    /**
    * @dev Copy values from the new target to the current storage
    * @param _target New target contract address
    */
    function finishUpgrade(address _target) public virtual onlyWhileUpgrading {
        emit UpgradeFinished(_target, msg.sender);
    }

    /**
    * @dev Base method to get data
    * @param _target Target to call
    * @param _selector Method selector
    * @param _numberOfArguments Number of used arguments
    * @param _argument1 First method argument
    * @param _argument2 Second method argument
    * @return memoryAddress Address in memory where the data is located
    */
    function delegateGetData(
        address _target,
        bytes4 _selector,
        uint8 _numberOfArguments,
        bytes32 _argument1,
        bytes32 _argument2
    )
        internal returns (bytes32 memoryAddress)
    {
        assembly {
            memoryAddress := mload(0x40)
            mstore(memoryAddress, _selector)
            if gt(_numberOfArguments, 0) {
                mstore(add(memoryAddress, 0x04), _argument1)
            }
            if gt(_numberOfArguments, 1) {
                mstore(add(memoryAddress, 0x24), _argument2)
            }
            switch delegatecall(gas(), _target, memoryAddress, add(0x04, mul(0x20, _numberOfArguments)), 0, 0)
                case 0 {
                    revert(memoryAddress, 0)
                }
                default {
                    returndatacopy(memoryAddress, 0x0, returndatasize())
                }
        }
    }

    /**
    * @dev Call "getter" without parameters.
    * Result should not exceed 32 bytes
    */
    function delegateGet(address _target, bytes4 _selector)
        internal returns (uint256 result)
    {
        bytes32 memoryAddress = delegateGetData(_target, _selector, 0, 0, 0);
        assembly {
            result := mload(memoryAddress)
        }
    }

    /**
    * @dev Call "getter" with one parameter.
    * Result should not exceed 32 bytes
    */
    function delegateGet(address _target, bytes4 _selector, bytes32 _argument)
        internal returns (uint256 result)
    {
        bytes32 memoryAddress = delegateGetData(_target, _selector, 1, _argument, 0);
        assembly {
            result := mload(memoryAddress)
        }
    }

    /**
    * @dev Call "getter" with two parameters.
    * Result should not exceed 32 bytes
    */
    function delegateGet(
        address _target,
        bytes4 _selector,
        bytes32 _argument1,
        bytes32 _argument2
    )
        internal returns (uint256 result)
    {
        bytes32 memoryAddress = delegateGetData(_target, _selector, 2, _argument1, _argument2);
        assembly {
            result := mload(memoryAddress)
        }
    }
}
