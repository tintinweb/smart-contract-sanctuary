pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// ----------------------------------------------------------------------------
// Ownable contract
// ----------------------------------------------------------------------------
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  event OwnershipTransferPending(address indexed owner, address indexed pendingOwner);

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferPending(owner, pendingOwner);
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// ----------------------------------------------------------------------------
// Pausable contract
// ----------------------------------------------------------------------------
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Claimable {
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// ----------------------------------------------------------------------------
// Admin contract
// ----------------------------------------------------------------------------
/**
 * @title Admin
 * @dev The Admin contract has the list of admin addresses.
 */
contract Administratable is Claimable {
  mapping(address => bool) public admins;

  event AdminAddressAdded(address indexed addr);
  event AdminAddressRemoved(address indexed addr);

  /**
   * @dev Throws if called by any account that&#39;s not admin or owner.
   */
  modifier onlyAdmin() {
    require(admins[msg.sender] || msg.sender == owner);
    _;
  }

  /**
   * @dev add an address to the admin list
   * @param addr address
   * @return true if the address was added to the admin list, false if the address was already in the admin list
   */
  function addAddressToAdmin(address addr) onlyOwner public returns(bool success) {
    if (!admins[addr]) {
      admins[addr] = true;
      emit AdminAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev remove an address from the admin list
   * @param addr address
   * @return true if the address was removed from the admin list,
   * false if the address wasn&#39;t in the admin list in the first place
   */
  function removeAddressFromAdmin(address addr) onlyOwner public returns(bool success) {
    if (admins[addr]) {
      admins[addr] = false;
      emit AdminAddressRemoved(addr);
      success = true;
    }
  }
}

/**
 * @title Callable
 * @dev Extension for the Ownable contract.
 * This allows the contract only be called by certain contract.
 */
contract Callable is Claimable {
  mapping(address => bool) public callers;

  event CallerAddressAdded(address indexed addr);
  event CallerAddressRemoved(address indexed addr);


  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyCaller() {
    require(callers[msg.sender] || msg.sender == owner);
    _;
  }

  /**
   * @dev add an address to the caller list
   * @param addr address
   * @return true if the address was added to the caller list, false if the address was already in the caller list
   */
  function addAddressToCaller(address addr) onlyOwner public returns(bool success) {
    if (!callers[addr]) {
      callers[addr] = true;
      emit CallerAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev remove an address from the caller list
   * @param addr address
   * @return true if the address was removed from the caller list,
   * false if the address wasn&#39;t in the caller list in the first place
   */
  function removeAddressFromCaller(address addr) onlyOwner public returns(bool success) {
    if (callers[addr]) {
      callers[addr] = false;
      emit CallerAddressRemoved(addr);
      success = true;
    }
  }
}
// ----------------------------------------------------------------------------
// Blacklist
// ----------------------------------------------------------------------------
/**
 * @title Blacklist
 * @dev The Blacklist contract has a blacklist of addresses, and provides basic authorization control functions.
 */
contract Blacklist is Callable {
  mapping(address => bool) public blacklist;

  function addAddressToBlacklist(address addr) onlyCaller public returns (bool success) {
    if (!blacklist[addr]) {
      blacklist[addr] = true;
      success = true;
    }
  }

  function removeAddressFromBlacklist(address addr) onlyCaller public returns (bool success) {
    if (blacklist[addr]) {
      blacklist[addr] = false;
      success = true;
    }
  }
}

// ----------------------------------------------------------------------------
// Verified
// ----------------------------------------------------------------------------
/**
 * @title Verified
 * @dev The Verified contract has a list of verified addresses.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Verified is Callable {
  mapping(address => bool) public verifiedList;

  function verifyAddress(address addr) onlyCaller public returns (bool success) {
    if (!verifiedList[addr]) {
      verifiedList[addr] = true;
      success = true;
    }
  }

  function unverifyAddress(address addr) onlyCaller public returns (bool success) {
    if (verifiedList[addr]) {
      verifiedList[addr] = false;
      success = true;
    }
  }
}



// ----------------------------------------------------------------------------
// Storage for the Allowance List
// ----------------------------------------------------------------------------
contract Allowance is Callable {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) public allowanceOf;

  function addAllowance(address _holder, address _spender, uint256 _value) onlyCaller public {
    allowanceOf[_holder][_spender] = allowanceOf[_holder][_spender].add(_value);
  }

  function subAllowance(address _holder, address _spender, uint256 _value) onlyCaller public {
    uint256 oldValue = allowanceOf[_holder][_spender];
    if (_value > oldValue) {
      allowanceOf[_holder][_spender] = 0;
    } else {
      allowanceOf[_holder][_spender] = oldValue.sub(_value);
    }
  }

  function setAllowance(address _holder, address _spender, uint256 _value) onlyCaller public {
    allowanceOf[_holder][_spender] = _value;
  }
}

// ----------------------------------------------------------------------------
// Storage for the Balance List
// ----------------------------------------------------------------------------
contract Balance is Callable {
  using SafeMath for uint256;

  mapping (address => uint256) public balanceOf;

  uint256 public totalSupply;

  function addBalance(address _addr, uint256 _value) onlyCaller public {
    balanceOf[_addr] = balanceOf[_addr].add(_value);
  }

  function subBalance(address _addr, uint256 _value) onlyCaller public {
    balanceOf[_addr] = balanceOf[_addr].sub(_value);
  }

  function setBalance(address _addr, uint256 _value) onlyCaller public {
    balanceOf[_addr] = _value;
  }

  function addTotalSupply(uint256 _value) onlyCaller public {
    totalSupply = totalSupply.add(_value);
  }

  function subTotalSupply(uint256 _value) onlyCaller public {
    totalSupply = totalSupply.sub(_value);
  }
}

contract UserContract {
  Blacklist internal _blacklist;
  Verified internal _verifiedList;

  constructor(
    Blacklist _blacklistContract, Verified _verifiedListContract
  ) public {
    _blacklist = _blacklistContract;
    _verifiedList = _verifiedListContract;
  }


  /**
   * @dev Throws if the given address is blacklisted.
   */
  modifier onlyNotBlacklistedAddr(address addr) {
    require(!_blacklist.blacklist(addr));
    _;
  }

  /**
   * @dev Throws if one of the given addresses is blacklisted.
   */
  modifier onlyNotBlacklistedAddrs(address[] addrs) {
    for (uint256 i = 0; i < addrs.length; i++) {
      require(!_blacklist.blacklist(addrs[i]));
    }
    _;
  }

  /**
   * @dev Throws if the given address is not verified.
   */
  modifier onlyVerifiedAddr(address addr) {
    require(_verifiedList.verifiedList(addr));
    _;
  }

  /**
   * @dev Throws if one of the given addresses is not verified.
   */
  modifier onlyVerifiedAddrs(address[] addrs) {
    for (uint256 i = 0; i < addrs.length; i++) {
      require(_verifiedList.verifiedList(addrs[i]));
    }
    _;
  }

  function blacklist(address addr) public view returns (bool) {
    return _blacklist.blacklist(addr);
  }

  function verifiedlist(address addr) public view returns (bool) {
    return _verifiedList.verifiedList(addr);
  }
}

contract AdminContract is Pausable, Administratable, UserContract {

  Balance internal _balances;

  uint256 constant maxBLBatch = 100;

  constructor(
    Balance _balanceContract, Blacklist _blacklistContract, Verified _verifiedListContract
  ) UserContract(_blacklistContract, _verifiedListContract) public {
    _balances = _balanceContract;
  }

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);
  // This notifies clients about the amount mint
  event Mint(address indexed to, uint256 value);

  event VerifiedAddressAdded(address indexed addr);
  event VerifiedAddressRemoved(address indexed addr);

  event BlacklistedAddressAdded(address indexed addr);
  event BlacklistedAddressRemoved(address indexed addr);

  // blacklist operations
  function _addToBlacklist(address addr) internal returns (bool success) {
    success = _blacklist.addAddressToBlacklist(addr);
    if (success) {
      emit BlacklistedAddressAdded(addr);
    }
  }

  function _removeFromBlacklist(address addr) internal returns (bool success) {
    success = _blacklist.removeAddressFromBlacklist(addr);
    if (success) {
      emit BlacklistedAddressRemoved(addr);
    }
  }

  /**
   * @dev add an address to the blacklist
   * @param addr address
   * @return true if the address was added to the blacklist, false if the address was already in the blacklist
   */
  function addAddressToBlacklist(address addr) onlyAdmin whenNotPaused public returns (bool) {
    return _addToBlacklist(addr);
  }

  /**
   * @dev add addresses to the blacklist
   * @param addrs addresses
   * @return true if at least one address was added to the blacklist,
   * false if all addresses were already in the blacklist
   */
  function addAddressesToBlacklist(address[] addrs) onlyAdmin whenNotPaused public returns (bool success) {
    uint256 cnt = uint256(addrs.length);
    require(cnt <= maxBLBatch);
    success = true;
    for (uint256 i = 0; i < addrs.length; i++) {
      if (!_addToBlacklist(addrs[i])) {
        success = false;
      }
    }
  }

  /**
   * @dev remove an address from the blacklist
   * @param addr address
   * @return true if the address was removed from the blacklist,
   * false if the address wasn&#39;t in the blacklist in the first place
   */
  function removeAddressFromBlacklist(address addr) onlyAdmin whenNotPaused public returns (bool) {
    return _removeFromBlacklist(addr);
  }

  /**
   * @dev remove addresses from the blacklist
   * @param addrs addresses
   * @return true if at least one address was removed from the blacklist,
   * false if all addresses weren&#39;t in the blacklist in the first place
   */
  function removeAddressesFromBlacklist(address[] addrs) onlyAdmin whenNotPaused public returns (bool success) {
    success = true;
    for (uint256 i = 0; i < addrs.length; i++) {
      if (!_removeFromBlacklist(addrs[i])) {
        success = false;
      }
    }
  }

  // verified list operations
  function _verifyAddress(address addr) internal returns (bool success) {
    success = _verifiedList.verifyAddress(addr);
    if (success) {
      emit VerifiedAddressAdded(addr);
    }
  }

  function _unverifyAddress(address addr) internal returns (bool success) {
    success = _verifiedList.unverifyAddress(addr);
    if (success) {
      emit VerifiedAddressRemoved(addr);
    }
  }

  /**
   * @dev add an address to the verifiedlist
   * @param addr address
   * @return true if the address was added to the verifiedlist, false if the address was already in the verifiedlist or if the address is in the blacklist
   */
  function verifyAddress(address addr) onlyAdmin onlyNotBlacklistedAddr(addr) whenNotPaused public returns (bool) {
    return _verifyAddress(addr);
  }

  /**
   * @dev add addresses to the verifiedlist
   * @param addrs addresses
   * @return true if at least one address was added to the verifiedlist,
   * false if all addresses were already in the verifiedlist
   */
  function verifyAddresses(address[] addrs) onlyAdmin onlyNotBlacklistedAddrs(addrs) whenNotPaused public returns (bool success) {
    success = true;
    for (uint256 i = 0; i < addrs.length; i++) {
      if (!_verifyAddress(addrs[i])) {
        success = false;
      }
    }
  }


  /**
   * @dev remove an address from the verifiedlist
   * @param addr address
   * @return true if the address was removed from the verifiedlist,
   * false if the address wasn&#39;t in the verifiedlist in the first place
   */
  function unverifyAddress(address addr) onlyAdmin whenNotPaused public returns (bool) {
    return _unverifyAddress(addr);
  }


  /**
   * @dev remove addresses from the verifiedlist
   * @param addrs addresses
   * @return true if at least one address was removed from the verifiedlist,
   * false if all addresses weren&#39;t in the verifiedlist in the first place
   */
  function unverifyAddresses(address[] addrs) onlyAdmin whenNotPaused public returns (bool success) {
    success = true;
    for (uint256 i = 0; i < addrs.length; i++) {
      if (!_unverifyAddress(addrs[i])) {
        success = false;
      }
    }
  }

  /**
   * Destroy tokens from other account
   *
   * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
   *
   * @param _from the address of the sender
   * @param _value the amount of money to burn
   */
  function burnFrom(address _from, uint256 _value) onlyOwner whenNotPaused
  public returns (bool success) {
    require(_balances.balanceOf(_from) >= _value);    // Check if the targeted balance is enough
    _balances.subBalance(_from, _value);              // Subtract from the targeted balance
    _balances.subTotalSupply(_value);
    emit Burn(_from, _value);
    return true;
  }

  /**
    * Add `_amount` tokens to the pool and to the `_to` address&#39; balance
    *
    * @param _to the address that will receive the given amount of tokens
    * @param _amount the amount of tokens it will receive
    */
  function mint(address _to, uint256 _amount)
  onlyOwner whenNotPaused onlyNotBlacklistedAddr(_to) onlyVerifiedAddr(_to)
  public returns (bool success) {
    _balances.addBalance(_to, _amount);
    _balances.addTotalSupply(_amount);
    emit Mint(_to, _amount);
    return true;
  }
}