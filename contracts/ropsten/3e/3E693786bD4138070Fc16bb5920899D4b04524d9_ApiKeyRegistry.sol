pragma solidity 0.4.24;

// File: contracts/Stoppable.sol

/* using a master switch, allowing to permanently turn-off functionality */
contract Stoppable {

  /************************************ abstract **********************************/
  modifier onlyOwner { _; }
  /********************************************************************************/

  bool public isOn = true;

  modifier whenOn() { require(isOn, "must be on"); _; }
  modifier whenOff() { require(!isOn, "must be off"); _; }

  function switchOff() onlyOwner external {
    if (isOn) {
      isOn = false;
      emit Off();
    }
  }
  event Off();
}

// File: contracts/Switchable.sol

/* using a master switch, allowing to switch functionality on/off */
contract Switchable is Stoppable {

  function switchOn() onlyOwner external {
    if (!isOn) {
      isOn = true;
      emit On();
    }
  }
  event On();
}

// File: contracts/Validating.sol

contract Validating {

  modifier notZero(uint number) { require(number != 0, "invalid 0 value"); _; }
  modifier notEmpty(string text) { require(bytes(text).length != 0, "invalid empty string"); _; }
  modifier validAddress(address value) { require(value != address(0x0), "invalid address");  _; }

}

// File: contracts/HasOwners.sol

contract HasOwners is Validating {

  mapping(address => bool) public isOwner;
  address[] private owners;

  constructor(address[] _owners) public {
    for (uint i = 0; i < _owners.length; i++) _addOwner_(_owners[i]);
    owners = _owners;
  }

  modifier onlyOwner { require(isOwner[msg.sender], "invalid sender; must be owner"); _; }

  function getOwners() public view returns (address[]) { return owners; }

  function addOwner(address owner) external onlyOwner {  _addOwner_(owner); }

  function _addOwner_(address owner) validAddress(owner) private {
    if (!isOwner[owner]) {
      isOwner[owner] = true;
      owners.push(owner);
      emit OwnerAdded(owner);
    }
  }
  event OwnerAdded(address indexed owner);

  function removeOwner(address owner) external onlyOwner {
    if (isOwner[owner]) {
      require(owners.length > 1, "removing the last owner is not allowed");
      isOwner[owner] = false;
      for (uint i = 0; i < owners.length - 1; i++) {
        if (owners[i] == owner) {
          owners[i] = owners[owners.length - 1]; // replace map last entry
          delete owners[owners.length - 1];
          break;
        }
      }
      owners.length -= 1;
      emit OwnerRemoved(owner);
    }
  }
  event OwnerRemoved(address indexed owner);
}

// File: contracts/registry/Registry.sol

interface Registry {

  function contains(address apiKey) external view returns (bool);

  function register(address apiKey) external;
  function registerWithUserAgreement(address apiKey, bytes32 userAgreement) external;
  event Registered(address apiKey, address indexed account);

  function translate(address apiKey) external view returns (address);
}

// File: contracts/registry/ApiKeyRegistry.sol

contract ApiKeyRegistry is Switchable, HasOwners, Registry {
  string public version;

  /* mapping of: address of api-key used in trading => address of account map funds used in settling */
  mapping (address => address) public accounts;
  mapping (address => bytes32) public userAgreements;

  constructor(address[] _owners, string _version) HasOwners(_owners) public {
    version = _version;
  }

  modifier isAbsent(address apiKey) { require(!_contains_(apiKey), "api key already in use"); _; }

  function contains(address apiKey) external view returns (bool) { return _contains_(apiKey); }
  function _contains_(address apiKey) private view returns (bool) { return accounts[apiKey] != address(0x0); }

  function registerWithUserAgreement(address apiKey, bytes32 userAgreement) validAddress(apiKey) isAbsent(apiKey) whenOn public {
    accounts[apiKey] = msg.sender;
    if (userAgreement != 0 && userAgreements[msg.sender] == 0) {
      userAgreements[msg.sender] = userAgreement;
    }
    emit Registered(apiKey, msg.sender, userAgreements[msg.sender]);
  }

  function register(address apiKey) external {
    registerWithUserAgreement(apiKey, 0);
  }

  event Registered(address apiKey, address indexed account, bytes32 userAgreement);

  function translate(address apiKey) external view returns (address) { return accounts[apiKey]; }

}