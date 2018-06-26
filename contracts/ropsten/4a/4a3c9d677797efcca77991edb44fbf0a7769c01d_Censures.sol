pragma solidity ^0.4.21;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/Ships.sol

//  the urbit ship data store

pragma solidity 0.4.24;


//  Ships: ship state data contract
//
//    This contract is used for storing all data related to Urbit addresses
//    and their ownership. Consider this contract the Urbit ledger.
//
//    It also contains permissions data, which ties in to ERC721
//    functionality. Operators of an address are allowed to transfer
//    ownership of all ships owned by their associated address
//    (ERC721&#39;s approveAll()). A transfer proxy is allowed to transfer
//    ownership of a single ship (ERC721&#39;s approve()).
//
//    Since data stores are difficult to upgrade, this contract contains
//    as little actual business logic as possible. Instead, the data stored
//    herein can only be modified by this contract&#39;s owner, which can be
//    changed and is thus upgradable/replacable.
//
//    Initially, this contract will be owned by the Constitution contract.
//
contract Ships is Ownable
{
  //  OwnerChanged: :ship is now owned by :owner
  //
  event OwnerChanged(uint32 indexed ship, address indexed owner);

  //  Activated: :ship is now activate
  //
  event Activated(uint32 indexed ship);

  //  Spawned: :parent has spawned :child.
  //
  event Spawned(uint32 indexed parent, uint32 child);

  //  EscapeRequested: :ship has requested a new sponsor, :sponsor
  //
  event EscapeRequested(uint32 indexed ship, uint32 indexed sponsor);

  //  EscapeCanceled: :ship&#39;s :sponsor request was canceled or rejected
  //
  event EscapeCanceled(uint32 indexed ship, uint32 indexed sponsor);

  //  EscapeAccepted: :ship confirmed with a new sponsor, :sponsor
  //
  event EscapeAccepted(uint32 indexed ship, uint32 indexed sponsor);

  //  LostSponsor: :ship&#39;s sponsor is now refusing it service
  //
  event LostSponsor(uint32 indexed ship, uint32 indexed sponsor);

  //  ChangedKeys: :ship has new Urbit public keys, :crypt and :auth
  //
  event ChangedKeys( uint32 indexed ship,
                     bytes32 encryptionKey,
                     bytes32 authenticationKey,
                     uint32 cryptoSuiteVersion,
                     uint32 keyRevisionNumber );

  //  BrokeContinuity: :ship has a new continuity number, :number.
  //
  event BrokeContinuity(uint32 indexed ship, uint32 number);

  //  ChangedSpawnProxy: :ship has a new spawn proxy
  //
  event ChangedSpawnProxy(uint32 indexed ship, address indexed spawnProxy);

  //  ChangedTransferProxy: :ship has a new transfer proxy
  //
  event ChangedTransferProxy( uint32 indexed ship,
                              address indexed transferProxy );

  //  ChangedDns: dnsDomains has been updated
  //
  event ChangedDns(string primary, string secondary, string tertiary);

  //  Class: classes of ship registered on-chain
  //
  enum Class
  {
    Galaxy,
    Star,
    Planet
  }

  //  Hull: state of a ship
  //
  struct Hull
  {
    //  owner: address that owns this ship
    //
    address owner;

    //  active: whether ship can be run
    //
    //    false: ship belongs to parent, cannot be booted
    //    true: ship has been, or can be, booted
    //
    bool active;

    //  encryptionKey: Urbit curve25519 encryption key, or 0 for none
    //
    bytes32 encryptionKey;

    //  authenticationKey: Urbit ed25519 authentication key, or 0 for none
    //
    bytes32 authenticationKey;

    //  cryptoSuiteNumber: version of the Urbit crypto suite used
    //
    uint32 cryptoSuiteVersion;

    //  keyRevisionNumber: incremented every time we change the keys
    //
    uint32 keyRevisionNumber;

    //  continuityNumber: incremented to indicate Urbit-side state loss
    //
    uint32 continuityNumber;

    //  spawnCount: for stars and galaxies, number of :active children
    //
    uint32 spawnCount;

    //  spawned: for stars and galaxies, all :active children
    //
    uint32[] spawned;

    //  sponsor: ship that supports this one on the network, or,
    //           if :hasSponsor is false, the last ship that supported it.
    //           (by default, the ship&#39;s half-width prefix)
    //
    uint32 sponsor;

    //  hasSponsor: true if the sponsor still supports the ship
    //
    bool hasSponsor;

    //  escapeRequested: true if the ship has requested to change sponsors
    //
    bool escapeRequested;

    //  escapeRequestedTo: if :escapeRequested is set, new sponsor requested
    //
    uint32 escapeRequestedTo;

    //  spawnProxy: 0, or another address with the right to spawn children
    //
    address spawnProxy;

    //  transferProxy: 0, or another address with the right to transfer owners
    //
    address transferProxy;
  }

  //  ships: all Urbit ship state
  //
  mapping(uint32 => Hull) public ships;

  //  shipsOwnedBy: per address, list of ships owned
  //
  mapping(address => uint32[]) public shipsOwnedBy;

  //  shipOwnerIndexes: per owner per ship, (index + 1) in shipsOwnedBy array
  //
  //    We delete owners by moving the last entry in the array to the
  //    newly emptied slot, which is (n - 1) where n is the value of
  //    shipOwnerIndexes[owner][ship].
  //
  mapping(address => mapping(uint32 => uint256)) public shipOwnerIndexes;

  //  operators: per owner, per address, has the right to transfer ownership
  //
  mapping(address => mapping(address => bool)) public operators;

  //  transferringFor: per address, the ships they are transfer proxy for
  //
  mapping(address => uint32[]) public transferringFor;

  //  transferringForIndexes: per address, per ship, (index + 1) in
  //                          the transferringFor array
  //
  mapping(address => mapping(uint32 => uint256)) public transferringForIndexes;

  //  spawningFor: per address, the ships they are spawn proxy for
  //
  mapping(address => uint32[]) public spawningFor;

  //  spawningForIndexes: per address, per ship, (index + 1) in
  //                      the spawningFor array
  //
  mapping(address => mapping(uint32 => uint256)) public spawningForIndexes;

  //  dnsDomains: base domains for contacting galaxies in urbit
  //
  //    dnsDomains[0] is primary, the others are used as fallbacks
  //
  string[3] public dnsDomains;

  //  constructor(): configure default dns domains
  //
  constructor()
    public
  {
    setDnsDomains(&quot;urbit.org&quot;, &quot;urbit.org&quot;, &quot;urbit.org&quot;);
  }

  //
  //  Getters, setters and checks
  //

    //  setDnsDomains(): set the base domains used for contacting galaxies
    //
    //    Note: since a string is really just a byte[], and Solidity can&#39;t
    //    work with two-dimensional arrays yet, we pass in the three
    //    domains as individual strings.
    //
    function setDnsDomains(string _primary, string _secondary, string _tertiary)
      onlyOwner
      public
    {
      dnsDomains[0] = _primary;
      dnsDomains[1] = _secondary;
      dnsDomains[2] = _tertiary;
      emit ChangedDns(_primary, _secondary, _tertiary);
    }

    //  getOwnedShips(): return array of ships that :msg.sender owns
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getOwnedShips()
      view
      external
      returns (uint32[] ownedShips)
    {
      return shipsOwnedBy[msg.sender];
    }

    //  getOwnedShipsByAddress(): return array of ships that _whose owns
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getOwnedShipsByAddress(address _whose)
      view
      external
      returns (uint32[] ownedShips)
    {
      return shipsOwnedBy[_whose];
    }

    //  getOwnedShipCount(): return length of array of ships that _whose owns
    //
    function getOwnedShipCount(address _whose)
      view
      external
      returns (uint256 count)
    {
      return shipsOwnedBy[_whose].length;
    }

    //  getOwnedShipAtIndex(): get ship at _index from array of ships that
    //                         _whose owns
    //
    function getOwnedShipAtIndex(address _whose, uint256 _index)
      view
      external
      returns (uint32 ship)
    {
      uint32[] storage owned = shipsOwnedBy[_whose];
      require(_index < owned.length);
      return owned[_index];
    }

    //  isOwner(): true if _ship is owned by _address
    //
    function isOwner(uint32 _ship, address _address)
      view
      external
      returns (bool result)
    {
      return (ships[_ship].owner == _address);
    }

    //  getOwner(): return owner of _ship
    //
    function getOwner(uint32 _ship)
      view
      external
      returns (address owner)
    {
      return ships[_ship].owner;
    }

    //  setOwner(): set owner of _ship to _owner
    //
    //    Note: setOwner() only implements the minimal data storage
    //    logic for a transfer; use the constitution contract for a
    //    full transfer.
    //
    //    Note: _owner must not equal the present owner or the zero address.
    //
    function setOwner(uint32 _ship, address _owner)
      onlyOwner
      external
    {
      //  prevent burning of ships by making zero the owner
      //
      require(0x0 != _owner);

      //  prev: previous owner, if any
      //
      address prev = ships[_ship].owner;

      if (prev == _owner)
      {
        return;
      }

      //  if the ship used to have a different owner, do some gymnastics to
      //  keep the list of owned ships gapless.  delete this ship from the
      //  list, then fill that gap with the list tail.
      //
      if (0x0 != prev)
      {
        //  i: current index in previous owner&#39;s list of owned ships
        //
        uint256 i = shipOwnerIndexes[prev][_ship];

        //  we store index + 1, because 0 is the solidity default value
        //
        assert(i > 0);
        i--;

        //  copy the last item in the list into the now-unused slot,
        //  making sure to update its :shipOwnerIndexes reference
        //
        uint32[] storage owner = shipsOwnedBy[prev];
        uint256 last = owner.length - 1;
        uint32 moved = owner[last];
        owner[i] = moved;
        shipOwnerIndexes[prev][moved] = i + 1;

        //  delete the last item
        //
        delete(owner[last]);
        owner.length = last;
        shipOwnerIndexes[prev][_ship] = 0;
      }

      //  update the owner list and the owner&#39;s index list
      //
      ships[_ship].owner = _owner;
      shipsOwnedBy[_owner].push(_ship);
      shipOwnerIndexes[_owner][_ship] = shipsOwnedBy[_owner].length;
      emit OwnerChanged(_ship, _owner);
    }

    //  isActive(): return true if ship is active
    //
    function isActive(uint32 _ship)
      view
      external
      returns (bool equals)
    {
      return ships[_ship].active;
    }

    //  activateShip(): activate a ship, register it as spawned by its parent
    //
    function activateShip(uint32 _ship)
      onlyOwner
      external
    {
      //  make a ship active, setting its sponsor to its prefix
      //
      Hull storage ship = ships[_ship];
      require(!ship.active);
      ship.active = true;
      uint32 prefix = getPrefix(_ship);
      ship.sponsor = prefix;
      ship.hasSponsor = true;

      //  register a new spawned ship for the prefix
      //
      ships[prefix].spawnCount++;
      ships[prefix].spawned.push(_ship);
      emit Spawned(prefix, _ship);

      emit Activated(_ship);
    }

    function getKeys(uint32 _ship)
      view
      external
      returns (bytes32 crypt, bytes32 auth, uint32 suite, uint32 revision)
    {
      Hull storage ship = ships[_ship];
      return (ship.encryptionKey,
              ship.authenticationKey,
              ship.cryptoSuiteVersion,
              ship.keyRevisionNumber);
    }

    function getKeyRevisionNumber(uint32 _ship)
      view
      external
      returns (uint32 revision)
    {
      return ships[_ship].keyRevisionNumber;
    }

    //  hasBeenBooted(): returns true if the ship has ever been assigned keys
    //
    function hasBeenBooted(uint32 _ship)
      view
      external
      returns (bool result)
    {
      return ( ships[_ship].keyRevisionNumber > 0 );
    }

    //  setKeys(): set Urbit public keys of _ship to _encryptionKey and
    //            _authenticationKey
    //
    function setKeys(uint32 _ship,
                     bytes32 _encryptionKey,
                     bytes32 _authenticationKey,
                     uint32 _cryptoSuiteVersion)
      onlyOwner
      external
    {
      Hull storage ship = ships[_ship];
      if ( ship.encryptionKey == _encryptionKey &&
           ship.authenticationKey == _authenticationKey &&
           ship.cryptoSuiteVersion == _cryptoSuiteVersion )
      {
        return;
      }

      ship.encryptionKey = _encryptionKey;
      ship.authenticationKey = _authenticationKey;
      ship.cryptoSuiteVersion = _cryptoSuiteVersion;
      ship.keyRevisionNumber++;

      emit ChangedKeys(_ship,
                       _encryptionKey,
                       _authenticationKey,
                       _cryptoSuiteVersion,
                       ship.keyRevisionNumber);
    }

    function getContinuityNumber(uint32 _ship)
      view
      external
      returns (uint32 continuityNumber)
    {
      return ships[_ship].continuityNumber;
    }

    function incrementContinuityNumber(uint32 _ship)
      onlyOwner
      external
    {
      Hull storage ship = ships[_ship];
      ship.continuityNumber++;
      emit BrokeContinuity(_ship, ship.continuityNumber);
    }

    //  getSpawnCount(): return the number of children spawned by _ship
    //
    function getSpawnCount(uint32 _ship)
      view
      external
      returns (uint32 spawnCount)
    {
      return ships[_ship].spawnCount;
    }

    //  getSpawned(): return array ships spawned under _ship
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getSpawned(uint32 _ship)
      view
      external
      returns (uint32[] spawned)
    {
      return ships[_ship].spawned;
    }

    function getSponsor(uint32 _ship)
      view
      external
      returns (uint32 sponsor)
    {
      return ships[_ship].sponsor;
    }

    function hasSponsor(uint32 _ship)
      view
      external
      returns (bool has)
    {
      return ships[_ship].hasSponsor;
    }

    function isSponsor(uint32 _ship, uint32 _sponsor)
      view
      external
      returns (bool result)
    {
      Hull storage ship = ships[_ship];
      return ( ship.hasSponsor &&
               (ship.sponsor == _sponsor) );
    }

    function loseSponsor(uint32 _ship)
      onlyOwner
      external
    {
      Hull storage ship = ships[_ship];
      if (!ship.hasSponsor)
      {
        return;
      }
      ship.hasSponsor = false;
      emit LostSponsor(_ship, ship.sponsor);
    }

    function isEscaping(uint32 _ship)
      view
      external
      returns (bool escaping)
    {
      return ships[_ship].escapeRequested;
    }

    function getEscapeRequest(uint32 _ship)
      view
      external
      returns (uint32 escape)
    {
      return ships[_ship].escapeRequestedTo;
    }

    function isRequestingEscapeTo(uint32 _ship, uint32 _sponsor)
      view
      public
      returns (bool equals)
    {
      Hull storage ship = ships[_ship];
      return (ship.escapeRequested && (ship.escapeRequestedTo == _sponsor));
    }

    function setEscapeRequest(uint32 _ship, uint32 _sponsor)
      onlyOwner
      external
    {
      if (isRequestingEscapeTo(_ship, _sponsor))
      {
        return;
      }
      Hull storage ship = ships[_ship];
      ship.escapeRequestedTo = _sponsor;
      ship.escapeRequested = true;
      emit EscapeRequested(_ship, _sponsor);
    }

    function cancelEscape(uint32 _ship)
      onlyOwner
      external
    {
      Hull storage ship = ships[_ship];
      if (!ship.escapeRequested)
      {
        return;
      }
      uint32 request = ship.escapeRequestedTo;
      ship.escapeRequestedTo = 0;
      ship.escapeRequested = false;
      emit EscapeCanceled(_ship, request);
    }

    //  doEscape(): perform the requested escape
    //
    function doEscape(uint32 _ship)
      onlyOwner
      external
    {
      Hull storage ship = ships[_ship];
      require(ship.escapeRequested);
      ship.sponsor = ship.escapeRequestedTo;
      ship.hasSponsor = true;
      ship.escapeRequestedTo = 0;
      ship.escapeRequested = false;
      emit EscapeAccepted(_ship, ship.sponsor);
    }

    function isSpawnProxy(uint32 _ship, address _spawner)
      view
      external
      returns (bool result)
    {
      return (ships[_ship].spawnProxy == _spawner);
    }

    function getSpawnProxy(uint32 _ship)
      view
      external
      returns (address spawnProxy)
    {
      return ships[_ship].spawnProxy;
    }

    function setSpawnProxy(uint32 _ship, address _spawner)
      onlyOwner
      external
    {
      Hull storage ship = ships[_ship];
      address prev = ship.spawnProxy;
      if (prev == _spawner)
      {
        return;
      }

      //  if the ship used to have a different spawn proxy, do some
      //  gymnastics to keep the reverse lookup gappless.  delete the ship
      //  from the old proxy&#39;s list, then fill that gap with the list tail.
      //
      if (0x0 != prev)
      {
        //  i: current index in previous proxy&#39;s list of spawning ships
        //
        uint256 i = spawningForIndexes[prev][_ship];

        //  we store index + 1, because 0 is the solidity default value
        //
        assert(i > 0);
        i--;

        //  copy the last item in the list into the now-unused slot,
        //  making sure to update its :spawningForIndexes reference
        //
        uint32[] storage prevSfor = spawningFor[prev];
        uint256 last = prevSfor.length - 1;
        uint32 moved = prevSfor[last];
        prevSfor[i] = moved;
        spawningForIndexes[prev][moved] = i + 1;

        //  delete the last item
        //
        delete(prevSfor[last]);
        prevSfor.length = last;
        spawningForIndexes[prev][_ship] = 0;
      }

      if (0x0 != _spawner)
      {
        uint32[] storage tfor = spawningFor[_spawner];
        tfor.push(_ship);
        spawningForIndexes[_spawner][_ship] = tfor.length;
      }

      ship.spawnProxy = _spawner;
      emit ChangedSpawnProxy(_ship, _spawner);
    }

    function getSpawningForCount(address _proxy)
      view
      external
      returns (uint256 count)
    {
      return spawningFor[_proxy].length;
    }

    //  getSpawningFor(): get the ships _proxy is a spawn proxy for
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getSpawningFor(address _proxy)
      view
      external
      returns (uint32[] tfor)
    {
      return spawningFor[_proxy];
    }

    function isTransferProxy(uint32 _ship, address _transferrer)
      view
      external
      returns (bool result)
    {
      return (ships[_ship].transferProxy == _transferrer);
    }

    function getTransferProxy(uint32 _ship)
      view
      external
      returns (address transferProxy)
    {
      return ships[_ship].transferProxy;
    }

    //  setTransferProxy(): configure _transferrer as transfer proxy for _ship
    //
    function setTransferProxy(uint32 _ship, address _transferrer)
      onlyOwner
      external
    {
      Hull storage ship = ships[_ship];
      address prev = ship.transferProxy;
      if (prev == _transferrer)
      {
        return;
      }

      //  if the ship used to have a different transfer proxy, do some
      //  gymnastics to keep the reverse lookup gappless.  delete the ship
      //  from the old proxy&#39;s list, then fill that gap with the list tail.
      //
      if (0x0 != prev)
      {
        //  i: current index in previous proxy&#39;s list of transferable ships
        //
        uint256 i = transferringForIndexes[prev][_ship];

        //  we store index + 1, because 0 is the solidity default value
        //
        assert(i > 0);
        i--;

        //  copy the last item in the list into the now-unused slot,
        //  making sure to update its :transferringForIndexes reference
        //
        uint32[] storage prevTfor = transferringFor[prev];
        uint256 last = prevTfor.length - 1;
        uint32 moved = prevTfor[last];
        prevTfor[i] = moved;
        transferringForIndexes[prev][moved] = i + 1;

        //  delete the last item
        //
        delete(prevTfor[last]);
        prevTfor.length = last;
        transferringForIndexes[prev][_ship] = 0;
      }

      if (0x0 != _transferrer)
      {
        uint32[] storage tfor = transferringFor[_transferrer];
        tfor.push(_ship);
        transferringForIndexes[_transferrer][_ship] = tfor.length;
      }

      ship.transferProxy = _transferrer;
      emit ChangedTransferProxy(_ship, _transferrer);
    }

    function getTransferringForCount(address _proxy)
      view
      external
      returns (uint256 count)
    {
      return transferringFor[_proxy].length;
    }

    //  getTransferringFor(): get the ships _proxy is a transfer proxy for
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getTransferringFor(address _proxy)
      view
      external
      returns (uint32[] tfor)
    {
      return transferringFor[_proxy];
    }

    function isOperator(address _owner, address _operator)
      view
      external
      returns (bool result)
    {
      return operators[_owner][_operator];
    }

    function setOperator(address _owner, address _operator, bool _approved)
      onlyOwner
      external
    {
      operators[_owner][_operator] = _approved;
    }

  //
  //  Utility functions
  //

    //  getPrefix(): compute prefix parent of _ship
    //
    function getPrefix(uint32 _ship)
      pure
      public
      returns (uint16 parent)
    {
      if (_ship < 65536)
      {
        return uint16(_ship % 256);
      }
      return uint16(_ship % 65536);
    }

    //  getShipClass(): return the class of _ship
    //
    function getShipClass(uint32 _ship)
      external
      pure
      returns (Class _class)
    {
      if (_ship < 256) return Class.Galaxy;
      if (_ship < 65536) return Class.Star;
      return Class.Planet;
    }
}

