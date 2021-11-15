//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./Proxy.sol";
import "../Utils/Ownable.sol";

contract DepositProxy is Ownable, Proxy {
    constructor(address initialImplementation, address owner) Ownable(owner) {
        _setImplementation(initialImplementation);
        _setVersion(1);
    }

    event Upgraded(address indexed implementation);

    function changeImplementation(address newImplementation)
        external
        onlyOwner
    {
        uint256 newVersion = _version() + 1;
        _setImplementation(newImplementation);
        _setVersion(newVersion);
        emit Upgraded(newImplementation);
    }

    function currentVersion() external view returns (uint256) {
        return _version();
    }

    function currentImplementation() external view returns (address) {
        return _implementation();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "../Utils/StorageSlot.sol";

contract Proxy {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 internal constant _VERSION_SLOT =
        0xd5fc8d396276aa91befc6c316c18c9435be69c677ed2ba2a3e9d17d7cfcb51f0;

    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }

    function _implementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _version() internal view returns (uint256) {
        return StorageSlot.getUint256Slot(_VERSION_SLOT).value;
    }

    function _setImplementation(address newImplementation) internal {
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    function _setVersion(uint256 newVersion) internal {
        StorageSlot.getUint256Slot(_VERSION_SLOT).value = newVersion;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./StorageSlot.sol";

abstract contract Ownable {
    bytes32 internal constant _OWNER_SLOT =
        0x8a721d7331971cd5eefcd6a2b20c226462fc25662d105424a4f69c8d550cca50;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address initialOwner) {
        _setOwner(initialOwner);
    }

    function owner() public view virtual returns (address) {
        return StorageSlot.getAddressSlot(_OWNER_SLOT).value;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = owner();
        StorageSlot.getAddressSlot(_OWNER_SLOT).value = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }
}

