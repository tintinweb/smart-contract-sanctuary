pragma solidity ^0.4.24;

interface itoken {
    function freezeAccount(address _target, bool _freeze) external;
    function freezeAccountPartialy(address _target, uint256 _value) external;
    function balanceOf(address _owner) external view returns (uint256 balance);
    // function totalSupply() external view returns (uint256);
    // function transferOwnership(address newOwner) external;
    function allowance(address _owner, address _spender) external view returns (uint256);
    function initialCongress(address _congress) external;
    function mint(address _to, uint256 _amount) external returns (bool);
    function finishMinting() external returns (bool);
    function pause() external;
    function unpause() external;
}

library StringUtils {
  /// @dev Does a byte-by-byte lexicographical comparison of two strings.
  /// @return a negative number if `_a` is smaller, zero if they are equal
  /// and a positive numbe if `_b` is smaller.
  function compare(string _a, string _b) public pure returns (int) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    uint minLength = a.length;
    if (b.length < minLength) minLength = b.length;
    //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
    for (uint i = 0; i < minLength; i ++)
      if (a[i] < b[i])
        return -1;
      else if (a[i] > b[i])
        return 1;
    if (a.length < b.length)
      return -1;
    else if (a.length > b.length)
      return 1;
    else
      return 0;
  }
  /// @dev Compares two strings and returns true iff they are equal.
  function equal(string _a, string _b) public pure returns (bool) {
    return compare(_a, _b) == 0;
  }
  /// @dev Finds the index of the first occurrence of _needle in _haystack
  function indexOf(string _haystack, string _needle) public pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
      return -1;
    else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn&#39;t found or input error), this function must return an "int" type with a max length of (2^128 - 1)
      return -1;
    else {
      uint subindex = 0;
      for (uint i = 0; i < h.length; i ++) {
        if (h[i] == n[0]) { // found the first char of b
          subindex = 1;
          while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {// search until the chars don&#39;t match or until we reach the end of a or b
                subindex++;
          }
          if(subindex == n.length)
                return int(i);
        }
      }
      return -1;
    }
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Claimable is Ownable {
  address public pendingOwner;

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

contract DelayedClaimable is Claimable {

  uint256 public end;
  uint256 public start;

  /**
   * @dev Used to specify the time period during which a pending
   * owner can claim ownership.
   * @param _start The earliest time ownership can be claimed.
   * @param _end The latest time ownership can be claimed.
   */
  function setLimits(uint256 _start, uint256 _end) onlyOwner public {
    require(_start <= _end);
    end = _end;
    start = _start;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer, as long as it is called within
   * the specified start and end time.
   */
  function claimOwnership() onlyPendingOwner public {
    require((block.number <= end) && (block.number >= start));
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
    end = 0;
  }

}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

contract MultiOwners is DelayedClaimable, RBAC {
  using SafeMath for uint256;
  using StringUtils for string;

  mapping (string => uint256) private authorizations;
  mapping (address => string) private ownerOfSides;
//   mapping (string => mapping (string => bool)) private voteResults;
  mapping (string => uint256) private sideExist;
  mapping (string => mapping (string => address[])) private sideVoters;
  address[] public owners;
  string[] private authTypes;
//   string[] private ownerSides;
  uint256 public multiOwnerSides;
  uint256 ownerSidesLimit = 5;
//   uint256 authRate = 75;
  bool initAdd = true;

  event OwnerAdded(address addr, string side);
  event OwnerRemoved(address addr);
  event InitialFinished();

  string public constant ROLE_MULTIOWNER = "multiOwner";
  string public constant AUTH_ADDOWNER = "addOwner";
  string public constant AUTH_REMOVEOWNER = "removeOwner";
//   string public constant AUTH_SETAUTHRATE = "setAuthRate";

  /**
   * @dev Throws if called by any account that&#39;s not multiOwners.
   */
  modifier onlyMultiOwners() {
    checkRole(msg.sender, ROLE_MULTIOWNER);
    _;
  }

  /**
   * @dev Throws if not in initializing stage.
   */
  modifier canInitial() {
    require(initAdd);
    _;
  }

  /**
   * @dev the msg.sender will authorize a type of event.
   * @param _authType the event type need to be authorized
   */
  function authorize(string _authType) onlyMultiOwners public {
    string memory side = ownerOfSides[msg.sender];
    address[] storage voters = sideVoters[side][_authType];

    if (voters.length == 0) {
      // if the first time to authorize this type of event
      authorizations[_authType] = authorizations[_authType].add(1);
    //   voteResults[side][_authType] = true;
    }

    // add voters of one side
    uint j = 0;
    for (; j < voters.length; j = j.add(1)) {
      if (voters[j] == msg.sender) {
        break;
      }
    }

    if (j >= voters.length) {
      voters.push(msg.sender);
    }

    // add the authType for clearing auth
    uint i = 0;
    for (; i < authTypes.length; i = i.add(1)) {
      if (authTypes[i].equal(_authType)) {
        break;
      }
    }

    if (i >= authTypes.length) {
      authTypes.push(_authType);
    }
  }

  /**
   * @dev the msg.sender will clear the authorization he has given for the event.
   * @param _authType the event type need to be authorized
   */
  function deAuthorize(string _authType) onlyMultiOwners public {
    string memory side = ownerOfSides[msg.sender];
    address[] storage voters = sideVoters[side][_authType];

    for (uint j = 0; j < voters.length; j = j.add(1)) {
      if (voters[j] == msg.sender) {
        delete voters[j];
        break;
      }
    }

    // if the sender has authorized this type of event, will remove its vote
    if (j < voters.length) {
      for (uint jj = j; jj < voters.length.sub(1); jj = jj.add(1)) {
        voters[jj] = voters[jj.add(1)];
      }

      delete voters[voters.length.sub(1)];
      voters.length = voters.length.sub(1);

      // if there is no votes of one side, the authorization need to be decreased
      if (voters.length == 0) {
        authorizations[_authType] = authorizations[_authType].sub(1);
      //   voteResults[side][_authType] = true;
      }

      // if there is no authorization on this type of event,
      // this event need to be removed from the list
      if (authorizations[_authType] == 0) {
        for (uint i = 0; i < authTypes.length; i = i.add(1)) {
          if (authTypes[i].equal(_authType)) {
            delete authTypes[i];
            break;
          }
        }
        for (uint ii = i; ii < authTypes.length.sub(1); ii = ii.add(1)) {
          authTypes[ii] = authTypes[ii.add(1)];
        }

        delete authTypes[authTypes.length.sub(1)];
        authTypes.length = authTypes.length.sub(1);
      }
    }
  }

  /**
   * @dev judge if the event has already been authorized.
   * @param _authType the event type need to be authorized
   */
  function hasAuth(string _authType) public view returns (bool) {
    require(multiOwnerSides > 1); // at least 2 sides have authorized

    // uint256 rate = authorizations[_authType].mul(100).div(multiOwnerNumber)
    return (authorizations[_authType] == multiOwnerSides);
  }

  /**
   * @dev clear all the authorizations that have been given for a type of event.
   * @param _authType the event type need to be authorized
   */
  function clearAuth(string _authType) internal {
    authorizations[_authType] = 0; // clear authorizations
    for (uint i = 0; i < owners.length; i = i.add(1)) {
      string memory side = ownerOfSides[owners[i]];
      address[] storage voters = sideVoters[side][_authType];
      for (uint j = 0; j < voters.length; j = j.add(1)) {
        delete voters[j]; // clear votes of one side
      }
      voters.length = 0;
    }

    // clear this type of event
    for (uint k = 0; k < authTypes.length; k = k.add(1)) {
      if (authTypes[k].equal(_authType)) {
        delete authTypes[k];
        break;
      }
    }
    for (uint kk = k; kk < authTypes.length.sub(1); kk = kk.add(1)) {
      authTypes[kk] = authTypes[kk.add(1)];
    }

    delete authTypes[authTypes.length.sub(1)];
    authTypes.length = authTypes.length.sub(1);
  }

  /**
   * @dev add an address as one of the multiOwners.
   * @param _addr the account address used as a multiOwner
   */
  function addAddress(address _addr, string _side) internal {
    require(multiOwnerSides < ownerSidesLimit);
    require(_addr != address(0));
    require(ownerOfSides[_addr].equal("")); // not allow duplicated adding

    // uint i = 0;
    // for (; i < owners.length; i = i.add(1)) {
    //   if (owners[i] == _addr) {
    //     break;
    //   }
    // }

    // if (i >= owners.length) {
    owners.push(_addr); // for not allowing duplicated adding, so each addr should be new

    addRole(_addr, ROLE_MULTIOWNER);
    ownerOfSides[_addr] = _side;
    // }

    if (sideExist[_side] == 0) {
      multiOwnerSides = multiOwnerSides.add(1);
    }

    sideExist[_side] = sideExist[_side].add(1);
  }

  /**
   * @dev add an address to the whitelist
   * @param _addr address will be one of the multiOwner
   * @param _side the side name of the multiOwner
   * @return true if the address was added to the multiOwners list,
   *         false if the address was already in the multiOwners list
   */
  function initAddressAsMultiOwner(address _addr, string _side)
    onlyOwner
    canInitial
    public
  {
    // require(initAdd);
    addAddress(_addr, _side);

    // initAdd = false;
    emit OwnerAdded(_addr, _side);
  }

  /**
   * @dev Function to stop initial stage.
   */
  function finishInitOwners() onlyOwner canInitial public {
    initAdd = false;
    emit InitialFinished();
  }

  /**
   * @dev add an address to the whitelist
   * @param _addr address
   * @param _side the side name of the multiOwner
   * @return true if the address was added to the multiOwners list,
   *         false if the address was already in the multiOwners list
   */
  function addAddressAsMultiOwner(address _addr, string _side)
    onlyMultiOwners
    public
  {
    require(hasAuth(AUTH_ADDOWNER));

    addAddress(_addr, _side);

    clearAuth(AUTH_ADDOWNER);
    emit OwnerAdded(_addr, _side);
  }

  /**
   * @dev getter to determine if address is in multiOwner list
   */
  function isMultiOwner(address _addr)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, ROLE_MULTIOWNER);
  }

  /**
   * @dev remove an address from the whitelist
   * @param _addr address
   * @return true if the address was removed from the multiOwner list,
   *         false if the address wasn&#39;t in the multiOwner list
   */
  function removeAddressFromOwners(address _addr)
    onlyMultiOwners
    public
  {
    require(hasAuth(AUTH_REMOVEOWNER));

    removeRole(_addr, ROLE_MULTIOWNER);

    // first remove the owner
    uint j = 0;
    for (; j < owners.length; j = j.add(1)) {
      if (owners[j] == _addr) {
        delete owners[j];
        break;
      }
    }
    if (j < owners.length) {
      for (uint jj = j; jj < owners.length.sub(1); jj = jj.add(1)) {
        owners[jj] = owners[jj.add(1)];
      }

      delete owners[owners.length.sub(1)];
      owners.length = owners.length.sub(1);
    }

    string memory side = ownerOfSides[_addr];
    // if (sideExist[side] > 0) {
    sideExist[side] = sideExist[side].sub(1);
    if (sideExist[side] == 0) {
      require(multiOwnerSides > 2); // not allow only left 1 side
      multiOwnerSides = multiOwnerSides.sub(1); // this side has been removed
    }

    // for every event type, if this owner has voted the event, then need to remove
    for (uint i = 0; i < authTypes.length; ) {
      address[] storage voters = sideVoters[side][authTypes[i]];
      for (uint m = 0; m < voters.length; m = m.add(1)) {
        if (voters[m] == _addr) {
          delete voters[m];
          break;
        }
      }
      if (m < voters.length) {
        for (uint n = m; n < voters.length.sub(1); n = n.add(1)) {
          voters[n] = voters[n.add(1)];
        }

        delete voters[voters.length.sub(1)];
        voters.length = voters.length.sub(1);

        // if this side only have this 1 voter, the authorization of this event need to be decreased
        if (voters.length == 0) {
          authorizations[authTypes[i]] = authorizations[authTypes[i]].sub(1);
        }

        // if there is no authorization of this event, the event need to be removed
        if (authorizations[authTypes[i]] == 0) {
          delete authTypes[i];

          for (uint kk = i; kk < authTypes.length.sub(1); kk = kk.add(1)) {
            authTypes[kk] = authTypes[kk.add(1)];
          }

          delete authTypes[authTypes.length.sub(1)];
          authTypes.length = authTypes.length.sub(1);
        } else {
          i = i.add(1);
        }
      } else {
        i = i.add(1);
      }
    }
//   }

    delete ownerOfSides[_addr];

    clearAuth(AUTH_REMOVEOWNER);
    emit OwnerRemoved(_addr);
  }

}

