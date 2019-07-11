/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
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
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contract-registry/contracts/interfaces/IRegistrable.sol

pragma solidity 0.5.0;

interface IRegistrable {
  function contractName() external view returns (bytes32);
  function register() external returns (bool);
  function isRegistered() external view returns (bool);
  function unregister(IRegistrable _newInstance) external;
}

// File: contract-registry/contracts/interfaces/IContractRegistry.sol

pragma solidity 0.5.0;


interface IContractRegistry {
  function add(IRegistrable) external returns(bool);
  function update(IRegistrable) external returns(bool);

  function contractByName(bytes32) external view returns (address);
}

// File: contract-registry/contracts/storage/interfaces/IStorageBase.sol

pragma solidity 0.5.0;

interface IStorageBase {
  function initStorageOwner(address) external returns (bool);
  function switchOwnerTo(address) external returns (bool);
  function kill() external returns (bool);

  function storageOwner() external returns (address);
}

// File: contract-registry/contracts/storageStrategy/interfaces/IStorageStrategy.sol

pragma solidity 0.5.0;


interface IStorageStrategy {
  function getAllStorages() external view returns (IStorageBase[] memory);
}

// File: contract-registry/contracts/helpers/Suicidal.sol

pragma solidity 0.5.0;

contract Suicidal {

  address payable private _payableOwner;

  event LogSuicide(
    uint256 balance,
    address indexed balanceReceiver
  );

  constructor () public {
    _payableOwner = msg.sender;
  }

  function _suicide()
  internal {
    emit LogSuicide(address(this).balance, _payableOwner);
    selfdestruct(_payableOwner);
  }
}

// File: contract-registry/contracts/interfaces/Registrable.sol

pragma solidity 0.5.0;




contract Registrable is IRegistrable, Suicidal {

  IContractRegistry public contractRegistry;

  bool private _isRegistered;

  modifier needContractRegistrySetup {
    require(address(contractRegistry) != address(0x0), "[needContractRegistrySetup] contractRegistry address is empty");
    require(_isRegistered, "[needContractRegistrySetup] contract is not registered");
    _;
  }

  modifier onlyFromContractRegistry() {
    require(msg.sender == address(contractRegistry), "[onlyFromContractRegistry] access denied");
    _;
  }

  modifier onlyFromContract(bytes32 _name) {
    require(_name != bytes32(0), "contract name is not set");
    require(msg.sender == contractRegistry.contractByName(_name), "[onlyFromContract...] access denied");
    _;
  }

  event LogRegister(address indexed executor, address indexed registered, bool isRegistered);

  constructor (address _contractRegistry) public {
    require(address(_contractRegistry) != address(0x0), "_contractRegistry address is empty");

    contractRegistry = IContractRegistry(_contractRegistry);
  }

  function isRegistered() external view returns (bool) {
    return _isRegistered;
  }

  function register()
  external
  onlyFromContractRegistry
  returns (bool) {
    return _register();
  }

  function _register()
  internal
  returns (bool) {
    require(!_isRegistered, "i&#39;m already register");

    _isRegistered = true;
    emit LogRegister(msg.sender, address(this), true);

    return true;
  }

  function unregister(IRegistrable _newInstance)
  external
  onlyFromContractRegistry {
    _unregister(_newInstance);

    /// @dev it is important that contract be killed once it is replaced by new one,
    ///      so there be no case when we allow to use old methods (including getters)
    _suicide();
  }

  function _unregister(IRegistrable _newInstance)
  internal
  returns (bool) {
    require(_isRegistered, "i&#39;m not even register");
    require(address(_newInstance) != address(0x0), "[unregister] _newInstance address is empty");
    require(address(_newInstance) != address(this), "[unregister] _newInstance is me");

    _isRegistered = false;
    emit LogRegister(msg.sender, address(this), false);

    return true;
  }
}

// File: contract-registry/contracts/storageStrategy/SingleStorageStrategy.sol

pragma solidity 0.5.0;




