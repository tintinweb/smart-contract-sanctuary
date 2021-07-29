/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @gnosis.pm/safe-contracts/contracts/common/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}


// File @gnosis.pm/safe-contracts/contracts/common/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}


// File @gnosis.pm/safe-contracts/contracts/base/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <[email protected]>
contract Executor {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}


// File @gnosis.pm/safe-contracts/contracts/base/[email protected]

pragma solidity >=0.7.0 <0.9.0;



/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract ModuleManager is SelfAuthorized, Executor {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    function setupModules(address to, bytes memory data) internal {
        require(modules[SENTINEL_MODULES] == address(0), "GS100");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
            // Setup has to complete successfully or transaction fails.
            require(execute(to, 0, data, Enum.Operation.DelegateCall, gasleft()), "GS000");
    }

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) public authorized {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "GS102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Disables the module `module` for the Safe.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) public authorized {
        // Validate module address and check that it corresponds to module index.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        require(modules[prevModule] == module, "GS103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        // Only whitelisted modules are allowed.
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "GS104");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next) {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (currentModule != address(0x0) && currentModule != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}


// File @gnosis.pm/safe-contracts/contracts/base/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title OwnerManager - Manages a set of owners and a threshold to perform actions.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract OwnerManager is SelfAuthorized {
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    function setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "GS200");
        // Validate that threshold is smaller than number of added owners.
        require(_threshold <= _owners.length, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this) && currentOwner != owner, "GS203");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "GS204");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev Allows to add a new owner to the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Adds the owner `owner` to the Safe and updates the threshold to `_threshold`.
    /// @param owner New owner address.
    /// @param _threshold New threshold.
    function addOwnerWithThreshold(address owner, uint256 _threshold) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "GS204");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to remove an owner from the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Removes the owner `owner` from the Safe and updates the threshold to `_threshold`.
    /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed.
    /// @param _threshold New threshold.
    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) public authorized {
        // Only allow to remove an owner, if threshold can still be reached.
        require(ownerCount - 1 >= _threshold, "GS201");
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == owner, "GS205");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS && newOwner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "GS204");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == oldOwner, "GS205");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev Allows to update the number of required confirmations by Safe owners.
    ///      This can only be done via a Safe transaction.
    /// @notice Changes the threshold of the Safe to `_threshold`.
    /// @param _threshold New threshold.
    function changeThreshold(uint256 _threshold) public authorized {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= ownerCount, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }
}


// File @gnosis.pm/safe-contracts/contracts/base/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    function internalSetFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallbacks calls.
    function setFallbackHandler(address handler) public authorized {
        internalSetFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}


// File @gnosis.pm/safe-contracts/contracts/base/[email protected]

pragma solidity >=0.7.0 <0.9.0;


interface Guard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}


// File @gnosis.pm/safe-contracts/contracts/common/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title EtherPaymentFallback - A contract that has a fallback to accept ether payments
/// @author Richard Meissner - <[email protected]>
contract EtherPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /// @dev Fallback function accepts Ether transactions.
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}


// File @gnosis.pm/safe-contracts/contracts/common/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title Singleton - Base for singleton contracts (should always be first super contract)
///         This contract is tightly coupled to our proxy contract (see `proxies/GnosisSafeProxy.sol`)
/// @author Richard Meissner - <[email protected]>
contract Singleton {
    // singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private singleton;
}


// File @gnosis.pm/safe-contracts/contracts/common/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}


// File @gnosis.pm/safe-contracts/contracts/common/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title SecuredTokenTransfer - Secure token transfer
/// @author Richard Meissner - <[email protected]>
contract SecuredTokenTransfer {
    /// @dev Transfers a token and returns if it was a success
    /// @param token Token that should be transferred
    /// @param receiver Receiver to whom the token should be transferred
    /// @param amount The amount of tokens that should be transferred
    function transferToken(
        address token,
        address receiver,
        uint256 amount
    ) internal returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
                case 0 {
                    transferred := success
                }
                case 0x20 {
                    transferred := iszero(or(iszero(success), iszero(mload(0))))
                }
                default {
                    transferred := 0
                }
        }
    }
}


// File @gnosis.pm/safe-contracts/contracts/common/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
contract StorageAccessible {
    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegetecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static).
     *
     * This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
     * Specifically, the `returndata` after a call to this method will be:
     * `success:bool || response.length:uint256 || response:bytes`.
     *
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}


