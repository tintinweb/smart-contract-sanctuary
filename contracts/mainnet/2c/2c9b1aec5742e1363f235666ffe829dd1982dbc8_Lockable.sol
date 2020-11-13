// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./ContractRegistryAccessor.sol";
import "./ILockable.sol";

contract Lockable is ILockable, ContractRegistryAccessor {

    bool public locked;

    constructor(IContractRegistry _contractRegistry, address _registryAdmin) ContractRegistryAccessor(_contractRegistry, _registryAdmin) public {}

    modifier onlyLockOwner() {
        require(msg.sender == registryAdmin() || msg.sender == address(getContractRegistry()), "caller is not a lock owner");

        _;
    }

    function lock() external override onlyLockOwner {
        locked = true;
        emit Locked();
    }

    function unlock() external override onlyLockOwner {
        locked = false;
        emit Unlocked();
    }

    function isLocked() external override view returns (bool) {
        return locked;
    }

    modifier onlyWhenActive() {
        require(!locked, "contract is locked for this operation");

        _;
    }
}
