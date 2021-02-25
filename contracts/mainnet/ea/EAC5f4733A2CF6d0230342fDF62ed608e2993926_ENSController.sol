// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../common/access/Guarded.sol";
import "../common/lifecycle/Initializable.sol";
import "../common/typedData/TypedDataContainer.sol";
import "../gateway/GatewayRecipient.sol";
import "./ENSRegistry.sol";


/**
 * @title ENS controller
 *
 * @notice ENS subnode registrar
 *
 * @dev The process of adding root node consists of 3 steps:
 * 1. `submitNode` - should be called from ENS node owner,
 * 2. Change ENS node owner in ENS registry to ENS controller,
 * 3. `verifyNode` - should be called from previous ENS node owner,
 *
 * To register sub node, `msg.sender` need to send valid signature from one of guardian key.
 * Once registration is complete `msg.sender` becoming both node owner and `addr` record value.
 *
 * After registration sub node cannot be replaced.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract ENSController is Guarded, Initializable, TypedDataContainer, GatewayRecipient {
  struct Node {
    address addr;
    address owner;
  }

  struct SubNodeRegistration {
    address account;
    bytes32 node;
    bytes32 label;
  }

  bytes32 private constant SUB_NODE_REGISTRATION_TYPE_HASH = keccak256(
    "SubNodeRegistration(address account,bytes32 node,bytes32 label)"
  );

  ENSRegistry public registry;

  mapping(bytes32 => Node) private nodes;

  // events

  /**
   * @dev Emitted when the address field in node resolver is changed
   * @param node node name hash
   * @param addr new address
   */
  event AddrChanged(
    bytes32 indexed node,
    address addr
  );

  /**
   * @dev Emitted when new node is submitted
   * @param node node name hash
   * @param owner owner address
   */
  event NodeSubmitted(
    bytes32 node,
    address owner
  );

  /**
   * @dev Emitted when the existing owner is verified
   * @param node node name hash
   */
  event NodeVerified(
    bytes32 node
  );

  /**
   * @dev Emitted when new node is released
   * @param node node name hash
   * @param owner owner address
   */
  event NodeReleased(
    bytes32 node,
    address owner
  );

  /**
   * @dev Emitted when ENS registry address is changed
   * @param registry registry address
   */
  event RegistryChanged(
    address registry
  );

  /**
   * @dev Public constructor
   */
  constructor() public Guarded() Initializable() {}

  // external functions

  /**
   * @notice Initializes `ENSController` contract
   * @param registry_ ENS registry address
   * @param gateway_ gateway address
   * @param typedDataDomainNameHash hash of a typed data domain name
   * @param typedDataDomainVersionHash hash of a typed data domain version
   * @param typedDataDomainSalt typed data salt
   */
  function initialize(
    ENSRegistry registry_,
    address[] calldata guardians_,
    address gateway_,
    bytes32 typedDataDomainNameHash,
    bytes32 typedDataDomainVersionHash,
    bytes32 typedDataDomainSalt
  )
    external
    onlyInitializer
  {
    require(
      address(registry_) != address(0),
      "ENSController: cannot set 0x0 registry"
    );

    registry = registry_;

    // Guarded
    _initializeGuarded(guardians_);

    // GatewayRecipient
    _initializeGatewayRecipient(gateway_);

    // TypedDataContainer
    _initializeTypedDataContainer(
      typedDataDomainNameHash,
      typedDataDomainVersionHash,
      typedDataDomainSalt
    );
  }

  /**
   * @notice Sets registry
   * @param registry_ registry address
   */
  function setRegistry(
    ENSRegistry registry_
  )
    external
    onlyGuardian
  {
    require(
      address(registry_) != address(0),
      "ENSController: cannot set 0x0 registry"
    );

    require(
      registry_ != registry,
      "ENSController: registry already set"
    );

    registry = registry_;

    emit RegistryChanged(
      address(registry)
    );
  }

  /**
   * @notice Submits node
   * @dev Should be called from the current ENS node owner
   * @param node node name hash
   */
  function submitNode(
    bytes32 node
  )
    external
  {
    address owner = _getContextAccount();

    require(
      nodes[node].addr == address(0),
      "ENSController: node already exists"
    );

    require(
      nodes[node].owner == address(0),
      "ENSController: node already submitted"
    );

    require(
      registry.owner(node) == owner,
      "ENSController: invalid ens node owner"
    );

    nodes[node].owner = owner;

    emit NodeSubmitted(node, owner);
  }

  /**
   * @notice Verifies node
   * @dev Should be called from the previous ENS node owner
   * @param node node name hash
   */
  function verifyNode(
    bytes32 node
  )
    external
  {
    address owner = _getContextAccount();

    require(
      nodes[node].addr == address(0),
      "ENSController: node already exists"
    );

    require(
      nodes[node].owner == owner,
      "ENSController: invalid node owner"
    );

    require(
      registry.owner(node) == address(this),
      "ENSController: invalid ens node owner"
    );

    nodes[node].addr = address(this);

    registry.setResolver(node, address(this));

    emit NodeVerified(node);
  }

  /**
   * @notice Releases node
   * @dev Should be called from the previous ENS node owner
   * @param node node name hash
   */
  function releaseNode(
    bytes32 node
  )
    external
  {
    address owner = _getContextAccount();

    require(
      nodes[node].addr == address(this),
      "ENSController: node doesn't exist"
    );

    require(
      nodes[node].owner == owner,
      "ENSController: invalid node owner"
    );

    registry.setOwner(node, owner);

    delete nodes[node].addr;
    delete nodes[node].owner;

    emit NodeReleased(node, owner);
  }

  /**
   * @notice Sets address
   * @dev Used in address resolver
   * @param node node name hash
   * @param addr address
   */
  function setAddr(
    bytes32 node,
    address addr
  )
    external
  {
    require(
      nodes[node].addr == _getContextAccount(),
      "ENSController: caller is not the node owner"
    );

    nodes[node].addr = addr;

    emit AddrChanged(node, addr);
  }

  /**
   * @notice Sync address
   * @param node node name hash
   */
  function syncAddr(
    bytes32 node
  )
    external
  {
    address account = _getContextAccount();

    require(
      account == registry.owner(node),
      "ENSController: caller is not the node owner"
    );

    require(
      registry.resolver(node) == address(this),
      "ENSController: invalid node resolver"
    );

    require(
      nodes[node].addr == address(0),
      "ENSController: node already in sync"
    );

    nodes[node].addr = account;

    emit AddrChanged(node, account);
  }

  /**
   * @notice Registers sub node
   * @param node node name hash
   * @param label label hash
   * @param guardianSignature guardian signature
   */
  function registerSubNode(
    bytes32 node,
    bytes32 label,
    bytes calldata guardianSignature
  )
    external
  {
    address account = _getContextAccount();

    bytes32 messageHash = _hashPrimaryTypedData(
      _hashTypedData(
        account,
        node,
        label
      )
    );

    require(
      _verifyGuardianSignature(messageHash, guardianSignature),
      "ENSController: invalid guardian signature"
    );

    bytes32 subNode = keccak256(
      abi.encodePacked(
        node,
        label
      )
    );

    require(
      nodes[node].addr == address(this),
      "ENSController: invalid node"
    );

    require(
      nodes[subNode].addr == address(0),
      "ENSController: label already taken"
    );

    nodes[subNode].addr = account;

    registry.setSubnodeOwner(node, label, address(this));
    registry.setResolver(subNode, address(this));
    registry.setOwner(subNode, account);

    emit AddrChanged(subNode, account);
  }

  // external functions (views)

  /**
   * @notice Gets address
   * @dev Used in address resolver
   * @param node node name hash
   * @return node address
   */
  function addr(
    bytes32 node
  )
    external
    view
    returns (address)
  {
    return nodes[node].addr;
  }
  /**
   * @notice Gets node
   * @param node node name hash
   */
  function getNode(
    bytes32 node
  )
    external
    view
    returns (address nodeAddr, address nodeOwner)
  {
    return (nodes[node].addr, nodes[node].owner);
  }

  // external functions (pure)

  /**
   * @notice Checks if contract supports interface
   * @param interfaceID method signature
   * @return true when contract supports interface
   */
  function supportsInterface(
    bytes4 interfaceID
  )
    external
    pure
    returns (bool)
  {
    return (
      /// @dev bytes4(keccak256('supportsInterface(bytes4)'));
      interfaceID == 0x01ffc9a7 ||
      /// @dev bytes4(keccak256('addr(bytes32)'));
      interfaceID == 0x3b3b57de
    );
  }

  // public functions (views)

  /**
   * @notice Hashes `SubNodeRegistration` typed data
   * @param subNodeRegistration struct
   * @return hash
   */
  function hashSubNodeRegistration(
    SubNodeRegistration memory subNodeRegistration
  )
    public
    view
    returns (bytes32)
  {
    return _hashPrimaryTypedData(
      _hashTypedData(
        subNodeRegistration.account,
        subNodeRegistration.node,
        subNodeRegistration.label
      )
    );
  }

  // private functions (pure)

  function _hashTypedData(
    address account,
    bytes32 node,
    bytes32 label
  )
    private
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(
      SUB_NODE_REGISTRATION_TYPE_HASH,
      account,
      node,
      label
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../libs/SignatureLib.sol";


/**
 * @title Guarded
 *
 * @dev Contract module which provides a guardian-type control mechanism.
 * It allows key accounts to have guardians and restricts specific methods to be accessible by guardians only.
 *
 * Each guardian account can remove other guardians
 *
 * Use `_initializeGuarded` to initialize the contract
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Guarded {
  using SignatureLib for bytes32;

  mapping(address => bool) private guardians;

  // events

  /**
   * @dev Emitted when a new guardian is added
   * @param sender sender address
   * @param guardian guardian address
   */
  event GuardianAdded(
    address sender,
    address guardian
  );

  /**
   * @dev Emitted when the existing guardian is removed
   * @param sender sender address
   * @param guardian guardian address
   */
  event GuardianRemoved(
    address sender,
    address guardian
  );

  // modifiers

  /**
   * @dev Throws if tx.origin is not a guardian account
   */
  modifier onlyGuardian() {
    require(
      // solhint-disable-next-line avoid-tx-origin
      guardians[tx.origin],
      "Guarded: tx.origin is not the guardian"
    );

    _;
  }

  /**
   * @dev Internal constructor
   */
  constructor() internal {}

  // external functions

  /**
   * @notice Adds a new guardian
   * @param guardian guardian address
   */
  function addGuardian(
    address guardian
  )
    external
    onlyGuardian
  {
    _addGuardian(guardian);
  }

  /**
   * @notice Removes the existing guardian
   * @param guardian guardian address
   */
  function removeGuardian(
    address guardian
  )
    external
    onlyGuardian
  {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin != guardian,
      "Guarded: cannot remove self"
    );

    require(
      guardians[guardian],
      "Guarded: guardian doesn't exist"
    );

    guardians[guardian] = false;

    emit GuardianRemoved(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin,
      guardian
    );
  }

  // external functions (views)

  /**
   * @notice Check if guardian exists
   * @param guardian guardian address
   * @return true when guardian exists
   */
  function isGuardian(
    address guardian
  )
    external
    view
    returns (bool)
  {
    return guardians[guardian];
  }

  /**
   * @notice Verifies guardian signature
   * @param messageHash message hash
   * @param signature signature
   * @return true on correct guardian signature
   */
  function verifyGuardianSignature(
    bytes32 messageHash,
    bytes calldata signature
  )
    external
    view
    returns (bool)
  {
    return _verifyGuardianSignature(
      messageHash,
      signature
    );
  }

  // internal functions

  /**
   * @notice Initializes `Guarded` contract
   * @dev If `guardians_` array is empty `tx.origin` is added as guardian account
   * @param guardians_ array of guardians addresses
   */
  function _initializeGuarded(
    address[] memory guardians_
  )
    internal
  {
    if (guardians_.length == 0) {
      // solhint-disable-next-line avoid-tx-origin
      _addGuardian(tx.origin);
    } else {
      uint guardiansLen = guardians_.length;
      for (uint i = 0; i < guardiansLen; i++) {
        _addGuardian(guardians_[i]);
      }
    }
  }


  // internal functions (views)

  function _verifyGuardianSignature(
    bytes32 messageHash,
    bytes memory signature
  )
    internal
    view
    returns (bool)
  {
    address guardian = messageHash.recoverAddress(signature);

    return guardians[guardian];
  }

  // private functions

  function _addGuardian(
    address guardian
  )
    private
  {
    require(
      guardian != address(0),
      "Guarded: cannot add 0x0 guardian"
    );

    require(
      !guardians[guardian],
      "Guarded: guardian already exists"
    );

    guardians[guardian] = true;

    emit GuardianAdded(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin,
      guardian
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Initializable
 *
 * @dev Contract module which provides access control mechanism, where
 * there is the initializer account that can be granted exclusive access to
 * specific functions.
 *
 * The initializer account will be tx.origin during contract deployment and will be removed on first use.
 * Use `onlyInitializer` modifier on contract initialize process.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Initializable {
  address private initializer;

  // events

  /**
   * @dev Emitted after `onlyInitializer`
   * @param initializer initializer address
   */
  event Initialized(
    address initializer
  );

  // modifiers

  /**
   * @dev Throws if tx.origin is not the initializer
   */
  modifier onlyInitializer() {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin == initializer,
      "Initializable: tx.origin is not the initializer"
    );

    /// @dev removes initializer
    initializer = address(0);

    _;

    emit Initialized(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin
    );
  }

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    // solhint-disable-next-line avoid-tx-origin
    initializer = tx.origin;
  }

   // external functions (views)

  /**
   * @notice Check if contract is initialized
   * @return true when contract is initialized
   */
  function isInitialized()
    external
    view
    returns (bool)
  {
    return initializer == address(0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Typed data container
 *
 * @dev EIP-712 is used across whole repository.
 *
 * Use `_initializeTypedDataContainer` to initialize the contract
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract TypedDataContainer {
  string private constant TYPED_DATA_PREFIX = "\x19\x01";
  bytes32 private constant TYPED_DATA_DOMAIN_TYPE_HASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
  );

  bytes32 public typedDataDomainSeparator;

  /**
   * @dev internal constructor
   */
  constructor() internal {}

  // internal functions

  /**
   * @notice Initializes `TypedDataContainer` contract
   * @param domainNameHash hash of a domain name
   * @param domainVersionHash hash of a domain version
   * @param domainSalt domain salt
   */
  function _initializeTypedDataContainer(
    bytes32 domainNameHash,
    bytes32 domainVersionHash,
    bytes32 domainSalt
  )
    internal
  {
    uint256 chainId;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }

    typedDataDomainSeparator = keccak256(abi.encode(
        TYPED_DATA_DOMAIN_TYPE_HASH,
        domainNameHash,
        domainVersionHash,
        chainId,
        address(this),
        domainSalt
    ));
  }

  // internal functions (views)

  /**
   * @notice Hashes primary typed data
   * @param dataHash hash of the data
   */
  function _hashPrimaryTypedData(
    bytes32 dataHash
  )
    internal
    view
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(
      TYPED_DATA_PREFIX,
      typedDataDomainSeparator,
      dataHash
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../common/libs/BytesLib.sol";


/**
 * @title Gateway recipient
 *
 * @notice Gateway target contract
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract GatewayRecipient {
  using BytesLib for bytes;

  address public gateway;

  /**
   * @dev internal constructor
   */
  constructor() internal {}

  // internal functions

  /**
   * @notice Initializes `GatewayRecipient` contract
   * @param gateway_ `Gateway` contract address
   */
  function _initializeGatewayRecipient(
    address gateway_
  )
    internal
  {
    gateway = gateway_;
  }

  // internal functions (views)

  /**
   * @notice Gets gateway context account
   * @return context account address
   */
  function _getContextAccount()
    internal
    view
    returns (address)
  {
    return _getContextAddress(40);
  }

  /**
   * @notice Gets gateway context sender
   * @return context sender address
   */
  function _getContextSender()
    internal
    view
    returns (address)
  {
    return _getContextAddress(20);
  }

  /**
   * @notice Gets gateway context data
   * @return context data
   */
  function _getContextData()
    internal
    view
    returns (bytes calldata)
  {
    bytes calldata result;

    if (_isGatewaySender()) {
      result = msg.data[:msg.data.length - 40];
    } else {
      result = msg.data;
    }

    return result;
  }

  // private functions (views)

  function _getContextAddress(
    uint256 offset
  )
    private
    view
    returns (address)
  {
    address result = address(0);

    if (_isGatewaySender()) {
      uint from = msg.data.length - offset;
      result = bytes(msg.data[from:from + 20]).toAddress();
    } else {
      result = msg.sender;
    }

    return result;
  }

  function _isGatewaySender()
    private
    view
    returns (bool)
  {
    bool result;

    if (msg.sender == gateway) {
      require(
        msg.data.length >= 44,
        "GatewayRecipient: invalid msg.data"
      );

      result = true;
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title ENS registry
 *
 * @dev Base on https://github.com/ensdomains/ens/blob/v0.2.2/contracts/ENSRegistry.sol
 */
contract ENSRegistry {
  struct Record {
    address owner;
    address resolver;
    uint64 ttl;
  }

  mapping(bytes32 => Record) private records;

  // events

  event NewOwner(
    bytes32 indexed node,
    bytes32 indexed label,
    address owner
  );

  event Transfer(
    bytes32 indexed node,
    address owner
  );

  event NewResolver(
    bytes32 indexed node,
    address resolver
  );

  event NewTTL(
    bytes32 indexed node,
    uint64 ttl
  );

  // modifiers

  modifier onlyNodeOwner(
    bytes32 node
  ) {
    require(
      records[node].owner == msg.sender,
      "ENSRegistry: msg.sender is not the node owner"
    );

    _;
  }

  /**
   * @dev public constructor
   */
  constructor()
    public
  {
    // solhint-disable-next-line avoid-tx-origin
    records[0x0].owner = tx.origin;
  }

  // external functions

  function setOwner(
    bytes32 node,
    address owner
  )
    external
    onlyNodeOwner(node)
  {
    records[node].owner = owner;

    emit Transfer(node, owner);
  }

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  )
    external
    onlyNodeOwner(node)
  {
    bytes32 subNode = keccak256(
      abi.encodePacked(
        node,
        label
      )
    );

    records[subNode].owner = owner;

    emit NewOwner(node, label, owner);
  }

  function setResolver(
    bytes32 node,
    address resolver
  )
    external
    onlyNodeOwner(node)
  {
    records[node].resolver = resolver;

    emit NewResolver(node, resolver);
  }

  function setTTL(
    bytes32 node,
    uint64 ttl
  )
    external
    onlyNodeOwner(node)
  {
    records[node].ttl = ttl;

    emit NewTTL(node, ttl);
  }

  // external functions (views)

  function owner(
    bytes32 node
  )
    external
    view
    returns (address)
  {
    return records[node].owner;
  }

  function resolver(
    bytes32 node
  )
    external
    view
    returns (address)
  {
    return records[node].resolver;
  }

  function ttl(
    bytes32 node
  )
    external
    view
    returns (uint64)
  {
    return records[node].ttl;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Signature library
 *
 * @dev Based on
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/cryptography/ECDSA.sol#L26
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/utils/Strings.sol#L12
 */
library SignatureLib {
  function recoverAddress(
    bytes32 messageHash,
    bytes memory signature
  )
    internal
    pure
    returns (address)
  {
    address result = address(0);

    if (signature.length == 65) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      // solhint-disable-next-line no-inline-assembly
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }

      if (v < 27) {
        v += 27;
      }

      if (v == 27 || v == 28) {
        result = ecrecover(messageHash, v, r, s);
      }
    }

    return result;
  }

  function toEthereumSignedMessageHash(
    bytes memory message
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n",
      _uintToString(message.length),
      abi.encodePacked(message)
    ));
  }

  function _uintToString(
    uint num
  )
    private
    pure
    returns (string memory)
  {
    if (num == 0) {
      return "0";
    } else if (num == 32) {
      return "32";
    }

    uint i = num;
    uint j = num;

    uint len;

    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory result = new bytes(len);

    uint k = len - 1;

    while (i != 0) {
      result[k--] = byte(uint8(48 + i % 10));
      i /= 10;
    }

    return string(result);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Bytes library
 *
 * @author Stanisław Głogowski <[email protected]>
 */
library BytesLib {
  /**
   * @notice Converts bytes to address
   * @param data data
   * @return address
   */
  function toAddress(
    bytes memory data
  )
    internal
    pure
    returns (address)
  {
    address result;

    require(
      data.length == 20,
      "BytesLib: invalid data length"
    );

    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := div(mload(add(data, 0x20)), 0x1000000000000000000000000)
    }

    return result;
  }
}