// File @gnosis.pm/safe-contracts/contracts/interfaces/[email protected]

pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}


// File @gnosis.pm/safe-contracts/contracts/external/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title GnosisSafeMath
 * @dev Math operations with safety checks that revert on error
 * Renamed from SafeMath to GnosisSafeMath to avoid conflicts
 * TODO: remove once open zeppelin update to solc 0.5.0
 */
library GnosisSafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}


// File @gnosis.pm/safe-contracts/contracts/[email protected]

pragma solidity >=0.7.0 <0.9.0;











/// @title Gnosis Safe - A multisignature wallet with support for confirmations using signed messages based on ERC191.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract GnosisSafe is
    EtherPaymentFallback,
    Singleton,
    ModuleManager,
    OwnerManager,
    SignatureDecoder,
    SecuredTokenTransfer,
    ISignatureValidatorConstants,
    FallbackManager,
    StorageAccessible,
    GuardManager
{
    using GnosisSafeMath for uint256;

    string public constant VERSION = "1.3.0";

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    event SafeSetup(address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event SignMsg(bytes32 indexed msgHash);
    event ExecutionFailure(bytes32 txHash, uint256 payment);
    event ExecutionSuccess(bytes32 txHash, uint256 payment);

    uint256 public nonce;
    bytes32 private _deprecatedDomainSeparator;
    // Mapping to keep track of all message hashes that have been approve by ALL REQUIRED owners
    mapping(bytes32 => uint256) public signedMessages;
    // Mapping to keep track of all hashes (message or transaction) that have been approve by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    // This constructor ensures that this contract can only be used as a master copy for Proxy contracts
    constructor() {
        // By setting the threshold it is not possible to call setup anymore,
        // so we create a Safe with 0 owners and threshold 1.
        // This is an unusable Safe, perfect for the singleton
        threshold = 1;
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Adddress that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        // setupOwners checks if the Threshold is already set, therefore preventing that this method is called twice
        setupOwners(_owners, _threshold);
        if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);
        // As setupOwners can only be called if the contract has not been initialized we don't need a check for setupModules
        setupModules(to, data);

        if (payment > 0) {
            // To avoid running into issues with EIP-170 we reuse the handlePayment function (to avoid adjusting code of that has been verified we do not adjust the method itself)
            // baseGas = 0, gasPrice = 1 and gas = payment => amount = (payment + 0) * 1 = payment
            handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
        }
        emit SafeSetup(msg.sender, _owners, _threshold, to, fallbackHandler);
    }

    /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
    ///      Note: The fees are always transferred, even if the user transaction fails.
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param safeTxGas Gas that should be used for the Safe transaction.
    /// @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash;
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            bytes memory txHashData =
                encodeTransactionData(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    nonce
                );
            // Increase nonce and execute transaction.
            nonce++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, txHashData, signatures);
        }
        address guard = getGuard();
        {
            if (guard != address(0)) {
                Guard(guard).checkTransaction(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    signatures,
                    msg.sender
                );
            }
        }
        // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
        // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
        require(gasleft() >= ((safeTxGas * 64) / 63).max(safeTxGas + 2500) + 500, "GS010");
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            uint256 gasUsed = gasleft();
            // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than safeTxGas)
            // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than safeTxGas
            success = execute(to, value, data, operation, gasPrice == 0 ? (gasleft() - 2500) : safeTxGas);
            gasUsed = gasUsed.sub(gasleft());
            // If no safeTxGas and no gasPrice was set (e.g. both are 0), then the internal tx is required to be successful
            // This makes it possible to use `estimateGas` without issues, as it searches for the minimum gas where the tx doesn't revert
            require(success || safeTxGas != 0 || gasPrice != 0, "GS013");
            // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
            uint256 payment = 0;
            if (gasPrice > 0) {
                payment = handlePayment(gasUsed, baseGas, gasPrice, gasToken, refundReceiver);
            }
            if (success) emit ExecutionSuccess(txHash, payment);
            else emit ExecutionFailure(txHash, payment);
        }
        {
            if (guard != address(0)) {
                Guard(guard).checkAfterExecution(txHash, success);
            }
        }
    }

    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    ) private returns (uint256 payment) {
        // solhint-disable-next-line avoid-tx-origin
        address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
        if (gasToken == address(0)) {
            // For ETH we will only adjust the gas price to not be higher than the actual used gas price
            payment = gasUsed.add(baseGas).mul(gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
            require(receiver.send(payment), "GS011");
        } else {
            payment = gasUsed.add(baseGas).mul(gasPrice);
            require(transferToken(gasToken, receiver, payment), "GS012");
        }
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "GS001");
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures.mul(65), "GS020");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures.mul(65), "GS021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s).add(32) <= signatures.length, "GS022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s).add(32).add(contractSignatureLen) <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS, "GS026");
            lastOwner = currentOwner;
        }
    }

    /// @dev Allows to estimate a Safe transaction.
    ///      This method is only meant for estimation purpose, therefore the call will always revert and encode the result in the revert data.
    ///      Since the `estimateGas` function includes refunds, call this method to get an estimated of the costs that are deducted from the safe with `execTransaction`
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @return Estimate without refunds and overhead fees (base transaction and payload data gas costs).
    /// @notice Deprecated in favor of common/StorageAccessible.sol and will be removed in next version.
    function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // Convert response to string and return via error message
        revert(string(abi.encodePacked(requiredGas)));
    }

    /**
     * @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
     * @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
     */
    function approveHash(bytes32 hashToApprove) external {
        require(owners[msg.sender] != address(0), "GS030");
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    /// @dev Returns the bytes that are hashed to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Gas that should be used for the safe transaction.
    /// @param baseGas Gas costs for that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash bytes.
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    SAFE_TX_TYPEHASH,
                    to,
                    value,
                    keccak256(data),
                    operation,
                    safeTxGas,
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    _nonce
                )
            );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeTxHash);
    }

    /// @dev Returns hash to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Fas that should be used for the safe transaction.
    /// @param baseGas Gas costs for data used to trigger the safe transaction.
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash.
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}