contract MultiOwnerContract is MultiOwners {
    Claimable public ownedContract;
    address public pendingOwnedOwner;
    // address internal origOwner;

    string public constant AUTH_CHANGEOWNEDOWNER = "transferOwnerOfOwnedContract";

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    // modifier onlyPendingOwnedOwner() {
    //     require(msg.sender == pendingOwnedOwner);
    //     _;
    // }

    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
        // origOwner = ownedContract.owner();

        // take ownership of the owned contract
        ownedContract.claimOwnership();

        return true;
    }

    /**
     * @dev change the owner of the contract from this contract address to the original one.
     *
     */
    // function transferOwnershipBack() onlyOwner public {
    //     ownedContract.transferOwnership(origOwner);
    //     ownedContract = Claimable(address(0));
    //     origOwner = address(0);
    // }

    /**
     * @dev change the owner of the contract from this contract address to another one.
     *
     * @param _nextOwner the contract address that will be next Owner of the original Contract
     */
    function changeOwnedOwnershipto(address _nextOwner) onlyMultiOwners public {
        require(ownedContract != address(0));
        require(hasAuth(AUTH_CHANGEOWNEDOWNER));

        if (ownedContract.owner() != pendingOwnedOwner) {
            ownedContract.transferOwnership(_nextOwner);
            pendingOwnedOwner = _nextOwner;
            // ownedContract = Claimable(address(0));
            // origOwner = address(0);
        } else {
            // the pending owner has already taken the ownership
            ownedContract = Claimable(address(0));
            pendingOwnedOwner = address(0);
        }

        clearAuth(AUTH_CHANGEOWNEDOWNER);
    }

    function ownedOwnershipTransferred() onlyOwner public returns (bool) {
        require(ownedContract != address(0));
        if (ownedContract.owner() == pendingOwnedOwner) {
            // the pending owner has already taken the ownership
            ownedContract = Claimable(address(0));
            pendingOwnedOwner = address(0);
            return true;
        } else {
            return false;
        }
    }

}

