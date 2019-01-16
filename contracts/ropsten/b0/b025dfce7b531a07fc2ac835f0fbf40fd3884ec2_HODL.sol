pragma solidity ^0.4.24;

// File: zos-lib/contracts/Initializable.sol

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: /openzeppelin-eth/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// File: /openzeppelin-eth/contracts/access/roles/PauserRole.sol

contract PauserRole is Initializable {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  function initialize(address sender) public initializer {
    if (!isPauser(sender)) {
      _addPauser(sender);
    }
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }

  uint256[50] private ______gap;
}

// File: /openzeppelin-eth/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Initializable, PauserRole {
  event Paused();
  event Unpaused();

  bool private _paused = false;

  function initialize(address sender) public initializer {
    PauserRole.initialize(sender);
  }

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function paused() public view returns(bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused();
  }

  uint256[50] private ______gap;
}

// File: contracts/HODL.sol

contract HODL is Initializable, Pausable {

    modifier hashDoesNotExist(string _hash){
        if(hashExistsMap[_hash] == true) revert();
        _;
    }

    mapping (string => address) hashToSender;
    mapping (string => uint) hashToTimestamp;
    mapping (string => bool) hashExistsMap;
    mapping (address => mapping (address => bool)) userOptOut;

    string[] public hashes;

    event AddedBatch(address indexed from, string hash, uint256 timestamp);
    event UserOptOut(address user, address appAddress, uint256 timestamp);
    event UserOptIn(address user, address appAddress, uint256 timestamp);

    function initialize() initializer public {
        hashes.push("hodl-genesis");
        hashToSender["hodl-genesis"] = msg.sender;
        hashToTimestamp["hodl-genesis"] = now;
        hashExistsMap["hodl-genesis"] = true;
    }

    function storeBatch(string _hash) public whenNotPaused hashDoesNotExist(_hash) {
        hashes.push(_hash);
        hashToSender[_hash] = msg.sender;
        hashToTimestamp[_hash] = now;
        hashExistsMap[_hash] = true;
        emit AddedBatch(msg.sender, _hash, now);
    }

    
    function opt(address appAddress) public whenNotPaused {
        bool userOptState = userOptOut[msg.sender][appAddress];
        if(userOptState == false){
            userOptOut[msg.sender][appAddress] = true;
            emit UserOptIn(msg.sender, appAddress, now);
        }
        else{
            userOptOut[msg.sender][appAddress] = false;
            emit UserOptOut(msg.sender, appAddress, now);
        }
    }

    function getSenderByHash(string _hash) public view returns (address) {
        return hashToSender[_hash];
    }
    
    function getTimestampByHash(string _hash) public view returns (uint) {
        return hashToTimestamp[_hash];
    }

    function getUserOptState(address userAddress, address appAddress) public view returns (bool){
        return userOptOut[userAddress][appAddress];
    }

}