contract SingleStorageStrategy is IStorageStrategy, Suicidal {

  IStorageBase public singleStorage;

  event LogDetachFromStorage(
    address indexed executor,
    address indexed newStorageOwner
  );

  event LogNewStorage(IStorageBase indexed storageAddress);

  constructor (IStorageBase _storage) public {
    require(address(_storage) != address(0x0), "storage can&#39;t be empty");
    singleStorage = _storage;
  }

  function getAllStorages()
  external
  view
  returns (IStorageBase[] memory) {
    return _getAllStorages();
  }

  function _getAllStorages()
  private
  view
  returns (IStorageBase[] memory) {
    IStorageBase[] memory list = new IStorageBase[](1);
    list[0] = singleStorage;
    return list;
  }

  function detachFromStorage(address _newStorageOwner)
  internal {
    require(singleStorage.switchOwnerTo(_newStorageOwner), "[detachFromStorage] failed");

    emit LogDetachFromStorage(msg.sender, _newStorageOwner);

    _suicide();
  }
}

// File: contract-registry/contracts/interfaces/RegistrableWithSingleStorage.sol

pragma solidity 0.5.0;





contract RegistrableWithSingleStorage is Registrable, SingleStorageStrategy {

  constructor (address _contractRegistry, IStorageBase _storage)
  public
  Registrable(_contractRegistry)
  SingleStorageStrategy (_storage) {}

  function register()
  external
  onlyFromContractRegistry
  returns (bool) {
    require(address(singleStorage) != address(0x0), "[register] contract do not have storage attached");

    return _register();
  }

  function unregister(IRegistrable _newInstance)
  external
  onlyFromContractRegistry {
    _unregister(_newInstance);

    IStorageStrategy newInstance = IStorageStrategy(address(_newInstance));
    detachFromStorage(address(newInstance));
  }
}

// File: contracts/interfaces/IParticipantRegistry.sol

pragma solidity 0.5.0;

interface IParticipantRegistry {
  function isRegisteredParticipant(bytes32 _id) external view returns (bool);
}

// File: contract-registry/contracts/helpers/Killable.sol

pragma solidity 0.5.0;

contract Killable {

  address payable private _payableOwner;

  event LogKill(
    uint256 balance,
    address indexed balanceReceiver
  );

  constructor () public {
    _payableOwner = msg.sender;
  }

  function kill()
  external {
    require(msg.sender == _payableOwner, "[kill] access denied");

    emit LogKill(address(this).balance, _payableOwner);
    selfdestruct(_payableOwner);
  }
}

// File: contract-registry/contracts/storage/StorageBase.sol

pragma solidity 0.5.0;



contract StorageBase is Killable {

  address public deployer;

  address public storageOwner;

  event LogInitStorageOwner(address indexed executor, address indexed storageOwner);
  event LogSwitchOwnerTo(address indexed executor, address indexed storageOwner);

  modifier onlyFromStorageOwner() {
    require(msg.sender == address(storageOwner), "you are not an owner of this storage");
    _;
  }

  constructor () public {
    deployer = msg.sender;
  }

  function initStorageOwner(address _instance)
  external
  returns (bool) {
    require(msg.sender == deployer, "[initStorageOwner] only deployer can initialize storage owner");
    require(address(storageOwner) == address(0x0), "[initStorageOwner] _storageOwner is already set");

    storageOwner = _instance;
    emit LogInitStorageOwner(msg.sender, _instance);

    return true;
  }

  function switchOwnerTo(address _newOwner)
  external
  onlyFromStorageOwner
  returns (bool) {
    require(address(storageOwner) != address(0x0), "[switchOwnerTo] failed");

    storageOwner = _newOwner;
    emit LogSwitchOwnerTo(msg.sender, _newOwner);

    return true;
  }

  function accessCheck()
  external
  view
  onlyFromStorageOwner
  returns (bool) {
    return true;
  }
}

// File: contracts/ParticipantRegistryStorage.sol

pragma solidity 0.5.0;