// File contracts/Modules/Strategies/AbstractStrategy.sol

pragma solidity ^0.8.4;

abstract contract AbstractStrategy {
    /// The executors for the safe.
    mapping(address => address) executors;

    modifier onlyExecutor(GnosisSafe safe) {
        require(
            executors[address(safe)] == msg.sender || safe.isOwner(msg.sender),
            "Sender is not executor"
        );
        _;
    }

    function NAME() external view virtual returns (string memory);

    function addExecutor(address executor) external {
        require(executors[msg.sender] == address(0x0), "executor already set");
        executors[msg.sender] = executor;
    }

    function removeExecutor() external {
        executors[msg.sender] = address(0x0);
    }

    function harvest(GnosisSafe safe) external virtual;

    function deposit(GnosisSafe safe, uint256 amount) public virtual;
}


// File contracts/Interfaces/ERC20.sol

pragma solidity ^0.8.0;

interface ERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}


// File contracts/Interfaces/PopsicleFinance/Sorbettiere.sol

pragma solidity ^0.8.4;

interface Sorbettiere {
    struct PoolInfo {
        ERC20 stakingToken;
        uint256 stakingTokenTotalAmount;
        uint256 accIcePerShare;
        uint32 lastRewardTime;
        uint16 allocPoint;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 remainingIceTokenReward;
    }

    function poolInfo(uint256) external returns (PoolInfo memory);

    function userInfo(uint256, address) external view returns (UserInfo memory);

    function deposit(uint256, uint256) external;

    function withdraw(uint256, uint256) external;

    function updatePool(uint256) external;

    function ice() external view returns (ERC20);
}


// File contracts/Interfaces/Uniswap.sol

pragma solidity ^0.8.4;

interface Uniswap {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory);
}


// File contracts/Libraries/SafeHelper.sol

pragma solidity ^0.8.4;



library SafeHelper {
    function approve(
        GnosisSafe safe,
        ERC20 token,
        address spender,
        uint256 amount
    ) internal {
        call(
            safe,
            address(token),
            abi.encodeWithSelector(token.approve.selector, spender, amount),
            "failed to approve"
        );
    }

    function execute(
        GnosisSafe safe,
        address to,
        bytes memory data
    ) internal {
        call(safe, to, data, "could not execute");
    }

    function call(
        GnosisSafe safe,
        address to,
        bytes memory data,
        string memory reason
    ) internal {
        require(
            safe.execTransactionFromModule(to, 0, data, Enum.Operation.Call),
            reason
        );
    }

    function swapExactTokensForTokens(
        GnosisSafe safe,
        Uniswap exchange,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) internal returns (uint256[] memory) {
        (bool success, bytes memory data) = safe.execTransactionFromModuleReturnData(
            address(exchange),
            0,
            abi.encodeWithSelector(
                exchange.swapExactTokensForTokens.selector,
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            ),
            Enum.Operation.Call
        );
        require(success);

        return abi.decode(data, (uint256[]));
    }
}


