/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


library LibRichErrors {
	bytes4 internal constant STANDARD_ERROR_SELECTOR = bytes4(keccak256("Error(string)"));

    function StandardError(string memory message)
        internal
        pure
        returns (bytes memory encodedError)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }

    function rrevert(bytes memory encodedError)
        internal
        pure
    {
        assembly {
            revert(add(encodedError, 0x20), mload(encodedError))
        }
    }
}


library LibProxyRichErrors {
    function NotImplementedError(bytes4 selector)
        internal
        pure
        returns (bytes memory encodedError)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("NotImplementedError(bytes4)")),
            selector
        );
    }

    function InvalidBootstrapCallerError(address actual, address expected)
        internal
        pure
        returns (bytes memory encodedError)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidBootstrapCallerError(address,address)")),
            actual,
            expected
        );
    }

    function InvalidDieCallerError(address actual, address expected)
        internal
        pure
        returns (bytes memory encodedError)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("InvalidDieCallerError(address,address)")),
            actual,
            expected
        );
    }

    function BootstrapCallFailedError(address target, bytes memory resultData)
        internal
        pure
        returns (bytes memory encodedError)
    {
        return abi.encodeWithSelector(
            bytes4(keccak256("BootstrapCallFailedError(address,bytes)")),
            target,
            resultData
        );
    }
}


library LibBootstrap {
    bytes4 internal constant BOOTSTRAP_SUCCESS = bytes4(keccak256("BOOTSTRAP_SUCCESS"));

    using LibRichErrors for bytes;

    function delegatecallBootstrapFunction(
        address target,
        bytes memory data
    )
        internal
    {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success ||
            resultData.length != 32 ||
            abi.decode(resultData, (bytes4)) != BOOTSTRAP_SUCCESS)
        {
            LibProxyRichErrors.BootstrapCallFailedError(target, resultData).rrevert();
        }
    }
}


/// @dev Common storage helpers
library LibStorage {
    /// @dev What to bit-shift a storage ID by to get its slot.
    ///      This gives us a maximum of 2**128 inline fields in each bucket.
    uint256 private constant STORAGE_SLOT_EXP = 128;

    /// @dev Storage IDs for feature storage buckets.
    ///      WARNING: APPEND-ONLY.
    enum StorageId {
        Proxy,
        SimpleFunctionRegistry,
        Ownable,
        ERC20,
        AccessControl,
        ERC20AccessControl,
        Test
    }

    /// @dev Get the storage slot given a storage ID. We assign unique, well-spaced
    ///     slots to storage bucket variables to ensure they do not overlap.
    ///     See: https://solidity.readthedocs.io/en/v0.6.6/assembly.html#access-to-external-variables-functions-and-libraries
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function getStorageSlot(StorageId storageId)
        internal
        pure
        returns (uint256 slot)
    {
        // This should never overflow with a reasonable `STORAGE_SLOT_EXP`
        // because Solidity will do a range check on `storageId` during the cast.
        return (uint256(storageId) + 1) << STORAGE_SLOT_EXP;
    }
}


library LibProxyStorage {
    struct Storage {
        // Mapping of function selector -> function implementation
        mapping(bytes4 => address) impls;
        //address owner;
    }

    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(
            LibStorage.StorageId.Proxy
        );
        assembly {
            stor.slot := storageSlot
        }
    }
}


interface IBootstrapFeature {
    /// @dev Bootstrap the initial feature set of this contract by delegatecalling
    ///      into `target`. Before exiting the `bootstrap()` function will
    ///      deregister itself from the proxy to prevent being called again.
    /// @param target The bootstrapper contract address.
    /// @param callData The call data to execute on `target`.
    function bootstrap(address target, bytes calldata callData) external;
}


/// @dev Detachable `bootstrap()` feature.
contract BootstrapFeature is
    IBootstrapFeature
{
    // immutable -> persist across delegatecalls
    /// @dev aka ZeroEx.
    address immutable private _deployer;
    /// @dev The implementation address of this contract.
    address immutable private _implementation;
    /// @dev aka InitialMigration.
    address immutable private _bootstrapCaller;

    using LibRichErrors for bytes;

    constructor(address bootstrapCaller) {
        _deployer = msg.sender;
        _implementation = address(this);
        _bootstrapCaller = bootstrapCaller;
    }

    modifier onlyBootstrapCaller() {
        if (msg.sender != _bootstrapCaller) {
            LibProxyRichErrors.InvalidBootstrapCallerError(msg.sender, _bootstrapCaller).rrevert();
        }
        _;
    }

    modifier onlyDeployer() {
        if (msg.sender != _deployer) {
            LibProxyRichErrors.InvalidDieCallerError(msg.sender, _deployer).rrevert();
        }
        _;
    }

    function bootstrap(address target, bytes calldata callData) external override onlyBootstrapCaller {
        LibProxyStorage.getStorage().impls[this.bootstrap.selector] = address(0);
        BootstrapFeature(_implementation).die();
        LibBootstrap.delegatecallBootstrapFunction(target, callData);
    }

    function die() external onlyDeployer {
        assert(address(this) == _implementation);
        selfdestruct(payable(msg.sender));
    }
}


contract ZeroEx_ {
    /// @param bootstrapper Who can call `bootstrap()`.
    constructor(address bootstrapper) {
        BootstrapFeature bootstrap = new BootstrapFeature(bootstrapper);
        LibProxyStorage.getStorage().impls[bootstrap.bootstrap.selector] = address(bootstrap);
    }

    function getFunctionImplementation(bytes4 selector)
        public
        view
        returns (address impl)
    {
        return LibProxyStorage.getStorage().impls[selector];
    }

    fallback() external payable {
        mapping(bytes4 => address) storage impls =
            LibProxyStorage.getStorage().impls;

        assembly {
            let cdlen := calldatasize()

            // receive() external payable {}
            if iszero(cdlen) {
                return(0, 0)
            }

            // 0x00-0x3F reserved for slot calculation
            calldatacopy(0x40, 0, cdlen)
            let selector := and(mload(0x40), 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)

            // slot for impls[selector] = keccak256(selector . impls.slot)
            mstore(0, selector)
            mstore(0x20, impls.slot)
            let slot := keccak256(0, 0x40)

            let delegate := sload(slot)
            if iszero(delegate) {
                // abi.encodeWithSelector(bytes4(keccak256("NotImplementedError(bytes4)")), selector)
                mstore(0, 0x734e6e1c00000000000000000000000000000000000000000000000000000000)
                mstore(4, selector)
                revert(0, 0x24)
            }

            let success := delegatecall(
                gas(),
                delegate,
                0x40, cdlen,
                0, 0
            )
            let rdlen := returndatasize()
            returndatacopy(0, 0, rdlen)
            if success {
                return(0, rdlen)
            }
            revert(0, rdlen)
        }
    }
}