contract ParticipantRegistryStorage is StorageBase {
  struct Participant {
    bytes32 id;
    string name;
    string publicKey;
    string externalId;
  }

  mapping(bytes32 => Participant) public participants;
  bytes32[] public ids;

  function getNumberOfIds() external view returns (uint256) {
    return ids.length;
  }

  function pushId(bytes32 _id)
  external
  onlyFromStorageOwner {
    ids.push(_id);
  }

  function setParticipant(
    bytes32 _id,
    string calldata _name,
    string calldata _publicKey,
    string calldata _externalId
  )
  external
  onlyFromStorageOwner {
    participants[_id] = Participant(_id, _name, _publicKey, _externalId);
  }

  function setParticipantName(bytes32 _id, string calldata _name)
  external
  onlyFromStorageOwner {
    participants[_id].name = _name;
  }

  function setParticipantExternalId(bytes32 _id, string calldata _externalId)
  external
  onlyFromStorageOwner {
    participants[_id].externalId = _externalId;
  }

  function setParticipantPublicKey(bytes32 _id, string calldata _publicKey)
  external
  onlyFromStorageOwner {
    participants[_id].publicKey = _publicKey;
  }

  function getParticipantName(bytes32 _id) external view returns (string memory) {
    return participants[_id].name;
  }

  function getParticipantPublicKey(bytes32 _id) external view returns (string memory) {
    return participants[_id].publicKey;
  }

  function getParticipantExternalId(bytes32 _id) external view returns (string memory) {
    return participants[_id].externalId;
  }
}

// File: contracts/ParticipantRegistry.sol

pragma solidity 0.5.0;









contract ParticipantRegistry is IParticipantRegistry, Ownable, RegistrableWithSingleStorage {

  using SafeMath for uint256;

  bytes32 constant NAME = "ParticipantRegistry";

  event LogParticipantRegistered(
    bytes32 id,
    string name,
    string publicKey,
    string externalId
  );

  event LogParticipantUpdated(
    bytes32 id,
    string name,
    string publicKey,
    string externalId
  );

  constructor(address _registry, IStorageBase _storage)
  public
  RegistrableWithSingleStorage(_registry, _storage) {}

  function contractName() external view returns (bytes32) {
    return NAME;
  }

  function _storage() private view returns (ParticipantRegistryStorage) {
    return ParticipantRegistryStorage(address(singleStorage));
  }

  function create(
    string memory _id,
    string memory _name,
    string memory _publicKey) public onlyOwner {
    ParticipantRegistryStorage prStorage = _storage();

    bytes32 hashedId = keccak256(bytes(_id));

    ParticipantRegistryStorage.Participant memory participant;
    (participant.id, participant.name, participant.publicKey, participant.externalId) = prStorage.participants(hashedId);

    require(participant.id == 0x0, "participant already exists");

    participant.id = hashedId;
    participant.name = _name;
    participant.publicKey = _publicKey;
    participant.externalId = _id;

    prStorage.setParticipant(
      participant.id,
      participant.name,
      participant.publicKey,
      participant.externalId
    );

    prStorage.pushId(participant.id);

    emit LogParticipantRegistered(
      participant.id,
      participant.name,
      participant.publicKey,
      participant.externalId
    );
  }

  function getNumberOfParticipants() public view returns (uint256) {
    return _storage().getNumberOfIds();
  }

  function update(bytes32 _id, string memory _name, string memory _publicKey) public onlyOwner {
    ParticipantRegistryStorage prStorage = _storage();
    ParticipantRegistryStorage.Participant memory participant;
    (participant.id, participant.name, participant.publicKey, participant.externalId) = prStorage.participants(_id);

    require(participant.id != 0x0, "participant do not exists");

    participant.name = _name;
    participant.publicKey = _publicKey;

    prStorage.setParticipant(
      participant.id,
      participant.name,
      participant.publicKey,
      participant.externalId
    );

    emit LogParticipantUpdated(
      participant.id,
      participant.name,
      participant.publicKey,
      participant.externalId
    );
  }

  function participants(bytes32 _id) external view returns (
    bytes32 id,
    string memory name,
    string memory publicKey,
    string memory externalId
  ) {
    ParticipantRegistryStorage.Participant memory participant;
    (participant.id, participant.name, participant.publicKey, participant.externalId) = _storage().participants(_id);

    return (
      participant.id,
      participant.name,
      participant.publicKey,
      participant.externalId
    );
  }

  function ids(uint256 _i) external view returns (bytes32) {
    return _storage().ids(_i);
  }

  function isRegisteredParticipant(bytes32 _id) external view returns (bool) {
    bytes32 id;
    (id, , , ) = _storage().participants(_id);
    return id != 0x0;
  }
}