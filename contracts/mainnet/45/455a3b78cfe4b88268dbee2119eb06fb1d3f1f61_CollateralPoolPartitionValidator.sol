// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

abstract contract ERC1820Registry {
    function setInterfaceImplementer(
        address _addr,
        bytes32 _interfaceHash,
        address _implementer
    ) external virtual;

    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash)
        external
        virtual
        view
        returns (address);

    function setManager(address _addr, address _newManager) external virtual;

    function getManager(address _addr) public virtual view returns (address);
}

/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
    );

    function setInterfaceImplementation(
        string memory _interfaceLabel,
        address _implementation
    ) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            interfaceHash,
            _implementation
        );
    }

    function interfaceAddr(address addr, string memory _interfaceLabel)
        internal
        view
        returns (address)
    {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

contract ERC1820Implementer {
    /**
     * @dev ERC1820 well defined magic value indicating the contract has
     * registered with the ERC1820Registry that it can implement an interface.
     */
    bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256(
        abi.encodePacked("ERC1820_ACCEPT_MAGIC")
    );

    /**
     * @dev Mapping of interface name keccak256 hashes for which this contract
     * implements the interface.
     * @dev Only settable internally.
     */
    mapping(bytes32 => bool) internal _interfaceHashes;

    /**
     * @notice Indicates whether the contract implements the interface `_interfaceHash`
     * for the address `_addr`.
     * @param _interfaceHash keccak256 hash of the name of the interface.
     * @return ERC1820_ACCEPT_MAGIC only if the contract implements `ìnterfaceHash`
     * for the address `_addr`.
     * @dev In this implementation, the `_addr` (the address for which the
     * contract will implement the interface) is always `address(this)`.
     */
    function canImplementInterfaceForAddress(
        bytes32 _interfaceHash,
        address // Comments to avoid compilation warnings for unused variables. /*addr*/
    ) external view returns (bytes32) {
        if (_interfaceHashes[_interfaceHash]) {
            return ERC1820_ACCEPT_MAGIC;
        } else {
            return "";
        }
    }

    /**
     * @notice Internally set the fact this contract implements the interface
     * identified by `_interfaceLabel`
     * @param _interfaceLabel String representation of the interface.
     */
    function _setInterface(string memory _interfaceLabel) internal {
        _interfaceHashes[keccak256(abi.encodePacked(_interfaceLabel))] = true;
    }
}

/**
 * @notice Partition strategy validator hooks for Amp
 */
interface IAmpPartitionStrategyValidator {
    function tokensFromPartitionToValidate(
        bytes4 _functionSig,
        bytes32 _partition,
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    function tokensToPartitionToValidate(
        bytes4 _functionSig,
        bytes32 _partition,
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    function isOperatorForPartitionScope(
        bytes32 _partition,
        address _operator,
        address _tokenHolder
    ) external view returns (bool);
}

/**
 * @title PartitionUtils
 * @notice Partition related helper functions.
 */

library PartitionUtils {
    bytes32 public constant CHANGE_PARTITION_FLAG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /**
     * @notice Retrieve the destination partition from the 'data' field.
     * A partition change is requested ONLY when 'data' starts with the flag:
     *
     *   0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
     *
     * When the flag is detected, the destination partition is extracted from the
     * 32 bytes following the flag.
     * @param _data Information attached to the transfer. Will contain the
     * destination partition if a change is requested.
     * @param _fallbackPartition Partition value to return if a partition change
     * is not requested in the `_data`.
     * @return toPartition Destination partition. If the `_data` does not contain
     * the prefix and bytes32 partition in the first 64 bytes, the method will
     * return the provided `_fromPartition`.
     */
    function _getDestinationPartition(bytes memory _data, bytes32 _fallbackPartition)
        internal
        pure
        returns (bytes32)
    {
        if (_data.length < 64) {
            return _fallbackPartition;
        }

        (bytes32 flag, bytes32 toPartition) = abi.decode(_data, (bytes32, bytes32));
        if (flag == CHANGE_PARTITION_FLAG) {
            return toPartition;
        }

        return _fallbackPartition;
    }

    /**
     * @notice Helper to get the strategy identifying prefix from the `_partition`.
     * @param _partition Partition to get the prefix for.
     * @return 4 byte partition strategy prefix.
     */
    function _getPartitionPrefix(bytes32 _partition) internal pure returns (bytes4) {
        return bytes4(_partition);
    }

    /**
     * @notice Helper method to split the partition into the prefix, sub partition
     * and partition owner components.
     * @param _partition The partition to split into parts.
     * @return The 4 byte partition prefix, 8 byte sub partition, and final 20
     * bytes representing an address.
     */
    function _splitPartition(bytes32 _partition)
        internal
        pure
        returns (
            bytes4,
            bytes8,
            address
        )
    {
        bytes4 prefix = bytes4(_partition);
        bytes8 subPartition = bytes8(_partition << 32);
        address addressPart = address(uint160(uint256(_partition)));
        return (prefix, subPartition, addressPart);
    }

    /**
     * @notice Helper method to get a partition strategy ERC1820 interface name
     * based on partition prefix.
     * @param _prefix 4 byte partition prefix.
     * @dev Each 4 byte prefix has a unique interface name so that an individual
     * hook implementation can be set for each prefix.
     */
    function _getPartitionStrategyValidatorIName(bytes4 _prefix)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("AmpPartitionStrategyValidator", _prefix));
    }
}

/**
 * @title Base contract that satisfies the IAmpPartitionStrategyValidator
 * interface
 */
contract AmpPartitionStrategyValidatorBase is
    IAmpPartitionStrategyValidator,
    ERC1820Client,
    ERC1820Implementer
{
    /**
     * @notice Partition prefix the hooks are valid for.
     * @dev Must to be set by the parent contract.
     */
    bytes4 public partitionPrefix;

    /**
     * @notice Amp contract address.
     */
    address public amp;

    /**
     * @notice Initialize the partition prefix and register the implementation
     * with the ERC1820 registry for the dynamic interface name.
     * @param _prefix Partition prefix the hooks are valid for.
     * @param _amp The address of the Amp contract.
     */
    constructor(bytes4 _prefix, address _amp) public {
        partitionPrefix = _prefix;

        string memory iname = PartitionUtils._getPartitionStrategyValidatorIName(
            partitionPrefix
        );
        ERC1820Implementer._setInterface(iname);

        amp = _amp;
    }

    /**
     * @dev Placeholder to satisfy IAmpPartitionSpaceValidator interface that
     * can be overridden by parent.
     */
    function tokensFromPartitionToValidate(
        bytes4, /* functionSig */
        bytes32, /* fromPartition */
        address, /* operator */
        address, /* from */
        address, /* to */
        uint256, /* value */
        bytes calldata, /* data */
        bytes calldata /* operatorData */
    ) external virtual override {}

    /**
     * @dev Placeholder to satisfy IAmpPartitionSpaceValidator interface that
     * can be overridden by parent.
     */
    function tokensToPartitionToValidate(
        bytes4, /* functionSig */
        bytes32, /* fromPartition */
        address, /* operator */
        address, /* from */
        address, /* to */
        uint256, /* value */
        bytes calldata, /* data */
        bytes calldata /* operatorData */
    ) external virtual override {}

    /**
     * @notice Report if address is an operator for a partition based on the
     * partition's strategy.
     * @dev Placeholder that can be overridden by parent.
     */
    function isOperatorForPartitionScope(
        bytes32, /* partition */
        address, /* operator */
        address /* tokenHolder */
    ) external virtual override view returns (bool) {
        return false;
    }
}


interface IAmp {
    function isCollateralManager(address) external view returns (bool);
}

/**
 * @title CollateralPoolPartitionValidator
 */
contract CollateralPoolPartitionValidator is AmpPartitionStrategyValidatorBase {
    bytes4 constant PARTITION_PREFIX = 0xCCCCCCCC;

    constructor(address _amp)
        public
        AmpPartitionStrategyValidatorBase(PARTITION_PREFIX, _amp)
    {}

    /**
     * @notice Reports if the token holder is an operator for the partition.
     * @dev The `_operator` address param is unused. For this strategy, this will
     * be being called on behalf of suppliers, as they have sent their tokens
     * to the collateral manager address, and are now trying to execute a
     * transfer from the pool. This implies that the pool sender hook
     * MUST be implemented in such a way as to restrict any unauthorized
     * transfers, as the partitions affected by this strategy will allow
     * all callers to make an attempt to transfer from the collateral
     * managers partition.
     * @param _partition The partition to check.
     * @param _tokenHolder The collateral manager holding the pool of tokens.
     * @return The operator check for this strategy returns true if the partition
     * owner (identified by the final 20 bytes of the partition) is the
     * same as the token holder address, as in this case the token holder
     * is the collateral manager address.
     */
    function isOperatorForPartitionScope(
        bytes32 _partition,
        address, /* operator */
        address _tokenHolder
    ) external override view returns (bool) {
        require(msg.sender == address(amp), "Hook must be called by amp");

        (, , address partitionOwner) = PartitionUtils._splitPartition(_partition);
        if (!IAmp(amp).isCollateralManager(partitionOwner)) {
            return false;
        }

        return _tokenHolder == partitionOwner;
    }

    /**
     * @notice Validate the rules of the strategy when tokens are being sent to
     * a partition under the purview of the strategy.
     * @dev The `_toPartition` must be formatted with the PARTITION_PREFIX as the
     * first 4 bytes, the `_to` value as the final 20 bytes. The 8 bytes in the
     * middle can be used by the manager to create sub partitions within their
     * impelemntation.
     * @param _toPartition The partition the tokens are transferred to.
     * @param _to The address of the collateral manager.
     */
    function tokensToPartitionToValidate(
        bytes4, /* functionSig */
        bytes32 _toPartition,
        address, /* operator */
        address, /* from */
        address _to,
        uint256, /* value */
        bytes calldata, /* _data */
        bytes calldata /* operatorData */
    ) external override {
        require(msg.sender == address(amp), "Hook must be called by amp");

        (, , address toPartitionOwner) = PartitionUtils._splitPartition(_toPartition);

        require(
            _to == toPartitionOwner,
            "Transfers to this partition must be to the partitionOwner"
        );
        require(
            IAmp(amp).isCollateralManager(toPartitionOwner),
            "Partition owner is not a registered collateral manager"
        );
    }
}