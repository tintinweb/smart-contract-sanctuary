// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Whitelist.sol";
import "../SystemContext.sol";

// TODO add support for contract ACLs, limit access to whitelist and creation of new contract instances
/**
 * @dev This contract enables creation of assets smart contract instances
 */
contract ContractFactory is Whitelist, SystemContext {

    event CreatedContractInstance(bytes32 contractName, address contractAddress);

    ContractFactory internal parentFactory;

    constructor(IRegistry contractRegistry, IAuthProvider authProvider, address parentFactory_) SystemContext(contractRegistry, authProvider) {
        parentFactory = ContractFactory(parentFactory_);
    }

    function whitelistContractChecksum(bytes32 checksum) external returns (bool) {
        _addToWhitelist(checksum);
        return true;
    }

    function removeWhitelistedContractChecksum(bytes32 checksum) external returns (bool) {
        _removeFromWhitelist(checksum);
        return true;
    }

    /**
     * @dev Creates contract instance for whitelisted byteCode
     * @param contractName contract name
     * @param bytecode contract bytecode
     * @param constructorParams encoded constructor params
     */
    function createContractInstance(string memory contractName, bytes memory bytecode, bytes memory constructorParams) external returns (bytes32) {
        bytes32 _checksum = keccak256(bytecode);
        require(isChecksumWhitelisted(_checksum), "Contract is not whitelisted. Check contract bytecode");

        bytes32 _contractNameHash = keccak256(abi.encode(contractName));

        bytes memory creationBytecode = abi.encodePacked(bytecode, constructorParams);

        address addr;
        assembly {
            addr := create(0, add(creationBytecode, 0x20), mload(creationBytecode))
        }

        require(isContract(addr), "Contract was not been deployed. Check contract bytecode and contract params");

        IRegistry _registryContract = _getRegistryContract();

        // TODO implement resolver, currently resolver is just an address of deployed contract
        emit CreatedContractInstance(_contractNameHash, addr);
        _registryContract.setRecord(_contractNameHash, msg.sender, addr);

        return _contractNameHash;
    }

    /**
     * @dev Returns True if provided address is a contract
     * @param account Prospective contract address
     * @return True if there is a contract behind the provided address
     */
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Returns true if contract checksum is whitelisted
     * @param checksum The user address
     */
    function isChecksumWhitelisted(bytes32 checksum) public override view returns (bool) {
        if (address(parentFactory) == address(0)) {
            return super.isChecksumWhitelisted(checksum);
        }

        return super.isChecksumWhitelisted(checksum) || parentFactory.isChecksumWhitelisted(checksum);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Whitelist {

    /**
    * @dev Emitted when a contract checksum is added to the whitelist
    */
    event Whitelisted(bytes32 checksum);

    /**
    * @dev Emitted when a smart contract checksum is removed from the whitelist
    */
    event RemovedFromWhitelist(bytes32 checksum);

    mapping(bytes32 => bool) private whitelisted;

    /**
    * @dev Adds contract checksum to the whitelist.
    * @param checksum Checksum of the smart contract
    */
    function _addToWhitelist(bytes32 checksum) internal {
        require(!whitelisted[checksum], "Contract checksum is already whitelisted");
        whitelisted[checksum] = true;

        emit Whitelisted(checksum);
    }

    /**
     * @dev Removes contract from the whitelist.
     * @param checksum of the smart contract
     */
    function _removeFromWhitelist(bytes32 checksum) internal {
        require(whitelisted[checksum], "Contract checksum not found in whitelist");
        whitelisted[checksum] = false;

        emit RemovedFromWhitelist(checksum);
    }

    /**
     * @dev Returns true if contract checksum is whitelisted
     * @param checksum The user address
     */
    function isChecksumWhitelisted(bytes32 checksum) public virtual view returns (bool) {
        return whitelisted[checksum];
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IRegistry.sol";
import "./interfaces/IAuthProvider.sol";

/**
 * @dev This contract stores information about system contract names
 * and Registry Contract address. This contract should be inherited by
 * any contract in our network, which should call other contracts by their
 * identifiers
 *
 * Provides shared context for all contracts in our network
 */

contract SystemContext {
    // system contracts
    bytes32 public constant AUTH_CONTRACT = keccak256("AUTH_CONTRACT");

    IRegistry internal _registry;
    IAuthProvider internal _authProvider;

    constructor (IRegistry registry, IAuthProvider authProvider) {
        _registry = registry;
        _authProvider = authProvider;
    }

    function _getContractAddress(bytes32 contractName) internal view returns (address) {
        return _registry.resolver(contractName);
    }

    function _getAuthContract() internal view returns (IAuthProvider) {
        return IAuthProvider(_getContractAddress(AUTH_CONTRACT));
    }

    function _getRegistryContract() internal view returns (IRegistry) {
        return _registry;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IRegistry {

    // Logged when new record is created.
    event NewRecord(bytes32 indexed node, address owner, address resolver);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);


    function setRecord(bytes32 node_, address owner_, address resolver_) external;
    function setResolver(bytes32 node_, address resolver_) external;
    function setOwner(bytes32 node_, address owner_) external;
    function owner(bytes32 node_) external view returns (address);
    function resolver(bytes32 node_) external view returns (address);
    function recordExists(bytes32 node_) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IAuthProvider {
    function isAuthorized(bytes32 role, address account) external returns (bool);
    function isGameOwner(address account) external returns (bool);
    function isSystemOwner(address account) external returns (bool);
}