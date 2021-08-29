//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

contract DepositProxy {
    address public owner;

    constructor(address initialImplementation) {
        _setImplementation(initialImplementation);
        _setVersion(1);
        owner = msg.sender;
    }

    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x24ed44ee9374370fd3aa7c8b1abf58827504c20f65246b17d2b9e7e1aef77847;

    bytes32 internal constant _VERSION_SLOT =
        0xd5fc8d396276aa91befc6c316c18c9435be69c677ed2ba2a3e9d17d7cfcb51f0;

    struct AddressSlot {
        address value;
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

    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }

    function _fallback() internal virtual {
        _delegate(_implementation());
    }

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

    function _implementation() internal view returns (address) {
        return getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _version() internal view returns (uint256) {
        return getUint256Slot(_VERSION_SLOT).value;
    }

    function _setImplementation(address newImplementation) internal {
        getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    function _setVersion(uint256 newVersion) internal {
        getUint256Slot(_VERSION_SLOT).value = newVersion;
    }

    function changeImplementation(address newImplementation)
        external
        onlyOwner
    {
        uint256 newVersion = _version() + 1;
        _setImplementation(newImplementation);
        _setVersion(newVersion);
    }

    function currentVersion() external view returns (uint256) {
        return _version();
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}