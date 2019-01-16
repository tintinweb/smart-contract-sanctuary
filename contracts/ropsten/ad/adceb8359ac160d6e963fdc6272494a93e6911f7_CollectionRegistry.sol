pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

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
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/Utils.sol

library Utils {

    function generateId(bytes32 uniqueData, address creator) internal view returns (bytes8) {
        bytes memory seed = abi.encodePacked(creator, block.number, uniqueData);
        return bytes8(keccak256(seed));
    }
}

// File: contracts/SchemaRegistry.sol

contract SchemaRegistry {

    event Registration(address indexed registrar, bytes8 _id);
    event Unregistration(bytes8 indexed _id);

    struct Schema {
        address owner;
        string name;
    }
    mapping (bytes8 => Schema) public schemas;
    mapping (bytes32 => bool) public nameExists;

    function register(string _name) public {
        bytes32 hashedName = keccak256(abi.encodePacked(_name));
        require(!nameExists[hashedName], "The schema already exists!");

        bytes8 id = Utils.generateId(hashedName, msg.sender);
        Schema storage schema = schemas[id];

        schema.owner = msg.sender;
        schema.name = _name;
        nameExists[hashedName] = true;

        emit Registration(msg.sender, id);
    }
    
    function unregister(bytes8 _id) public {
        Schema storage schema = schemas[_id];
        require(schema.owner == msg.sender, "Only owner can do this");

        bytes32 hashedName = keccak256(abi.encodePacked(schema.name));
        nameExists[hashedName] = false;

        delete schemas[_id];
        emit Unregistration(_id);
    }

    function exists(bytes8 _id) public view returns (bool) {
        return (schemas[_id].owner != address(0));
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/AppRegistry.sol

contract AppRegistry is Ownable {
    using SafeMath for uint256;

    event Registered(string indexed name, bytes8 appId);

    struct App {
        string name;
        address owner;
    }

    mapping (bytes8 => App) public apps;
    mapping (bytes32 => bool) appNameExists;

    /**
     * @dev Creates a new application.
     */
    function register(string _name) public {
        bytes32 hashOfName = keccak256(abi.encodePacked(_name));
        require(!appNameExists[hashOfName], "App name already exists.");
        appNameExists[hashOfName] = true;

        bytes8 appId = Utils.generateId(hashOfName, msg.sender);
        apps[appId].name = _name;
        apps[appId].owner = msg.sender;

        emit Registered(_name, appId);
    }

    function transferAppOwner(bytes8 appId, address _newOwner) public {
        require(isOwner(appId, msg.sender), "only owner can transfer ownership");
        apps[appId].owner = _newOwner;
    }

    function isOwner(bytes8 _appId, address _owner) public view returns (bool) {
        return apps[_appId].owner == _owner;
    }

    function unregister(bytes8 _appId) public {
        require(exists(_appId), "App does not exist.");

        bytes32 hashOfName = keccak256(abi.encodePacked(apps[_appId].name));
        appNameExists[hashOfName] = false;
        delete apps[_appId];
    }

    function exists(bytes8 _appId) public view returns (bool) {
        return apps[_appId].owner != address(0x0);
    }

    function exists(string _appName) external view returns (bool) {
        bytes32 hashOfName = keccak256(abi.encodePacked(_appName));
        return appNameExists[hashOfName];
    }
}

// File: contracts/SparseMerkleTree.sol

// Based on https://rinkeby.etherscan.io/address/0x881544e0b2e02a79ad10b01eca51660889d5452b#code
contract SparseMerkleTree {

    bytes32 constant LEAF_INCLUDED = 0x0000000000000000000000000000000000000000000000000000000000000001;

    uint8 constant DEPTH = 64;
    bytes32[DEPTH + 1] public defaultHashes;

    constructor() public {
        // defaultHash[0] is being set to keccak256(uint256(0));
        defaultHashes[0] = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;
        setDefaultHashes(1, DEPTH);
    }

    function checkMembership(
        bytes32 root,
        uint64 leafID,
        bytes proof) public view returns (bool)
    {
        bytes32 computedHash = getRoot(leafID, proof);
        return (computedHash == root);
    }

    // first 64 bits of the proof are the 0/1 bits
    function getRoot(uint64 index, bytes proof) public view returns (bytes32) {
        require((proof.length - 8) % 32 == 0 && proof.length <= 2056);
        bytes32 proofElement;
        bytes32 computedHash = LEAF_INCLUDED;
        uint16 p = 8;
        uint64 proofBits;
        assembly {proofBits := div(mload(add(proof, 32)), exp(256, 24))}

        for (uint d = 0; d < DEPTH; d++ ) {
            if (proofBits % 2 == 0) { // check if last bit of proofBits is 0
                proofElement = defaultHashes[d];
            } else {
                p += 32;
                require(proof.length >= p);
                assembly { proofElement := mload(add(proof, p)) }
            }
            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            proofBits = proofBits / 2; // shift it right for next bit
            index = index / 2;
        }
        return computedHash;
    }

    function setDefaultHashes(uint8 startIndex, uint8 endIndex) private {
        for (uint8 i = startIndex; i <= endIndex; i ++) {
            defaultHashes[i] = keccak256(abi.encodePacked(defaultHashes[i-1], defaultHashes[i-1]));
        }
    }
}

// File: openzeppelin-solidity/contracts/cryptography/ECDSA.sol

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

// File: contracts/Accounts.sol

contract Accounts is Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    event SignUp(address indexed owner, bytes8 accountId);
    event TemporaryCreated(address indexed proxy, bytes32 indexed identityHash, bytes8 accountId);
    event Unlocked(bytes32 indexed identityHash, bytes8 indexed accountId, address newOwner);

    enum AccountStatus {
        NONE,
        TEMPORARY,
        CREATED
    }

    struct Account {
        address owner;
        AccountStatus status;

        address delegate;

        // password support using account proxy
        address proxy;
        address passwordProof;
    }

    mapping (bytes8 => Account) public accounts;
    mapping (address => bytes8) private passwordToAccount;
    mapping (address => bytes8) private addressToAccount;

    mapping (bytes32 => bytes8) public identityHashToAccount;

    uint256 public numberOfAccounts;

    function create() external {
        require(
            addressToAccount[msg.sender] == bytes8(0),
            "you can make only one account per one Ethereum Account");

        bytes8 accountId = Utils.generateId(bytes32(0), msg.sender);
        accounts[accountId].owner = msg.sender;
        accounts[accountId].status = AccountStatus.CREATED;

        addressToAccount[msg.sender] = accountId;
        emit SignUp(msg.sender, accountId);
    }

    function createTemporary(bytes32 identityHash) external {
        require(identityHashToAccount[identityHash] == bytes8(0), "account already exists");

        bytes8 accountId = Utils.generateId(identityHash, msg.sender);
        accounts[accountId].proxy = msg.sender;
        accounts[accountId].delegate = msg.sender;
        accounts[accountId].status = AccountStatus.TEMPORARY;

        identityHashToAccount[identityHash] = accountId;
        emit TemporaryCreated(msg.sender, identityHash, accountId);
    }

    function unlockTemporary(bytes32 identityPreimage, address newOwner, bytes passwordSignature) external {
        // check that keccak256(identityPreimage) == account.identityHash
        bytes32 identityHash = keccak256(abi.encodePacked(identityPreimage));
        bytes8 accountId = identityHashToAccount[identityHash];

        require(isTemporary(accountId), "it&#39;s not temporary account");
        Account storage account = accounts[accountId];

        require(
            msg.sender == account.proxy,
            "account must be unlocked through the account proxy"
        );
        require(
            addressToAccount[msg.sender] == bytes8(0),
            "you can make only one account per one Ethereum Account"
        );
        account.owner = newOwner;
        addressToAccount[newOwner] = accountId;

        bytes memory message = abi.encodePacked(identityPreimage, newOwner);
        setPassword(accountId, message, passwordSignature);

        account.status = AccountStatus.CREATED;
        emit Unlocked(identityHash, accountId, newOwner);
    }

    function createUsingProxy(address owner, bytes passwordSignature) external {
        require(
            addressToAccount[owner] == bytes8(0),
            "you can make only one account per one Ethereum Account");

        bytes8 accountId = Utils.generateId(bytes32(owner), msg.sender);
        accounts[accountId].owner = owner;
        accounts[accountId].proxy = msg.sender;
        accounts[accountId].delegate = msg.sender;
        accounts[accountId].status = AccountStatus.CREATED;

        bytes memory message = abi.encodePacked(owner);
        setPassword(accountId, message, passwordSignature);

        addressToAccount[owner] = accountId;
        emit SignUp(owner, accountId);
    }

    function setDelegate(address delegate) external {
        // the delegate and the proxy cannot modify delegate.
        // a delegate can be set only through the account owner&#39;s direct transaction.
        require(addressToAccount[msg.sender] != bytes8(0), "Account does not exist.");

        Account storage account = accounts[addressToAccount[msg.sender]];
        account.delegate = delegate;
    }

    function setPassword(bytes8 accountId, bytes memory message, bytes memory passwordSignature) internal {
        // user uses his/her own password to derive a sign key.
        // since ECRECOVER returns address (not public key itself),
        // we need to use address as a password proof.
        address passwordProof = keccak256(message).recover(passwordSignature);

        // password proof should be unique, since unique account ID is also used for key derivation
        require(passwordToAccount[passwordProof] == bytes8(0x0), "password proof is not unique");

        accounts[accountId].passwordProof = passwordProof;
        passwordToAccount[passwordProof] = accountId;
    }

    function getAccountId(address sender) public view returns (bytes8) {
        bytes8 accountId = addressToAccount[sender];
        require(accounts[accountId].status != AccountStatus.NONE, "unknown address");
        return accountId;
    }

    function getAccountIdFromSignature(bytes32 messageHash, bytes signature) public view returns (bytes8) {
        address passwordProof = messageHash.recover(signature);
        bytes8 accountId = passwordToAccount[passwordProof];

        if (accounts[accountId].status == AccountStatus.NONE) {
            revert("password mismatch");
        }
        return accountId;
    }

    function isTemporary(bytes8 accountId) public view returns (bool) {
        return accounts[accountId].status == AccountStatus.TEMPORARY;
    }

    function isDelegateOf(address sender, bytes8 accountId) public view returns (bool) {
        return accounts[accountId].delegate == sender;
    }
}

// File: contracts/CollectionRegistry.sol

contract CollectionRegistry {
    using SafeMath for uint256;

    event Registration(address indexed registrar, bytes8 indexed appId, bytes8 collectionId);
    event Unregistration(bytes8 indexed collectionId, bytes8 indexed appId);
    event Allowed(bytes8 indexed collectionId, bytes8 indexed userId);
    event Denied(bytes8 indexed collectionId, bytes8 indexed userId);

    struct Collection {
        bytes8 appId;
        bytes8 schemaId;
        IncentivePolicy policy;
        mapping (bytes8 => Auth) dataCollectionOf;
    }

    struct IncentivePolicy {
        uint256 self;
        uint256 owner;
    }

    struct Auth {
        bool isAllowed;
        uint256 authorizedAt;
    }

    mapping (bytes8 => Collection) collections;

    Accounts accounts;
    AppRegistry apps;
    SchemaRegistry schemas;

    constructor(Accounts _accounts, AppRegistry _appReg, SchemaRegistry _schemaReg) public {
        apps = _appReg;
        schemas = _schemaReg;
        accounts = _accounts;
    }

    function register(bytes8 _appId, bytes8 _schemaId, uint256 _ratio) public {
        require(apps.isOwner(_appId, msg.sender), "only owner can register collection.");
        require(schemas.exists(_schemaId), "given schema does not exist");

        bytes32 unique = keccak256(abi.encodePacked(_appId, _schemaId, _ratio));
        bytes8 collectionId = Utils.generateId(unique, msg.sender);

        Collection storage collection = collections[collectionId];
        collection.appId = _appId;
        collection.schemaId = _schemaId;

        // calculate with ETH. ex) 35ETH == 0.35%
        collection.policy = IncentivePolicy({
            self: _ratio,
            owner: uint256(100 ether).sub(_ratio)
        });

        emit Registration(msg.sender, _appId, collectionId);
    }

    function unregister(bytes8 _id) public {
        require(exists(_id), "collection does not exist");

        bytes8 appId = collections[_id].appId;
        require(apps.isOwner(appId, msg.sender), "only owner can register collection.");

        delete collections[_id];
        emit Unregistration(_id, appId);
    }

    function get(bytes8 _id) public view returns (bytes8 appId, bytes8 schemaId, uint256 incentiveRatioSelf) {
        require(exists(_id), "collection does not exist");

        appId = collections[_id].appId;
        schemaId = collections[_id].schemaId;
        incentiveRatioSelf = collections[_id].policy.self;
    }

    function allow(bytes8 _id) public {
        bytes8 userId = accounts.getAccountId(msg.sender);
        modifyAuth(_id, userId, true);

        emit Allowed(_id, userId);
    }

    function allowByDelegate(bytes8 _id, bytes8 _userId) public {
        require(
            accounts.isDelegateOf(msg.sender, _userId),
            "only the delegate can modify.");

        modifyAuth(_id, _userId, true);
        emit Allowed(_id, _userId);
    }

    function allowByPassword(bytes8 _id, bytes passwordSignature) public {
        bytes32 inputHash = keccak256(abi.encodePacked(_id));
        bytes8 userId = accounts.getAccountIdFromSignature(inputHash, passwordSignature);

        modifyAuth(_id, userId, true);
        emit Allowed(_id, userId);
    }

    function deny(bytes8 _id) public {
        bytes8 userId = accounts.getAccountId(msg.sender);

        modifyAuth(_id, userId, false);
        emit Denied(_id, userId);
    }

    function denyByDelegate(bytes8 _id, bytes8 _userId) public {
        require(
            accounts.isDelegateOf(msg.sender, _userId),
            "only the delegate can modify.");

        modifyAuth(_id, _userId, false);
        emit Denied(_id, _userId);
    }

    function denyByPassword(bytes8 _id, bytes passwordSignature) public {
        bytes32 inputHash = keccak256(abi.encodePacked(_id));
        bytes8 userId = accounts.getAccountIdFromSignature(inputHash, passwordSignature);

        modifyAuth(_id, userId, false);
        emit Denied(_id, userId);
    }

    function modifyAuth(bytes8 _id, bytes8 _userId, bool _allow) internal {
        require(exists(_id), "Collection does not exist.");
        Auth storage auth = collections[_id].dataCollectionOf[_userId];

        if (auth.authorizedAt != 0 && accounts.isTemporary(_userId)) {
            // temporary account can&#39;t change DAuth settings that already set.
            revert("The account is currently locked.");
        }

        auth.isAllowed = _allow;
        auth.authorizedAt = block.number;
    }

    function exists(bytes8 _id) public view returns (bool) {
        return (collections[_id].appId != bytes8(0x0));
    }

    function isCollectionAllowed(bytes8 collectionId, bytes8 user) public view returns (bool) {
        return isCollectionAllowedAt(collectionId, user, block.number);
    }

    function isCollectionAllowedAt(bytes8 collectionId, bytes8 user, uint256 blockNumber) public view returns (bool) {
        return collections[collectionId].dataCollectionOf[user].isAllowed
            && collections[collectionId].dataCollectionOf[user].authorizedAt < blockNumber;
    }
}