contract DRCTOwner is MultiOwnerContract {
    string public constant AUTH_INITCONGRESS = "initCongress";
    string public constant AUTH_CANMINT = "canMint";
    string public constant AUTH_SETMINTAMOUNT = "setMintAmount";
    string public constant AUTH_FREEZEACCOUNT = "freezeAccount";

    bool congressInit = false;
    // bool paramsInit = false;
    // iParams public params;
    uint256 onceMintAmount;


    // function initParams(address _params) onlyOwner public {
    //     require(!paramsInit);
    //     require(_params != address(0));

    //     params = _params;
    //     paramsInit = false;
    // }

    /**
     * @dev Function to set mint token amount
     * @param _value The mint value.
     */
    function setOnceMintAmount(uint256 _value) onlyMultiOwners public {
        require(hasAuth(AUTH_SETMINTAMOUNT));
        require(_value > 0);
        onceMintAmount = _value;

        clearAuth(AUTH_SETMINTAMOUNT);
    }

    /**
     * @dev change the owner of the contract from this contract address to another one.
     *
     * @param _congress the contract address that will be next Owner of the original Contract
     */
    function initCongress(address _congress) onlyMultiOwners public {
        require(hasAuth(AUTH_INITCONGRESS));
        require(!congressInit);

        itoken tk = itoken(address(ownedContract));
        tk.initialCongress(_congress);

        clearAuth(AUTH_INITCONGRESS);
        congressInit = true;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to) onlyMultiOwners public returns (bool) {
        require(hasAuth(AUTH_CANMINT));

        itoken tk = itoken(address(ownedContract));
        bool res = tk.mint(_to, onceMintAmount);

        clearAuth(AUTH_CANMINT);
        return res;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyMultiOwners public returns (bool) {
        require(hasAuth(AUTH_CANMINT));

        itoken tk = itoken(address(ownedContract));
        bool res = tk.finishMinting();

        clearAuth(AUTH_CANMINT);
        return res;
    }

    /**
     * @dev freeze the account&#39;s balance under urgent situation
     *
     * by default all the accounts will not be frozen until set freeze value as true.
     *
     * @param _target address the account should be frozen
     * @param _freeze bool if true, the account will be frozen
     */
    function freezeAccountDirect(address _target, bool _freeze) onlyMultiOwners public {
        require(hasAuth(AUTH_FREEZEACCOUNT));

        require(_target != address(0));
        itoken tk = itoken(address(ownedContract));
        tk.freezeAccount(_target, _freeze);

        clearAuth(AUTH_FREEZEACCOUNT);
    }

    /**
     * @dev freeze the account&#39;s balance
     *
     * by default all the accounts will not be frozen until set freeze value as true.
     *
     * @param _target address the account should be frozen
     * @param _freeze bool if true, the account will be frozen
     */
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        require(_target != address(0));
        itoken tk = itoken(address(ownedContract));
        if (_freeze) {
            require(tk.allowance(_target, this) == tk.balanceOf(_target));
        }

        tk.freezeAccount(_target, _freeze);
    }

    /**
     * @dev freeze the account&#39;s balance
     *
     * @param _target address the account should be frozen
     * @param _value uint256 the amount of tokens that will be frozen
     */
    function freezeAccountPartialy(address _target, uint256 _value) onlyOwner public {
        require(_target != address(0));
        itoken tk = itoken(address(ownedContract));
        require(tk.allowance(_target, this) == _value);

        tk.freezeAccountPartialy(_target, _value);
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner public {
        itoken tk = itoken(address(ownedContract));
        tk.pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner public {
        itoken tk = itoken(address(ownedContract));
        tk.unpause();
    }

}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}