// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "./utilities/UnstructuredStorageWithTimelock.sol";
import "./interface/IStorageV1.sol";

/**
    TimelockProxyStorageCentered is a proxy implementation that timelocks the implementation switch.
    The owner is stored in the system storage (StorageV1Upgradeable) and not in the contract storage
    of the proxy.
*/
contract TimelockProxyStorageCentered is Proxy {
    using UnstructuredStorageWithTimelock for bytes32;

    // bytes32(uint256(keccak256("eip1967.proxy.systemStorage")) - 1
    bytes32 private constant _SYSTEM_STORAGE_SLOT =
        0xf7ce9e33978bd6e766998cbee51134930bc6e39dc5dcd8f992c5b743b1c6d698;

    // bytes32(uint256(keccak256("eip1967.proxy.timelock")) - 1
    bytes32 private constant _TIMELOCK_SLOT =
        0xc6fb23975d74c7743b6d6d0c1ad9dc3911bc8a4a970ec5723a30579b45472009;

    // _IMPLEMENTATION_SLOT, value cloned from UpgradeableProxy
    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event UpgradeScheduled(address indexed implementation, uint256 activeTime);
    event Upgraded(address indexed implementation);

    event TimelockUpdateScheduled(uint256 newTimelock, uint256 activeTime);
    event TimelockUpdated(uint256 newTimelock);

    constructor(
        address _logic,
        address _storage,
        uint256 _timelock,
        bytes memory _data
    ) {
        assert(
            _SYSTEM_STORAGE_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.systemStorage")) - 1)
        );
        assert(
            _TIMELOCK_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.timelock")) - 1)
        );
        assert(
            _IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        _SYSTEM_STORAGE_SLOT.setAddress(_storage);
        _TIMELOCK_SLOT.setUint256(_timelock);
        _IMPLEMENTATION_SLOT.setAddress(_logic);
        if (_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }

    // Using Transparent proxy pattern to avoid collision attacks
    // see OpenZeppelin's `TransparentUpgradeableProxy`
    modifier adminPriviledged() {
        require(
            msg.sender == IStorageV1(_systemStorage()).governance() ||
            IStorageV1(_systemStorage()).isAdmin(msg.sender), 
            "msg.sender is not adminPriviledged"
        );
        _;
    }

    modifier requireTimelockPassed(bytes32 _slot) {
        require(
            block.timestamp >= _slot.scheduledTime(),
            "Timelock has not passed yet"
        );
        _;
    }

    function proxyScheduleImplementationUpdate(address targetAddress)
        public
        adminPriviledged
    {
        bytes32 _slot = _IMPLEMENTATION_SLOT;
        uint256 activeTime = block.timestamp + _TIMELOCK_SLOT.fetchUint256();
        (_slot.scheduledContentSlot()).setAddress(targetAddress);
        (_slot.scheduledTimeSlot()).setUint256(activeTime);

        emit UpgradeScheduled(targetAddress, activeTime);
    }

    function proxyScheduleTimelockUpdate(uint256 newTimelock) public adminPriviledged {
        uint256 activeTime = block.timestamp + _TIMELOCK_SLOT.fetchUint256();
        (_TIMELOCK_SLOT.scheduledContentSlot()).setUint256(newTimelock);
        (_TIMELOCK_SLOT.scheduledTimeSlot()).setUint256(activeTime);

        emit TimelockUpdateScheduled(newTimelock, activeTime);
    }

    function proxyUpgradeTimelock()
        public
        adminPriviledged
        requireTimelockPassed(_TIMELOCK_SLOT)
    {
        uint256 newTimelock =
            (_TIMELOCK_SLOT.scheduledContentSlot()).fetchUint256();
        _TIMELOCK_SLOT.setUint256(newTimelock);
        emit TimelockUpdated(newTimelock);
    }

    function proxyUpgradeImplementation()
        public
        adminPriviledged
        requireTimelockPassed(_IMPLEMENTATION_SLOT)
    {
        address newImplementation =
            (_IMPLEMENTATION_SLOT.scheduledContentSlot()).fetchAddress();
        _IMPLEMENTATION_SLOT.setAddress(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _implementation() internal view override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    function _systemStorage() internal view returns (address systemStorage) {
        bytes32 slot = _SYSTEM_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            systemStorage := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
    UnstructuredStorageWithTimelock is a set of functions that facilitates setting/fetching unstructured storage 
    along with information of future updates and its timelock information.

    For every content storage, there are two other slots that could be calculated automatically:
        * Slot (The current value)
        * Scheduled Slot (The future value)
        * Scheduled Time (The future time)

    Note that the library does NOT enforce timelock and does NOT store the timelock information.
*/
library UnstructuredStorageWithTimelock {
    // This is used to calculate the time slot and scheduled content for different variables
    uint256 private constant SCHEDULED_SIGNATURE = 0x111;
    uint256 private constant TIMESLOT_SIGNATURE = 0xAAA;

    function updateAddressWithTimelock(bytes32 _slot) internal {
        require(
            scheduledTime(_slot) > block.timestamp,
            "Timelock has not passed"
        );
        setAddress(_slot, scheduledAddress(_slot));
    }

    function updateUint256WithTimelock(bytes32 _slot) internal {
        require(
            scheduledTime(_slot) > block.timestamp,
            "Timelock has not passed"
        );
        setUint256(_slot, scheduledUint256(_slot));
    }

    function setAddress(bytes32 _slot, address _target) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_slot, _target)
        }
    }

    function fetchAddress(bytes32 _slot)
        internal
        view
        returns (address result)
    {
        assembly {
            result := sload(_slot)
        }
    }

    function scheduledAddress(bytes32 _slot)
        internal
        view
        returns (address result)
    {
        result = fetchAddress(scheduledContentSlot(_slot));
    }

    function scheduledUint256(bytes32 _slot)
        internal
        view
        returns (uint256 result)
    {
        result = fetchUint256(scheduledContentSlot(_slot));
    }

    function setUint256(bytes32 _slot, uint256 _target) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_slot, _target)
        }
    }

    function fetchUint256(bytes32 _slot)
        internal
        view
        returns (uint256 result)
    {
        assembly {
            result := sload(_slot)
        }
    }

    function scheduledContentSlot(bytes32 _slot)
        internal
        pure
        returns (bytes32)
    {
        return
            bytes32(
                uint256(keccak256(abi.encodePacked(_slot, SCHEDULED_SIGNATURE)))
            );
    }

    function scheduledTime(bytes32 _slot) internal view returns (uint256) {
        return fetchUint256(scheduledTimeSlot(_slot));
    }

    function scheduledTimeSlot(bytes32 _slot) internal pure returns (bytes32) {
        return
            bytes32(
                uint256(keccak256(abi.encodePacked(_slot, TIMESLOT_SIGNATURE)))
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IStorageV1 {
    function governance() external view returns(address);
    function treasury() external view returns(address);
    function isAdmin(address _target) external view returns(bool);
    function isOperator(address _target) external view returns(bool);
}