// File: contracts/ReadsShips.sol

//  contract that uses the Ships contract

pragma solidity 0.4.24;


//  ReadsShips: referring to and testing against the Ships contract
//
//    To avoid needless repetition, this contract provides common
//    checks and operations using the Ships contract.
//
contract ReadsShips
{
  //  ships: ships state data storage contract.
  //
  Ships public ships;

  //  constructor(): set the Ships contract&#39;s address
  //
  constructor(Ships _ships)
    public
  {
    ships = _ships;
  }

  //  activeShipOwner(): require that :msg.sender is the owner of _ship,
  //                     and that _ship is active
  //
  modifier activeShipOwner(uint32 _ship)
  {
    require( ships.isOwner(_ship, msg.sender) &&
             ships.isActive(_ship) );
    _;
  }
}

// File: contracts/Censures.sol

//  simple reputations store

pragma solidity 0.4.24;


//  Censures: simple reputation management
//
//    This contract allows stars and galaxies to assign a negative
//    reputation (censure) to other ships of the same or lower rank.
//    These censures are not permanent, they can be forgiven.
//
//    Since the Urbit network provides incentives for good behavior,
//    making bad behavior is the exception rather than the rule, this
//    only provides registration of negative reputation.
//
contract Censures is ReadsShips
{
  //  Censured: :who got censures by :by
  //
  event Censured(uint16 indexed by, uint32 indexed who);

  //  Forgiven: :who is no longer censured by :by
  //
  event Forgiven(uint16 indexed by, uint32 indexed who);

  //  censuring: per ship, the ships they&#39;re censuring
  //
  mapping(uint16 => uint32[]) public censuring;

  //  censuredBy: per ship, those who have censured them
  //
  mapping(uint32 => uint16[]) public censuredBy;

  //  censuringIndexes: per ship per censure, (index + 1) in censures array
  //
  //    We delete censures by moving the last entry in the array to the
  //    newly emptied slot, which is (n - 1) where n is the value of
  //    indexes[ship][censure].
  //
  mapping(uint16 => mapping(uint32 => uint256)) public censuringIndexes;

  //  censuredByIndexes: per censure per ship, (index + 1) in censured array
  //
  //    see also explanation for indexes_censures above
  //
  mapping(uint32 => mapping(uint16 => uint256)) public censuredByIndexes;

  //  constructor(): register the ships contract
  //
  constructor(Ships _ships)
    ReadsShips(_ships)
    public
  {
    //
  }

  //  getCensuringCount(): return length of array of censures made by _whose
  //
  function getCensuringCount(uint16 _whose)
    view
    public
    returns (uint256 count)
  {
    return censuring[_whose].length;
  }

  //  getCensuring(): return array of censures made by _whose
  //
  //    Note: only useful for clients, as Solidity does not currently
  //    support returning dynamic arrays.
  //
  function getCensuring(uint16 _whose)
    view
    public
    returns (uint32[] cens)
  {
    return censuring[_whose];
  }

  //  getCensuredByCount(): return length of array of censures made against _who
  //
  function getCensuredByCount(uint16 _who)
    view
    public
    returns (uint256 count)
  {
    return censuredBy[_who].length;
  }

  //  getCensuredBy(): return array of censures made against _who
  //
  //    Note: only useful for clients, as Solidity does not currently
  //    support returning dynamic arrays.
  //
  function getCensuredBy(uint16 _who)
    view
    public
    returns (uint16[] cens)
  {
    return censuredBy[_who];
  }

  //  censure(): register a censure of _who as _as
  //
  function censure(uint16 _as, uint32 _who)
    external
    activeShipOwner(_as)
  {
    require( //  can&#39;t censure self
             //
             (_as != _who) &&
             //
             //  must not haven censured _who already
             //
             (censuringIndexes[_as][_who] == 0) );

    //  only stars and galaxies may censure, and only galaxies may censure
    //  other galaxies. (enum gets smaller for higher ship classes)
    //
    Ships.Class asClass = ships.getShipClass(_as);
    Ships.Class whoClass = ships.getShipClass(_who);
    require( whoClass >= asClass );

    //  update contract state with the new censure
    //
    censuring[_as].push(_who);
    censuringIndexes[_as][_who] = censuring[_as].length;

    //  and update the reverse lookup
    //
    censuredBy[_who].push(_as);
    censuredByIndexes[_who][_as] = censuredBy[_who].length;

    emit Censured(_as, _who);
  }

  //  forgive(): unregister a censure of _who as _as
  //
  function forgive(uint16 _as, uint32 _who)
    external
    activeShipOwner(_as)
  {
    //  below, we perform the same logic twice: once on the canonical data,
    //  and once on the reverse lookup
    //
    //  i: current index in _as&#39;s list of censures
    //  j: current index in _who&#39;s list of ships that have censured it
    //
    uint256 i = censuringIndexes[_as][_who];
    uint256 j = censuredByIndexes[_who][_as];

    //  we store index + 1, because 0 is the eth default value
    //  can only delete an existing censure
    //
    require( (i > 0) && (j > 0) );
    i--;
    j--;

    //  copy last item in the list into the now-unused slot,
    //  making sure to update the :indexes_ references
    //
    uint32[] storage cens = censuring[_as];
    uint16[] storage cend = censuredBy[_who];
    uint256 lastCens = cens.length - 1;
    uint256 lastCend = cend.length - 1;
    uint32 movedCens = cens[lastCens];
    uint16 movedCend = cend[lastCend];
    cens[i] = movedCens;
    cend[j] = movedCend;
    censuringIndexes[_as][movedCens] = i + 1;
    censuredByIndexes[_who][movedCend] = j + 1;

    //  delete the last item
    //
    cens.length = lastCens;
    cend.length = lastCend;
    censuringIndexes[_as][_who] = 0;
    censuredByIndexes[_who][_as] = 0;

    emit Forgiven(_as, _who);
  }
}