// File hardhat/[email protected]

pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}


// File contracts/Libraries/ExchangeHelper.sol

pragma solidity ^0.8.4;





library ExchangeHelper {
    Uniswap public constant uni = Uniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    Uniswap public constant sushi = Uniswap(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    function amountOutFor(
        Uniswap exchange,
        address[] memory path,
        uint256 amountIn
    ) internal returns (uint256) {
        uint256[] memory amountsOut = exchange.getAmountsOut(amountIn, path);
        return amountsOut[amountsOut.length - 1];
    }

    function dataForBestExchange(
        Uniswap a,
        Uniswap b,
        address[] memory path,
        uint256 amount
    ) internal returns (Uniswap, uint256) {
        uint256 aAmount = amountOutFor(a, path, amount);
        uint256 bAmount = amountOutFor(b, path, amount);

        if (aAmount > bAmount) {
            return (a, aAmount);
        } else {
            return (b, bAmount);
        }
    }

    // @TODO THIS FEELS A BIT MESSY

    function sellForBestPriceWithSlippage(
        GnosisSafe safe,
        address[] memory path,
        uint256 sellAmount,
        uint256 slippage
    ) internal returns (uint256) {
        // Check for best price
        (Uniswap exchange, uint256 amount) = dataForBestExchange(
            uni,
            sushi,
            path,
            sellAmount
        );

        // Return if we won't be able to sell any
        if (amount == 0) {
            return 0;
        }

        // Approve Token on best exchange
        SafeHelper.approve(safe, ERC20(path[0]), address(exchange), sellAmount);

        // Trade
        uint256[] memory balances = SafeHelper.swapExactTokensForTokens(
            safe,
            exchange,
            sellAmount,
            (amount * (1000 - slippage)) / 1000,
            path,
            address(safe),
            block.timestamp + 180
        );

        return balances[2];
    }
}


// File contracts/Modules/Strategies/SorbettiereStrategy.sol

pragma solidity ^0.8.4;



contract SorbettiereStrategy is AbstractStrategy {
    using ExchangeHelper for Uniswap;
    using SafeHelper for GnosisSafe;

    string public constant VERSION = "1.0.0";

    Sorbettiere public immutable sorbettiere;

    ERC20 public immutable ice;
    ERC20 public constant usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 public constant weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ERC20 public immutable stakingToken;
    uint256 public immutable pool;

    address[] public path;

    constructor(Sorbettiere _sorbettiere, uint256 _pool) {
        pool = _pool;
        stakingToken = _sorbettiere.poolInfo(_pool).stakingToken;
        path = [address(_sorbettiere.ice()), address(weth), address(usdc)];
        ice = _sorbettiere.ice();
        sorbettiere = _sorbettiere;
    }

    function NAME() external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Sorbettiere ",
                    ice.name(),
                    " - ",
                    stakingToken.symbol(),
                    " Strategy Module"
                )
            );
    }

    function harvest(GnosisSafe safe) external override {
        uint256 amountBefore = ice.balanceOf(address(safe));

        // Redeem
        safe.call(
            address(sorbettiere),
            abi.encodeWithSelector(sorbettiere.withdraw.selector, pool, 0),
            "failed to withdraw"
        );

        uint256 amountAfter = ice.balanceOf(address(safe));
        uint256 balance = amountAfter - amountBefore;

        require(balance > 0, "balance was 0");

        uint256 amountOut = ExchangeHelper.sellForBestPriceWithSlippage(
            safe,
            path,
            balance,
            20
        );
    }

    function deposit(GnosisSafe safe, uint256 amount) public override {
        // Approve Staking Token
        safe.approve(stakingToken, address(sorbettiere), amount);

        // Deposit
        safe.call(
            address(sorbettiere),
            abi.encodeWithSelector(sorbettiere.deposit.selector, pool, amount),
            "could not deposit"
        );
    }

    function withdraw(GnosisSafe safe, uint256 amount) public {
        safe.call(
            address(sorbettiere),
            abi.encodeWithSelector(sorbettiere.withdraw.selector, pool, amount),
            "could not withdraw"
        );
    }
}