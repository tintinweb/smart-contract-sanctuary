pragma solidity ^0.4.18;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/TweedentityStore.sol

/**
 * @title TweedentityStore
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev It store the tweedentities related to the app
 */



contract TweedentityStore /** 1.0.2 */
is Ownable
{

  uint public appId;
  string public appNickname;

  uint public identities;

  address public manager;
  address public newManager;

  struct Uid {
    string lastUid;
    uint lastUpdate;
  }

  struct Address {
    address lastAddress;
    uint lastUpdate;
  }

  mapping(string => Address) internal __addressByUid;
  mapping(address => Uid) internal __uidByAddress;

  bool public appSet;



  // events


  event IdentitySet(
    address indexed addr,
    string uid
  );


  event IdentityRemoved(
    address indexed addr,
    string uid
  );



  // modifiers


  modifier onlyManager() {
    require(msg.sender == manager || (newManager != address(0) && msg.sender == newManager));
    _;
  }


  modifier whenAppSet() {
    require(appSet);
    _;
  }



  // config


  /**
  * @dev Sets the manager
  * @param _address Manager&#39;s address
  */
  function setManager(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != address(0));
    manager = _address;
  }


  /**
  * @dev Sets new manager
  * @param _address New manager&#39;s address
  */
  function setNewManager(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != address(0) && manager != address(0));
    newManager = _address;
  }


  /**
  * @dev Sets new manager
  */
  function switchManagerAndRemoveOldOne()
  external
  onlyOwner
  {
    manager = newManager;
    newManager = address(0);
  }


  /**
  * @dev Sets the app
  * @param _appNickname Nickname (e.g. twitter)
  * @param _appId ID (e.g. 1)
  */
  function setApp(
    string _appNickname,
    uint _appId
  )
  external
  onlyOwner
  {
    require(!appSet);
    require(_appId > 0);
    require(bytes(_appNickname).length > 0);
    appId = _appId;
    appNickname = _appNickname;
    appSet = true;
  }



  // helpers


  /**
   * @dev Checks if a tweedentity is upgradable
   * @param _address The address
   * @param _uid The user-id
   */
  function isUpgradable(
    address _address,
    string _uid
  )
  public
  constant returns (bool)
  {
    if (__addressByUid[_uid].lastAddress != address(0)) {
      return keccak256(getUid(_address)) == keccak256(_uid);
    }
    return true;
  }



  // primary methods


  /**
   * @dev Sets a tweedentity
   * @param _address The address of the wallet
   * @param _uid The user-id of the owner user account
   */
  function setIdentity(
    address _address,
    string _uid
  )
  external
  onlyManager
  whenAppSet
  {
    require(_address != address(0));
    require(isUid(_uid));
    require(isUpgradable(_address, _uid));

    if (bytes(__uidByAddress[_address].lastUid).length > 0) {
      // if _address is associated with an oldUid,
      // this removes the association between _address and oldUid
      __addressByUid[__uidByAddress[_address].lastUid] = Address(address(0), __addressByUid[__uidByAddress[_address].lastUid].lastUpdate);
      identities--;
    }

    __uidByAddress[_address] = Uid(_uid, now);
    __addressByUid[_uid] = Address(_address, now);
    identities++;
    IdentitySet(_address, _uid);
  }


  /**
   * @dev Unset a tweedentity
   * @param _address The address of the wallet
   */
  function unsetIdentity(
    address _address
  )
  external
  onlyManager
  whenAppSet
  {
    require(_address != address(0));
    require(bytes(__uidByAddress[_address].lastUid).length > 0);

    string memory uid = __uidByAddress[_address].lastUid;
    __uidByAddress[_address] = Uid(&#39;&#39;, __uidByAddress[_address].lastUpdate);
    __addressByUid[uid] = Address(address(0), __addressByUid[uid].lastUpdate);
    identities--;
    IdentityRemoved(_address, uid);
  }



  // getters


  /**
   * @dev Returns the keccak256 of the app nickname
   */
  function getAppNickname()
  external
  whenAppSet
  constant returns (bytes32) {
    return keccak256(appNickname);
  }


  /**
   * @dev Returns the appId
   */
  function getAppId()
  external
  whenAppSet
  constant returns (uint) {
    return appId;
  }


  /**
   * @dev Returns the user-id associated to a wallet
   * @param _address The address of the wallet
   */
  function getUid(
    address _address
  )
  public
  constant returns (string)
  {
    return __uidByAddress[_address].lastUid;
  }


  /**
   * @dev Returns the user-id associated to a wallet as a unsigned integer
   * @param _address The address of the wallet
   */
  function getUidAsInteger(
    address _address
  )
  external
  constant returns (uint)
  {
    return __stringToUint(__uidByAddress[_address].lastUid);
  }


  /**
   * @dev Returns the address associated to a user-id
   * @param _uid The user-id
   */
  function getAddress(
    string _uid
  )
  external
  constant returns (address)
  {
    return __addressByUid[_uid].lastAddress;
  }


  /**
   * @dev Returns the timestamp of last update by address
   * @param _address The address of the wallet
   */
  function getAddressLastUpdate(
    address _address
  )
  external
  constant returns (uint)
  {
    return __uidByAddress[_address].lastUpdate;
  }


  /**
 * @dev Returns the timestamp of last update by user-id
 * @param _uid The user-id
 */
  function getUidLastUpdate(
    string _uid
  )
  external
  constant returns (uint)
  {
    return __addressByUid[_uid].lastUpdate;
  }



  // utils


  function isUid(
    string _uid
  )
  public
  pure
  returns (bool)
  {
    bytes memory uid = bytes(_uid);
    if (uid.length == 0) {
      return false;
    } else {
      for (uint i = 0; i < uid.length; i++) {
        if (uid[i] < 48 || uid[i] > 57) {
          return false;
        }
      }
    }
    return true;
  }



  // private methods


  function __stringToUint(
    string s
  )
  internal
  pure
  returns (uint result)
  {
    bytes memory b = bytes(s);
    uint i;
    result = 0;
    for (i = 0; i < b.length; i++) {
      uint c = uint(b[i]);
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
  }


  function __uintToBytes(uint x)
  internal
  pure
  returns (bytes b)
  {
    b = new bytes(32);
    for (uint i = 0; i < 32; i++) {
      b[i] = byte(uint8(x / (2 ** (8 * (31 - i)))));
    }
  }

}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: contracts/TweedentityManager.sol

/**
 * @title TweedentityManager
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev Sets and removes tweedentities in the store,
 * adding more logic to the simple logic of the store
 */


contract TweedentityManager /** 1.0.2 */
is Pausable
{

  struct Store {
    TweedentityStore store;
    address addr;
  }

  mapping(uint => Store) private __stores;

  mapping(uint => bytes32) public appNicknames32;
  mapping(uint => string) public appNicknames;
  mapping(string => uint) private __appIds;

  address public claimer;
  address public newClaimer;
  mapping(address => bool) public customerService;
  address[] private __customerServiceAddress;

  uint public upgradable = 0;
  uint public notUpgradableInStore = 1;
  uint public addressNotUpgradable = 2;

  uint public minimumTimeBeforeUpdate = 1 hours;



  // events


  event IdentityNotUpgradable(
    string appNickname,
    address indexed addr,
    string uid
  );



  // config


  /**
   * @dev Sets a store to be used by the manager
   * @param _appNickname The nickname of the app for which the store&#39;s been configured
   * @param _address The address of the store
   */
  function setAStore(
    string _appNickname,
    address _address
  )
  public
  onlyOwner
  {
    require(bytes(_appNickname).length > 0);
    bytes32 _appNickname32 = keccak256(_appNickname);
    require(_address != address(0));
    TweedentityStore _store = TweedentityStore(_address);
    require(_store.getAppNickname() == _appNickname32);
    uint _appId = _store.getAppId();
    require(appNicknames32[_appId] == 0x0);
    appNicknames32[_appId] = _appNickname32;
    appNicknames[_appId] = _appNickname;
    __appIds[_appNickname] = _appId;

    __stores[_appId] = Store(
      TweedentityStore(_address),
      _address
    );
  }


  /**
   * @dev Sets the claimer which will verify the ownership and call to set a tweedentity
   * @param _address Address of the claimer
   */
  function setClaimer(
    address _address
  )
  public
  onlyOwner
  {
    require(_address != 0x0);
    claimer = _address;
  }


  /**
   * @dev Sets a new claimer during updates
   * @param _address Address of the new claimer
   */
  function setNewClaimer(
    address _address
  )
  public
  onlyOwner
  {
    require(_address != address(0) && claimer != address(0));
    newClaimer = _address;
  }


  /**
  * @dev Sets new manager
  */
  function switchClaimerAndRemoveOldOne()
  external
  onlyOwner
  {
    claimer = newClaimer;
    newClaimer = address(0);
  }


  /**
   * @dev Sets a wallet as customer service to perform emergency removal of wrong, abused, squatted tweedentities (due, for example, to hacking of the Twitter account)
   * @param _address The customer service wallet
   * @param _status The status (true is set, false is unset)
   */
  function setCustomerService(
    address _address,
    bool _status
  )
  public
  onlyOwner
  {
    require(_address != 0x0);
    customerService[_address] = _status;
    bool found;
    for (uint i = 0; i < __customerServiceAddress.length; i++) {
      if (__customerServiceAddress[i] == _address) {
        found = true;
        break;
      }
    }
    if (!found) {
      __customerServiceAddress.push(_address);
    }
  }



  //modifiers


  modifier onlyClaimer() {
    require(msg.sender == claimer || (newClaimer != address(0) && msg.sender == newClaimer));
    _;
  }


  modifier onlyCustomerService() {
    require(msg.sender == owner || customerService[msg.sender] == true);
    _;
  }


  modifier whenStoreSet(
    uint _appId
  ) {
    require(appNicknames32[_appId] != 0x0);
    _;
  }



  // internal getters


  function __getStore(
    uint _appId
  )
  internal
  constant returns (TweedentityStore)
  {
    return __stores[_appId].store;
  }



  // helpers


  function isAddressUpgradable(
    TweedentityStore _store,
    address _address
  )
  internal
  constant returns (bool)
  {
    uint lastUpdate = _store.getAddressLastUpdate(_address);
    return lastUpdate == 0 || now >= lastUpdate + minimumTimeBeforeUpdate;
  }


  function isUpgradable(
    TweedentityStore _store,
    address _address,
    string _uid
  )
  internal
  constant returns (bool)
  {
    if (!_store.isUpgradable(_address, _uid) || !isAddressUpgradable(_store, _address)) {
      return false;
    }
    return true;
  }



  // getters


  /**
   * @dev Gets the app-id associated to a nickname
   * @param _appNickname The nickname of a configured app
   */
  function getAppId(
    string _appNickname
  )
  external
  constant returns (uint) {
    return __appIds[_appNickname];
  }


  /**
   * @dev Allows other contracts to check if a store is set
   * @param _appNickname The nickname of a configured app
   */
  function isStoreSet(
    string _appNickname
  )
  public
  constant returns (bool){
    return __appIds[_appNickname] != 0;
  }


  /**
   * @dev Return a numeric code about the upgradability of a couple wallet-uid in a certain app
   * @param _appId The id of the app
   * @param _address The address of the wallet
   * @param _uid The user-id
   */
  function getUpgradability(
    uint _appId,
    address _address,
    string _uid
  )
  external
  constant returns (uint)
  {
    TweedentityStore _store = __getStore(_appId);
    if (!_store.isUpgradable(_address, _uid)) {
      return notUpgradableInStore;
    } else if (!isAddressUpgradable(_store, _address)) {
      return addressNotUpgradable;
    } else {
      return upgradable;
    }
  }


  /**
   * @dev Returns the address of a store
   * @param _appNickname The app nickname
   */
  function getStoreAddress(
    string _appNickname
  )
  external
  constant returns (address) {
    return __stores[__appIds[_appNickname]].addr;
  }


  /**
   * @dev Returns the address of any customerService account
   */
  function getCustomerServiceAddress()
  external
  constant returns (address[]) {
    return __customerServiceAddress;
  }



  // primary methods


  /**
   * @dev Sets a new identity
   * @param _appId The id of the app
   * @param _address The address of the wallet
   * @param _uid The user-id
   */
  function setIdentity(
    uint _appId,
    address _address,
    string _uid
  )
  external
  onlyClaimer
  whenStoreSet(_appId)
  whenNotPaused
  {
    require(_address != address(0));

    TweedentityStore _store = __getStore(_appId);
    require(_store.isUid(_uid));
    if (isUpgradable(_store, _address, _uid)) {
      _store.setIdentity(_address, _uid);
    } else {
      IdentityNotUpgradable(appNicknames[_appId], _address, _uid);
    }
  }


  /**
   * @dev Unsets an existent identity
   * @param _appId The id of the app
   * @param _address The address of the wallet
   */
  function unsetIdentity(
    uint _appId,
    address _address
  )
  external
  onlyCustomerService
  whenStoreSet(_appId)
  whenNotPaused
  {
    TweedentityStore _store = __getStore(_appId);
    _store.unsetIdentity(_address);
  }


  /**
   * @dev Allow the sender to unset its existent identity
   * @param _appId The id of the app
   */
  function unsetMyIdentity(
    uint _appId
  )
  external
  whenStoreSet(_appId)
  whenNotPaused
  {
    TweedentityStore _store = __getStore(_appId);
    _store.unsetIdentity(msg.sender);
  }


  /**
   * @dev Update the minimum time before allowing a wallet to update its data
   * @param _newMinimumTime The new minimum time in seconds
   */
  function changeMinimumTimeBeforeUpdate(
    uint _newMinimumTime
  )
  external
  onlyOwner
  {
    minimumTimeBeforeUpdate = _newMinimumTime;
  }



  // private methods


  function __stringToUint(
    string s
  )
  internal
  pure
  returns (uint result)
  {
    bytes memory b = bytes(s);
    uint i;
    result = 0;
    for (i = 0; i < b.length; i++) {
      uint c = uint(b[i]);
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
  }


  function __uintToBytes(uint x)
  internal
  pure
  returns (bytes b)
  {
    b = new bytes(32);
    for (uint i = 0; i < 32; i++) {
      b[i] = byte(uint8(x / (2 ** (8 * (31 - i)))));
    }
  }

}