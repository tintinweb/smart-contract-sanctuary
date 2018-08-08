pragma solidity 0.4.24;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
    setDnsDomains("urbit.org", "urbit.org", "urbit.org");
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

// File: contracts/Claims.sol

//  simple claims store

pragma solidity 0.4.24;


//  Claims: simple identity management
//
//    This contract allows ships to document claims about their owner.
//    Most commonly, these are about identity, with a claim&#39;s protocol
//    defining the context or platform of the claim, and its dossier
//    containing proof of its validity.
//    Ships are limited to a maximum of 16 claims.
//
//    For existing claims, the dossier can be updated, or the claim can
//    be removed entirely. It is recommended to remove any claims associated
//    with a ship when it is about to be transfered to a new owner.
//    For convenience, the owner of the Ships contract (the Constitution)
//    is allowed to clear claims for any ship, allowing it to do this for
//    you on-transfer.
//
contract Claims is ReadsShips
{
  //  ClaimAdded: a claim was addhd by :by
  //
  event ClaimAdded( uint32 indexed by,
                    string _protocol,
                    string _claim,
                    bytes _dossier );

  //  ClaimRemoved: a claim was removed by :by
  //
  event ClaimRemoved(uint32 indexed by, string _protocol, string _claim);

  //  maxClaims: the amount of claims that can be registered per ship
  //
  uint8 constant maxClaims = 16;

  //  Claim: claim details
  //
  struct Claim
  {
    //  protocol: context of the claim
    //
    string protocol;

    //  claim: the claim itself
    //
    string claim;

    //  dossier: data relating to the claim, as proof
    //
    bytes dossier;
  }

  //  per ship, list of claims
  //
  mapping(uint32 => Claim[maxClaims]) public claims;

  //  constructor(): register the ships contract.
  //
  constructor(Ships _ships)
    ReadsShips(_ships)
    public
  {
    //
  }

  //  addClaim(): register a claim as _ship
  //
  function addClaim(uint32 _ship,
                    string _protocol,
                    string _claim,
                    bytes _dossier)
    external
    activeShipOwner(_ship)
  {
    //  cur: index + 1 of the claim if it already exists, 0 otherwise
    //
    uint8 cur = findClaim(_ship, _protocol, _claim);

    //  if the claim doesn&#39;t yet exist, store it in state
    //
    if (cur == 0)
    {
      //  if there are no empty slots left, this throws
      //
      uint8 empty = findEmptySlot(_ship);
      claims[_ship][empty] = Claim(_protocol, _claim, _dossier);
    }
    //
    //  if the claim has been made before, update the version in state
    //
    else
    {
      claims[_ship][cur-1] = Claim(_protocol, _claim, _dossier);
    }
    emit ClaimAdded(_ship, _protocol, _claim, _dossier);
  }

  //  removeClaim(): unregister a claim as _ship
  //
  function removeClaim(uint32 _ship, string _protocol, string _claim)
    external
    activeShipOwner(_ship)
  {
    //  i: current index + 1 in _ship&#39;s list of claims
    //
    uint256 i = findClaim(_ship, _protocol, _claim);

    //  we store index + 1, because 0 is the eth default value
    //  can only delete an existing claim
    //
    require(i > 0);
    i--;

    //  clear out the claim
    //
    claims[_ship][i] = Claim(&#39;&#39;, &#39;&#39;, &#39;&#39;);

    emit ClaimRemoved(_ship, _protocol, _claim);
  }

  //  clearClaims(): unregister all of _ship&#39;s claims
  //
  //    can also be called by the constitution during ship transfer
  //
  function clearClaims(uint32 _ship)
    external
  {
    //  both ship owner and constitution may do this
    //
    require( ships.isOwner(_ship, msg.sender) ||
             ( msg.sender == ships.owner() ) );

    Claim[maxClaims] storage currClaims = claims[_ship];

    //  clear out all claims
    //
    for (uint8 i = 0; i < maxClaims; i++)
    {
      currClaims[i] = Claim(&#39;&#39;, &#39;&#39;, &#39;&#39;);
    }
  }

  //  findClaim(): find the index of the specified claim
  //
  //    returns 0 if not found, index + 1 otherwise
  //
  function findClaim(uint32 _whose, string _protocol, string _claim)
    public
    view
    returns (uint8 index)
  {
    //  we use hashes of the string because solidity can&#39;t do string
    //  comparison yet
    //
    bytes32 protocolHash = keccak256(bytes(_protocol));
    bytes32 claimHash = keccak256(bytes(_claim));
    Claim[maxClaims] storage theirClaims = claims[_whose];
    for (uint8 i = 0; i < maxClaims; i++)
    {
      Claim storage thisClaim = theirClaims[i];
      if ( ( protocolHash == keccak256(bytes(thisClaim.protocol)) ) &&
           ( claimHash == keccak256(bytes(thisClaim.claim)) ) )
      {
        return i+1;
      }
    }
    return 0;
  }

  //  findEmptySlot(): find the index of the first empty claim slot
  //
  //    returns the index of the slot, throws if there are no empty slots
  //
  function findEmptySlot(uint32 _whose)
    internal
    view
    returns (uint8 index)
  {
    Claim[maxClaims] storage theirClaims = claims[_whose];
    for (uint8 i = 0; i < maxClaims; i++)
    {
      Claim storage thisClaim = theirClaims[i];
      if ( (0 == bytes(thisClaim.protocol).length) &&
           (0 == bytes(thisClaim.claim).length) )
      {
        return i;
      }
    }
    revert();
  }
}

// File: contracts/SafeMath8.sol

/**
 * @title SafeMath8
 * @dev Math operations for uint8 with safety checks that throw on error
 */
library SafeMath8 {
  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint8 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    assert(b <= a);
    return a - b;
  }

  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/Polls.sol

//  the urbit polls data store

pragma solidity 0.4.24;




//  Polls: proposals & votes data contract
//
//    This contract is used for storing all data related to the proposals
//    of the senate (galaxy owners) and their votes on those proposals.
//    It keeps track of votes and uses them to calculate whether a majority
//    is in favor of a proposal.
//
//    Every galaxy can only vote on a proposal exactly once. Votes cannot
//    be changed. If a proposal fails to achieve majority within its
//    duration, it can be restarted after its cooldown period has passed.
//
//    The requirements for a proposal to achieve majority are as follows:
//    - At least 1/4 of the currently active voters (rounded down) must have
//      voted in favor of the proposal,
//    - More than half of the votes cast must be in favor of the proposal,
//      and this can no longer change, either because
//      - the poll duration has passed, or
//      - not enough voters remain to take away the in-favor majority.
//    As soon as these conditions are met, no further interaction with
//    the proposal is possible. Achieving majority is permanent.
//
//    Since data stores are difficult to upgrade, all of the logic unrelated
//    to the voting itself (that is, determining who is eligible to vote)
//    is expected to be implemented by this contract&#39;s owner.
//
//    Initially, this contract will be owned by the Constitution contract.
//
contract Polls is Ownable
{
  using SafeMath for uint256;
  using SafeMath8 for uint8;

  //  ConstitutionPollStarted: a poll on :proposal has opened
  //
  event ConstitutionPollStarted(address proposal);

  //  DocumentPollStarted: a poll on :proposal has opened
  //
  event DocumentPollStarted(bytes32 proposal);

  //  ConstitutionMajority: :proposal has achieved majority
  //
  event ConstitutionMajority(address proposal);

  //  DocumentMajority: :proposal has achieved majority
  //
  event DocumentMajority(bytes32 proposal);

  //  Poll: full poll state
  //
  struct Poll
  {
    //  start: the timestamp at which the poll was started
    //
    uint256 start;

    //  voted: per galaxy, whether they have voted on this poll
    //
    bool[256] voted;

    //  yesVotes: amount of votes in favor of the proposal
    //
    uint8 yesVotes;

    //  noVotes: amount of votes against the proposal
    //
    uint8 noVotes;

    //  duration: amount of time during which the poll can be voted on
    //
    uint256 duration;

    //  cooldown: amount of time before the (non-majority) poll can be reopened
    //
    uint256 cooldown;
  }

  //  pollDuration: duration set for new polls. see also Poll.duration above
  //
  uint256 public pollDuration;

  //  pollCooldown: cooldown set for new polls. see also Poll.cooldown above
  //
  uint256 public pollCooldown;

  //  totalVoters: amount of active galaxies
  //
  uint8 public totalVoters;

  //  constitutionPolls: per address, poll held to determine if that address
  //                 will become the new constitution
  //
  mapping(address => Poll) public constitutionPolls;

  //  constitutionHasAchievedMajority: per address, whether that address
  //                                   has everachieved majority
  //
  //    if we did not store this, we would have to look at old poll data
  //    to see whether or not a proposal has ever achieved majority.
  //    since the outcome of a poll is calculated based on :totalVoters,
  //    which may not be consistent accross time, we need to store outcomes
  //    explicitly instead of re-calculating them, so that we can always
  //    tell with certainty whether or not a majority was achieved,
  //    regardless of the current :totalVoters.
  //
  mapping(address => bool) public constitutionHasAchievedMajority;

  //  documentPolls: per hash, poll held to determine if the corresponding
  //                 document is accepted by the galactic senate
  //
  mapping(bytes32 => Poll) public documentPolls;

  //  documentHasAchievedMajority: per hash, whether that hash has ever
  //                               achieved majority
  //
  //    the note for constitutionHasAchievedMajority above applies here as well
  //
  mapping(bytes32 => bool) public documentHasAchievedMajority;

  //  documentMajorities: all hashes that have achieved majority
  //
  bytes32[] public documentMajorities;

  //  constructor(): initial contract configuration
  //
  constructor(uint256 _pollDuration, uint256 _pollCooldown)
    public
  {
    reconfigure(_pollDuration, _pollCooldown);
  }

  //  reconfigure(): change poll duration and cooldown
  //
  function reconfigure(uint256 _pollDuration, uint256 _pollCooldown)
    public
    onlyOwner
  {
    require( (5 days <= _pollDuration) && (_pollDuration <= 90 days) &&
             (5 days <= _pollCooldown) && (_pollCooldown <= 90 days) );
    pollDuration = _pollDuration;
    pollCooldown = _pollCooldown;
  }

  //  incrementTotalVoters(): increase the amount of registered voters
  //
  function incrementTotalVoters()
    external
    onlyOwner
  {
    require(totalVoters < 255);
    totalVoters = totalVoters.add(1);
  }

  //  getDocumentMajorities(): return array of all document majorities
  //
  //    Note: only useful for clients, as Solidity does not currently
  //    support returning dynamic arrays.
  //
  function getDocumentMajorities()
    external
    view
    returns (bytes32[] majorities)
  {
    return documentMajorities;
  }

  //  hasVotedOnConstitutionPoll(): returns true if _galaxy has voted
  //                                on the _proposal
  //
  function hasVotedOnConstitutionPoll(uint8 _galaxy, address _proposal)
    external
    view
    returns (bool result)
  {
    return constitutionPolls[_proposal].voted[_galaxy];
  }

  //  hasVotedOnDocumentPoll(): returns true if _galaxy has voted
  //                            on the _proposal
  //
  function hasVotedOnDocumentPoll(uint8 _galaxy, bytes32 _proposal)
    external
    view
    returns (bool result)
  {
    return documentPolls[_proposal].voted[_galaxy];
  }

  //  startConstitutionPoll(): open a poll on making _proposal the new constitution
  //
  function startConstitutionPoll(address _proposal)
    external
    onlyOwner
  {
    //  _proposal must not have achieved majority before
    //
    require(!constitutionHasAchievedMajority[_proposal]);

    //  start the poll
    //
    Poll storage poll = constitutionPolls[_proposal];
    startPoll(poll);
    emit ConstitutionPollStarted(_proposal);
  }

  //  startDocumentPoll(): open a poll on accepting the document
  //                       whose hash is _proposal
  //
  function startDocumentPoll(bytes32 _proposal)
    external
    onlyOwner
  {
    //  _proposal must not have achieved majority before
    //
    require(!documentHasAchievedMajority[_proposal]);

    //  start the poll
    //
    Poll storage poll = documentPolls[_proposal];
    startPoll(poll);
    emit DocumentPollStarted(_proposal);
  }

  //  startPoll(): open a new poll, or re-open an old one
  //
  function startPoll(Poll storage _poll)
    internal
  {
    //  check that the poll has cooled down enough to be started again
    //
    //    for completely new polls, the values used will be zero
    //
    require( block.timestamp > ( _poll.start.add(
                                 _poll.duration.add(
                                 _poll.cooldown )) ) );

    //  set started poll state
    //
    _poll.start = block.timestamp;
    delete _poll.voted;
    _poll.yesVotes = 0;
    _poll.noVotes = 0;
    _poll.duration = pollDuration;
    _poll.cooldown = pollCooldown;
  }

  //  castConstitutionVote(): as galaxy _as, cast a vote on the _proposal
  //
  //    _vote is true when in favor of the proposal, false otherwise
  //
  function castConstitutionVote(uint8 _as, address _proposal, bool _vote)
    external
    onlyOwner
    returns (bool majority)
  {
    Poll storage poll = constitutionPolls[_proposal];
    processVote(poll, _as, _vote);
    return updateConstitutionPoll(_proposal);
  }

  //  castDocumentVote(): as galaxy _as, cast a vote on the _proposal
  //
  //    _vote is true when in favor of the proposal, false otherwise
  //
  function castDocumentVote(uint8 _as, bytes32 _proposal, bool _vote)
    external
    onlyOwner
    returns (bool majority)
  {
    Poll storage poll = documentPolls[_proposal];
    processVote(poll, _as, _vote);
    return updateDocumentPoll(_proposal);
  }

  //  processVote(): record a vote from _as on the _poll
  //
  function processVote(Poll storage _poll, uint8 _as, bool _vote)
    internal
  {
    //  assist symbolic execution tools
    //
    assert(block.timestamp >= _poll.start);

    require( //  may only vote once
             //
             !_poll.voted[_as] &&
             //
             //  may only vote when the poll is open
             //
             (block.timestamp < _poll.start.add(_poll.duration)) );

    //  update poll state to account for the new vote
    //
    _poll.voted[_as] = true;
    if (_vote)
    {
      _poll.yesVotes = _poll.yesVotes.add(1);
    }
    else
    {
      _poll.noVotes = _poll.noVotes.add(1);
    }
  }

  //  updateConstitutionPoll(): check whether the _proposal has achieved
  //                            majority, updating state, sending an event,
  //                            and returning true if it has
  //
  function updateConstitutionPoll(address _proposal)
    public
    onlyOwner
    returns (bool majority)
  {
    //  _proposal must not have achieved majority before
    //
    require(!constitutionHasAchievedMajority[_proposal]);

    //  check for majority in the poll
    //
    Poll storage poll = constitutionPolls[_proposal];
    majority = checkPollMajority(poll);

    //  if majority was achieved, update the state and send an event
    //
    if (majority)
    {
      constitutionHasAchievedMajority[_proposal] = true;
      emit ConstitutionMajority(_proposal);
    }
    return majority;
  }

  //  updateDocumentPoll(): check whether the _proposal has achieved majority,
  //                        updating the state and sending an event if it has
  //
  //    this can be called by anyone, because the constitution does not
  //    need to be aware of the result
  //
  function updateDocumentPoll(bytes32 _proposal)
    public
    returns (bool majority)
  {
    //  _proposal must not have achieved majority before
    //
    require(!documentHasAchievedMajority[_proposal]);

    //  check for majority in the poll
    //
    Poll storage poll = documentPolls[_proposal];
    majority = checkPollMajority(poll);

    //  if majority was achieved, update state and send an event
    //
    if (majority)
    {
      documentHasAchievedMajority[_proposal] = true;
      documentMajorities.push(_proposal);
      emit DocumentMajority(_proposal);
    }
    return majority;
  }

  //  checkPollMajority(): returns true if the majority is in favor of
  //                       the subject of the poll
  //
  function checkPollMajority(Poll _poll)
    internal
    view
    returns (bool majority)
  {
    //  remainingVotes: amount of votes that can still be cast
    //
    uint8 remainingVotes = totalVoters.sub( _poll.yesVotes.add(_poll.noVotes) );
    int16 score = int16(_poll.yesVotes) - _poll.noVotes;

    return ( //  poll must have at least the minimum required yes-votes
             //
             (_poll.yesVotes >= (totalVoters / 4)) &&
             //
             //  and have a majority...
             //
             (_poll.yesVotes > _poll.noVotes) &&
             //
             //  ...that is indisputable
             //
             ( //  either because the poll has ended
               //
               (block.timestamp > _poll.start.add(_poll.duration)) ||
               //
               //  or because there aren&#39;t enough remaining voters to
               //  tip the scale
               //
               (score > remainingVotes) ) );
  }
}

// File: contracts/interfaces/ENS.sol

// https://github.com/ethereum/ens/blob/master/contracts/ENS.sol

pragma solidity ^0.4.18;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
    function setResolver(bytes32 node, address resolver) public;
    function setOwner(bytes32 node, address owner) public;
    function setTTL(bytes32 node, uint64 ttl) public;
    function owner(bytes32 node) public view returns (address);
    function resolver(bytes32 node) public view returns (address);
    function ttl(bytes32 node) public view returns (uint64);

}

// File: contracts/interfaces/ResolverInterface.sol

// https://github.com/ethereum/ens/blob/master/contracts/ResolverInterface.sol

pragma solidity ^0.4.18;

contract ResolverInterface {
    function PublicResolver(address ensAddr) public;
    function setAddr(bytes32 node, address addr) public;
    function setHash(bytes32 node, bytes32 hash) public;
    function addr(bytes32 node) public view returns (address);
    function hash(bytes32 node) public view returns (bytes32);
    function supportsInterface(bytes4 interfaceID) public pure returns (bool);
}

// File: contracts/ConstitutionBase.sol

//  base contract for the urbit constitution
//  encapsulates dependencies all constitutions need.

pragma solidity 0.4.24;






//  ConstitutionBase: upgradable constitution
//
//    This contract implements the upgrade logic for the Constitution.
//    Newer versions of the Constitution are expected to provide at least
//    the onUpgrade() function. If they don&#39;t, upgrading to them will fail.
//
//    Note that even though this contract doesn&#39;t specify any required
//    interface members aside from upgrade() and onUpgrade(), contracts
//    and clients may still rely on the presence of certain functions
//    provided by the Constitution proper. Keep this in mind when writing
//    updated versions of it.
//
contract ConstitutionBase is Ownable, ReadsShips
{
  event Upgraded(address to);

  //  polls: senate voting contract
  //
  Polls public polls;

  //  ens: ENS registry where ownership of the urbit domain is registered
  //
  ENS public ens;

  //  previousConstitution: address of the previous constitution this
  //                        instance expects to upgrade from, stored and
  //                        checked for to prevent unexpected upgrade paths
  //
  address public previousConstitution;

  //  baseNode: namehash of the urbit ens node
  //  subLabel: hash of the constitution&#39;s subdomain (without base domain)
  //  subNode:  namehash of the constitution&#39;s subnode
  //
  bytes32 public baseNode;
  bytes32 public subLabel;
  bytes32 public subNode;

  constructor(address _previous,
              Ships _ships,
              Polls _polls,
              ENS _ensRegistry,
              string _baseEns,
              string _subEns)
    ReadsShips(_ships)
    internal
  {
    previousConstitution = _previous;
    polls = _polls;
    ens = _ensRegistry;
    subLabel = keccak256(abi.encodePacked(_subEns));
    baseNode = keccak256(abi.encodePacked(
                 keccak256(abi.encodePacked( bytes32(0), keccak256(&#39;eth&#39;) )),
                 keccak256(abi.encodePacked( _baseEns )) ));
    subNode = keccak256(abi.encodePacked( baseNode, subLabel ));
  }

  //  onUpgrade(): called by previous constitution when upgrading
  //
  //    in future constitutions, this might perform more logic than
  //    just simple checks and verifications.
  //    when overriding this, make sure to call the original as well.
  //
  function onUpgrade()
    external
  {
    //  make sure this is the expected upgrade path,
    //  and that we have gotten the ownership we require
    //
    require( msg.sender == previousConstitution &&
             this == ships.owner() &&
             this == polls.owner() &&
             this == ens.owner(baseNode) &&
             this == ens.owner(subNode) );
  }

  //  upgrade(): transfer ownership of the constitution data to the new
  //             constitution contract, notify it, then self-destruct.
  //
  //    Note: any eth that have somehow ended up in the contract are also
  //          sent to the new constitution.
  //
  function upgrade(ConstitutionBase _new)
    internal
  {
    //  transfer ownership of the data contracts
    //
    ships.transferOwnership(_new);
    polls.transferOwnership(_new);

    //  make the ens resolver point to the new address, then transfer
    //  ownership of the urbit & constitution nodes to the new constitution.
    //
    //    Note: we&#39;re assuming we only register a resolver for the base node
    //          and don&#39;t have one registered for subnodes.
    //
    ResolverInterface resolver = ResolverInterface(ens.resolver(baseNode));
    resolver.setAddr(subNode, _new);
    ens.setSubnodeOwner(baseNode, subLabel, _new);
    ens.setOwner(baseNode, _new);

    //  trigger upgrade logic on the target contract
    //
    _new.onUpgrade();

    //  emit event and destroy this contract
    //
    emit Upgraded(_new);
    selfdestruct(_new);
  }
}

// File: contracts/interfaces/ERC165.sol

// from https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md

pragma solidity 0.4.24;

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts/ERC165Mapping.sol

// from https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md

pragma solidity 0.4.24;


contract ERC165Mapping is ERC165 {
    /// @dev You must not set element 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() internal {
        supportedInterfaces[this.supportsInterface.selector] = true;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return supportedInterfaces[interfaceID];
    }
}

// File: zeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: zeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: zeppelin-solidity/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: zeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   *  after a `safetransfer`. This function MAY throw to revert and reject the
   *  transfer. This function MUST use 50,000 gas or less. Return of other
   *  than the magic value MUST result in the transaction being reverted.
   *  Note: the contract address is always the message sender.
   * @param _from The sending address
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
   */
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

// File: contracts/Constitution.sol

//  the urbit ethereum constitution

pragma solidity 0.4.24;








//  Constitution: logic for interacting with the Urbit ledger
//
//    This contract is the point of entry for all operations on the Urbit
//    ledger as stored in the Ships contract. The functions herein are
//    responsible for performing all necessary business logic.
//    Examples of such logic include verifying permissions of the caller
//    and ensuring a requested change is actually valid.
//
//    This contract uses external contracts (Ships, Polls) for data storage
//    so that it itself can easily be replaced in case its logic needs to
//    be changed. In other words, it can be upgraded. It does this by passing
//    ownership of the data contracts to a new Constitution contract.
//
//    Because of this, it is advised for clients to not store this contract&#39;s
//    address directly, but rather ask the Ships contract for its owner
//    attribute to ensure transactions get sent to the latest Constitution.
//
//    Upgrading happens based on polls held by the senate (galaxy owners).
//    Through this contract, the senate can submit proposals, opening polls
//    for the senate to cast votes on. These proposals can be either hashes
//    of documents or addresses of new Constitutions.
//    If a constitution proposal gains majority, this contract will transfer
//    ownership of the data storage contracts to that address, so that it may
//    operate on the date they contain. This contract will selfdestruct at
//    the end of the upgrade process.
//
//    This contract implements the ERC721 interface for non-fungible tokens,
//    allowing ships to be managed using generic clients that support the
//    standard. It also implements ERC165 to allow this to be discovered.
//
contract Constitution is ConstitutionBase, ERC165Mapping, ERC721Metadata
{
  using SafeMath for uint256;
  using AddressUtils for address;

  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved,
                 uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator,
                       bool _approved);

  // erc721Received: equal to:
  //               bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  //                 which can be also obtained as:
  //               ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant erc721Received = 0xf0b9e5ba;

  //  claims: contract reference, for clearing claims on-transfer
  //
  Claims public claims;

  //  constructor(): set Urbit data addresses and signal interface support
  //
  //    Note: during first deploy, ownership of these contracts must be
  //    manually transferred to this contract after it&#39;s on the chain and
  //    its address is known.
  //
  constructor(address _previous,
              Ships _ships,
              Polls _polls,
              ENS _ensRegistry,
              string _baseEns,
              string _subEns,
              Claims _claims)
    ConstitutionBase(_previous, _ships, _polls, _ensRegistry, _baseEns, _subEns)
    public
  {
    claims = _claims;

    //  register supported interfaces for ERC165
    //
    supportedInterfaces[0x80ac58cd] = true; // ERC721
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }

  //
  //  ERC721 interface
  //

    //  balanceOf(): get the amount of ships owned by _owner
    //
    function balanceOf(address _owner)
      public
      view
      returns (uint256 balance)
    {
      require(0x0 != _owner);
      return ships.getOwnedShipCount(_owner);
    }

    //  ownerOf(): get the current owner of ship _tokenId
    //
    function ownerOf(uint256 _tokenId)
      public
      view
      validShipId(_tokenId)
      returns (address owner)
    {
      uint32 id = uint32(_tokenId);

      //  this will throw if the owner is the zero address,
      //  active ships always have a valid owner.
      //
      require(ships.isActive(id));

      owner = ships.getOwner(id);
    }

    //  exists(): returns true if ship _tokenId is active
    //
    function exists(uint256 _tokenId)
      public
      view
      returns (bool doesExist)
    {
      return ( (_tokenId < 4294967296) &&
               ships.isActive(uint32(_tokenId)) );
    }

    //  safeTransferFrom(): transfer ship _tokenId from _from to _to
    //
    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
      public
    {
      //  transfer with empty data
      //
      safeTransferFrom(_from, _to, _tokenId, "");
    }

    //  safeTransferFrom(): transfer ship _tokenId from _from to _to,
    //                      and call recipient if it&#39;s a contract
    //
    function safeTransferFrom(address _from, address _to, uint256 _tokenId,
                              bytes _data)
      public
    {
      //  perform raw transfer
      //
      transferFrom(_from, _to, _tokenId);

      //  do the callback last to avoid re-entrancy
      //
      if (_to.isContract())
      {
        bytes4 retval = ERC721Receiver(_to)
                        .onERC721Received(_from, _tokenId, _data);
        //
        //  standard return idiom to confirm contract semantics
        //
        require(retval == erc721Received);
      }
    }

    //  transferFrom(): transfer ship _tokenId from _from to _to,
    //                  WITHOUT notifying recipient contract
    //
    function transferFrom(address _from, address _to, uint256 _tokenId)
      public
      validShipId(_tokenId)
    {
      uint32 id = uint32(_tokenId);
      require(ships.isOwner(id, _from));
      transferShip(id, _to, true);
    }

    //  approve(): allow _approved to transfer ownership of ship _tokenId
    //
    function approve(address _approved, uint256 _tokenId)
      public
      validShipId(_tokenId)
    {
      setTransferProxy(uint32(_tokenId), _approved);
    }

    //  setApprovalForAll(): allow or disallow _operator to transfer ownership
    //                       of ALL ships owned by :msg.sender
    //
    function setApprovalForAll(address _operator, bool _approved)
      public
    {
      require(0x0 != _operator);
      ships.setOperator(msg.sender, _operator, _approved);
      emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    //  getApproved(): get the transfer proxy for ship _tokenId
    //
    function getApproved(uint256 _tokenId)
      public
      view
      validShipId(_tokenId)
      returns (address approved)
    {
      require(ships.isActive(uint32(_tokenId)));
      return ships.getTransferProxy(uint32(_tokenId));
    }

    //  isApprovedForAll(): returns true if _operator is an operator for _owner
    //
    function isApprovedForAll(address _owner, address _operator)
      public
      view
      returns (bool result)
    {
      return ships.isOperator(_owner, _operator);
    }

  //
  //  ERC721Metadata interface
  //

    function name()
      public
      view
      returns (string)
    {
      return "Urbit Ship";
    }

    function symbol()
      public
      view
      returns (string)
    {
      return "URS";
    }

    //  tokenURI(): produce a URL to a standard JSON file
    //
    function tokenURI(uint256 _tokenId)
      public
      view
      validShipId(_tokenId)
      returns (string _tokenURI)
    {
      _tokenURI = "https://eth.urbit.org/erc721/0000000000.json";
      bytes memory _tokenURIBytes = bytes(_tokenURI);
      _tokenURIBytes[29] = byte(48+(_tokenId / 1000000000) % 10);
      _tokenURIBytes[30] = byte(48+(_tokenId / 100000000) % 10);
      _tokenURIBytes[31] = byte(48+(_tokenId / 10000000) % 10);
      _tokenURIBytes[32] = byte(48+(_tokenId / 1000000) % 10);
      _tokenURIBytes[33] = byte(48+(_tokenId / 100000) % 10);
      _tokenURIBytes[34] = byte(48+(_tokenId / 10000) % 10);
      _tokenURIBytes[35] = byte(48+(_tokenId / 1000) % 10);
      _tokenURIBytes[36] = byte(48+(_tokenId / 100) % 10);
      _tokenURIBytes[37] = byte(48+(_tokenId / 10) % 10);
      _tokenURIBytes[38] = byte(48+(_tokenId / 1) % 10);
    }

  //
  //  Urbit functions for all ships
  //

    //  configureKeys(): configure _ship with Urbit public keys _encryptionKey,
    //                   _authenticationKey, and corresponding
    //                   _cryptoSuiteVersion, incrementing the ship&#39;s
    //                   continuity number if needed
    //
    function configureKeys(uint32 _ship,
                           bytes32 _encryptionKey,
                           bytes32 _authenticationKey,
                           uint32 _cryptoSuiteVersion,
                           bool _discontinuous)
      external
      activeShipOwner(_ship)
    {
      if (_discontinuous)
      {
        ships.incrementContinuityNumber(_ship);
      }
      ships.setKeys(_ship,
                    _encryptionKey,
                    _authenticationKey,
                    _cryptoSuiteVersion);
    }

    //  spawn(): spawn _ship, giving ownership to _target
    //
    //    Requirements:
    //    - _ship must not be active,
    //    - _ship must not be a planet with a galaxy prefix,
    //    - _ship&#39;s prefix must be active and under its spawn limit,
    //    - :msg.sender must be either the owner of _ship&#39;s prefix,
    //      or an authorized spawn proxy for it.
    //
    function spawn(uint32 _ship,
                   address _target)
      external
    {
      //  only currently unowned (and thus also inactive) ships can be spawned
      //
      require(ships.isOwner(_ship, 0x0));

      //  prefix: half-width prefix of _ship
      //
      uint16 prefix = ships.getPrefix(_ship);

      //  only allow spawning of ships of the class directly below the prefix
      //
      //    this is possible because of how the address space works,
      //    but supporting it introduces complexity through broken assumptions.
      //
      //    example:
      //    0x0000.0000 - galaxy zero
      //    0x0000.0100 - the first star of galaxy zero
      //    0x0001.0100 - the first planet of the first star
      //    0x0001.0000 - the first planet of galaxy zero
      //
      require( (uint8(ships.getShipClass(prefix)) + 1) ==
               uint8(ships.getShipClass(_ship)) );

      //  prefix ship must be live and able to spawn
      //
      require( (ships.hasBeenBooted(prefix)) &&
               ( ships.getSpawnCount(prefix) <
                 getSpawnLimit(prefix, block.timestamp) ) );

      //  the owner of a prefix can always spawn its children;
      //  other addresses need explicit permission (the role
      //  of "spawnProxy" in the Ships contract)
      //
      require( ships.isOwner(prefix, msg.sender) ||
               ships.isSpawnProxy(prefix, msg.sender) );

      //  if the caller is spawning the ship to themselves,
      //  assume it knows what it&#39;s doing and resolve right away
      //
      if (msg.sender == _target)
      {
        //  make the ship active and set its new owner
        //
        ships.activateShip(_ship);
        ships.setOwner(_ship, _target);

        emit Transfer(0x0, _target, uint256(_ship));
      }
      //
      //  when sending to a "foreign" address, enforce a withdraw pattern
      //  by approving the _target for transfer of the _ship.
      //  we make the parent&#39;s owner the owner of this _ship in the mean time,
      //  so that it may cancel the transfer (un-approve) if _target flakes.
      //  we don&#39;t make _ship active yet, because it still belongs to its
      //  parent.
      //
      else
      {
        address prefixOwner = ships.getOwner(prefix);
        ships.setOwner(_ship, prefixOwner);
        ships.setTransferProxy(_ship, _target);

        emit Transfer(0x0, prefixOwner, uint256(_ship));
        emit Approval(prefixOwner, _target, uint256(_ship));
      }
    }

    //  getSpawnLimit(): returns the total number of children the ship _ship
    //                   is allowed to spawn at datetime _time.
    //
    function getSpawnLimit(uint32 _ship, uint256 _time)
      public
      view
      returns (uint32 limit)
    {
      Ships.Class class = ships.getShipClass(_ship);

      if ( class == Ships.Class.Galaxy )
      {
        return 255;
      }
      else if ( class == Ships.Class.Star )
      {
        //  in 2018, stars may spawn at most 1024 planets. this limit doubles
        //  for every subsequent year.
        //
        //    Note: 1514764800 corresponds to 2018-01-01
        //
        uint256 yearsSince2018 = (_time - 1514764800) / 365 days;
        if (yearsSince2018 < 6)
        {
          limit = uint32( 1024 * (2 ** yearsSince2018) );
        }
        else
        {
          limit = 65535;
        }
        return limit;
      }
      else  //  class == Ships.Class.Planet
      {
        //  planets can create moons, but moons aren&#39;t on the chain
        //
        return 0;
      }

    }

    //  setSpawnProxy(): give _spawnProxy the right to spawn ships
    //                   with the prefix _prefix
    //
    function setSpawnProxy(uint16 _prefix, address _spawnProxy)
      external
      activeShipOwner(_prefix)
    {
      ships.setSpawnProxy(_prefix, _spawnProxy);
    }

    //  transferShip(): transfer _ship to _target, clearing all permissions
    //                  data and keys if _reset is true
    //
    //    Note: the _reset flag is useful when transferring the ship to
    //    a recipient who doesn&#39;t trust the previous owner.
    //
    //    Requirements:
    //    - :msg.sender must be either _ship&#39;s current owner, authorized
    //      to transfer _ship, or authorized to transfer the current
    //      owner&#39;s ships.
    //    - _target must not be the zero address.
    //
    function transferShip(uint32 _ship, address _target, bool _reset)
      public
    {

      //  old: current ship owner
      //
      address old = ships.getOwner(_ship);

      //  transfer is legitimate if the caller is the old owner, or
      //  has operator or transfer rights
      //
      require((old == msg.sender)
              || ships.isOperator(old, msg.sender)
              || ships.isTransferProxy(_ship, msg.sender));

      //  if the ship wasn&#39;t active yet, that means transferring it
      //  is part of the "spawn" flow, so we need to activate it
      //
      if ( !ships.isActive(_ship) )
      {
        ships.activateShip(_ship);
      }

      //  if the owner would actually change, change it
      //
      //    the only time this deliberately wouldn&#39;t be the case is when a
      //    parent ship wants to activate a spawned but untransferred child.
      //
      if ( !ships.isOwner(_ship, _target) )
      {
        ships.setOwner(_ship, _target);

        //  according to ERC721, the transferrer gets cleared during every
        //  Transfer event
        //
        ships.setTransferProxy(_ship, 0);

        emit Transfer(old, _target, uint256(_ship));
      }

      //  reset sensitive data -- are transferring the
      //  ship to a new owner
      //
      if ( _reset )
      {
        //  clear the Urbit public keys and break continuity,
        //  but only if the ship has already been used
        //
        if ( ships.hasBeenBooted(_ship) )
        {
          ships.incrementContinuityNumber(_ship);
          ships.setKeys(_ship, 0, 0, 0);
        }

        //  clear transfer proxy
        //
        //    in most cases this is done above, during the ownership transfer,
        //    but we might not hit that and still be expected to reset the
        //    transfer proxy.
        //    doing it a second time is a no-op in Ships.
        //
        ships.setTransferProxy(_ship, 0);

        //  clear spawning proxy
        //
        ships.setSpawnProxy(_ship, 0);

        //  clear claims
        //
        claims.clearClaims(_ship);
      }
    }

    //  setTransferProxy(): give _transferProxy the right to transfer _ship
    //
    //    Requirements:
    //    - :msg.sender must be either _ship&#39;s current owner, or be
    //      allowed to manage the current owner&#39;s ships.
    //
    function setTransferProxy(uint32 _ship, address _transferProxy)
      public
    {
      //  owner: owner of _ship
      //
      address owner = ships.getOwner(_ship);

      //  caller must be :owner, or an operator designated by the owner.
      //
      require((owner == msg.sender) || ships.isOperator(owner, msg.sender));

      //  set transferrer field in Ships contract
      //
      ships.setTransferProxy(_ship, _transferProxy);

      //  emit Approval event
      //
      emit Approval(owner, _transferProxy, uint256(_ship));
    }

    //  canEscapeTo(): true if _ship could try to escape to _sponsor
    //
    //    Note: public to help with clients
    //
    function canEscapeTo(uint32 _ship, uint32 _sponsor)
      public
      view
      returns (bool canEscape)
    {
      //  can&#39;t escape to a sponsor that hasn&#39;t been born
      //
      if ( !ships.hasBeenBooted(_sponsor) ) return false;

      //  Can only escape to a ship one class higher than ourselves,
      //  except in the special case where the escaping ship hasn&#39;t
      //  been booted yet -- in that case we may escape to ships of
      //  the same class, to support lightweight invitation chains.
      //
      //  The use case for lightweight invitations is that a planet
      //  owner should be able to invite their friends to Urbit in
      //  a two-party transaction, without a new star relationship.
      //  The lightweight invitation process works by escaping
      //  your own active, but never booted, ship, to yourself,
      //  then transferring it to your friend.
      //
      //  These planets can, in turn, sponsor other unbooted planets,
      //  so the "planet sponsorship chain" can grow to arbitrary
      //  length. Most users, especially deep down the chain, will
      //  want to improve their performance by switching to direct
      //  star sponsors eventually.
      //
      Ships.Class shipClass = ships.getShipClass(_ship);
      Ships.Class sponsorClass = ships.getShipClass(_sponsor);
      return ( //  normal hierarchical escape structure
               //
               ( (uint8(sponsorClass) + 1) == uint8(shipClass) ) ||
               //
               //  special peer escape
               //
               ( (sponsorClass == shipClass) &&
                 //
                 //  peer escape is only for ships that haven&#39;t been booted yet,
                 //  because it&#39;s only for lightweight invitation chains
                 //
                 !ships.hasBeenBooted(_ship) ) );
    }

    //  escape(): request escape from _ship to _sponsor
    //
    //    if an escape request is already active, this overwrites
    //    the existing request
    //
    //    Requirements:
    //    - :msg.sender must be the owner of _ship,
    //    - _ship must be able to escape to _sponsor according to canEscapeTo().
    //
    function escape(uint32 _ship, uint32 _sponsor)
      external
      activeShipOwner(_ship)
    {
      require(canEscapeTo(_ship, _sponsor));
      ships.setEscapeRequest(_ship, _sponsor);
    }

    //  cancelEscape(): cancel the currently set escape for _ship
    //
    function cancelEscape(uint32 _ship)
      external
      activeShipOwner(_ship)
    {
      ships.cancelEscape(_ship);
    }

    //  adopt(): as the _sponsor, accept the _escapee
    //
    //    Requirements:
    //    - :msg.sender must be the owner of _sponsor,
    //    - _escapee must currently be trying to escape to _sponsor.
    //
    function adopt(uint32 _sponsor, uint32 _escapee)
      external
      activeShipOwner(_sponsor)
    {
      require(ships.isRequestingEscapeTo(_escapee, _sponsor));

      //  _sponsor becomes _escapee&#39;s sponsor
      //  its escape request is reset to "not escaping"
      //
      ships.doEscape(_escapee);
    }

    //  reject(): as the _sponsor, deny the _escapee&#39;s request
    //
    //    Requirements:
    //    - :msg.sender must be the owner of _sponsor,
    //    - _escapee must currently be trying to escape to _sponsor.
    //
    function reject(uint32 _sponsor, uint32 _escapee)
      external
      activeShipOwner(_sponsor)
    {
      require(ships.isRequestingEscapeTo(_escapee, _sponsor));

      //  reset the _escapee&#39;s escape request to "not escaping"
      //
      ships.cancelEscape(_escapee);
    }

    //  detach(): as the _sponsor, stop sponsoring the _ship
    //
    //    Requirements:
    //    - :msg.sender must be the owner of _sponsor,
    //    - _ship must currently be sponsored by _sponsor.
    //
    function detach(uint32 _sponsor, uint32 _ship)
      external
      activeShipOwner(_sponsor)
    {
      //  only the current and active sponsor may do this
      //
      require(ships.isSponsor(_ship, _sponsor));

      //  signal that _sponsor no longer supports _ship
      //
      ships.loseSponsor(_ship);
    }

  //
  //  Poll actions
  //

    //  startConstitutionPoll(): as _galaxy, start a poll for the constitution
    //                       upgrade _proposal
    //
    //    Requirements:
    //    - :msg.sender must be the owner of _galaxy,
    //    - the _proposal must expect to be upgraded from this specific
    //      contract, as indicated by its previousConstitution attribute.
    //
    function startConstitutionPoll(uint8 _galaxy, ConstitutionBase _proposal)
      external
      activeShipOwner(_galaxy)
    {
      //  ensure that the upgrade target expects this contract as the source
      //
      require(_proposal.previousConstitution() == address(this));
      polls.startConstitutionPoll(_proposal);
    }

    //  startDocumentPoll(): as _galaxy, start a poll for the _proposal
    //
    function startDocumentPoll(uint8 _galaxy, bytes32 _proposal)
      external
      activeShipOwner(_galaxy)
    {
      polls.startDocumentPoll(_proposal);
    }

    //  castConstitutionVote(): as _galaxy, cast a _vote on the constitution
    //                          upgrade _proposal
    //
    //    _vote is true when in favor of the proposal, false otherwise
    //
    //    If this vote results in a majority for the _proposal, it will
    //    be upgraded to immediately.
    //
    function castConstitutionVote(uint8 _galaxy,
                              ConstitutionBase _proposal,
                              bool _vote)
      external
      activeShipOwner(_galaxy)
    {
      //  majority: true if the vote resulted in a majority, false otherwise
      //
      bool majority = polls.castConstitutionVote(_galaxy, _proposal, _vote);

      //  if a majority is in favor of the upgrade, it happens as defined
      //  in the constitution base contract
      //
      if (majority)
      {
        upgrade(_proposal);
      }
    }

    //  castDocumentVote(): as _galaxy, cast a _vote on the _proposal
    //
    //    _vote is true when in favor of the proposal, false otherwise
    //
    function castDocumentVote(uint8 _galaxy, bytes32 _proposal, bool _vote)
      external
      activeShipOwner(_galaxy)
    {
      polls.castDocumentVote(_galaxy, _proposal, _vote);
    }

    //  updateConstitutionPoll(): check whether the _proposal has achieved
    //                            majority, upgrading to it if it has
    //
    function updateConstitutionPoll(ConstitutionBase _proposal)
      external
    {
      //  majority: true if the poll ended in a majority, false otherwise
      //
      bool majority = polls.updateConstitutionPoll(_proposal);

      //  if a majority is in favor of the upgrade, it happens as defined
      //  in the constitution base contract
      //
      if (majority)
      {
        upgrade(_proposal);
      }
    }

    //  updateDocumentPoll(): check whether the _proposal has achieved majority
    //
    //    Note: the polls contract publicly exposes the function this calls,
    //    but we offer it in the constitution interface as a convenience
    //
    function updateDocumentPoll(bytes32 _proposal)
      external
    {
      polls.updateDocumentPoll(_proposal);
    }

  //
  //  Contract owner operations
  //

    //  createGalaxy(): grant _target ownership of the _galaxy and register
    //                  it for voting
    //
    function createGalaxy(uint8 _galaxy, address _target)
      external
      onlyOwner
    {
      require( !ships.isActive(_galaxy) &&
               0x0 != _target );
      polls.incrementTotalVoters();
      ships.activateShip(_galaxy);
      ships.setOwner(_galaxy, _target);
      emit Transfer(0x0, _target, uint256(_galaxy));
    }

    function setDnsDomains(string _primary, string _secondary, string _tertiary)
      external
      onlyOwner
    {
      ships.setDnsDomains(_primary, _secondary, _tertiary);
    }

  //
  //  Function modifiers for this contract
  //

    //  validShipId(): require that _id is a valid ship
    //
    modifier validShipId(uint256 _id)
    {
      require(_id < 4294967296);
      _;
    }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/Pool.sol

//  an example urbit star pool

pragma solidity 0.4.24;



//  Pool: simple ships-as-tokens contract
//
//    This contract displays a way to turn ships into tokens and vice versa.
//    It implements all functionality of an ERC20 token, and adds a few
//    additional functions to allow tokens to be obtained.
//
//    Using deposit(), an unbooted star can be transferred to this contract.
//    Upon receiving the star, this contract grants one star token to the
//    sender. This token can be used like every other ERC20 token.
//    Using withdraw(), a token can be traded in to receive ownership
//    of one of the stars deposited into this contract.
//
contract Pool is StandardToken
{
  //  ERC20 token metadata
  //
  string constant public name = "StarToken";
  string constant public symbol = "TAR";
  uint256 constant public decimals = 18;
  uint256 constant public oneStar = 1e18;

  //  ships: ships state data store
  //
  Ships public ships;

  //  assets: stars currently held in this pool
  //
  uint16[] public assets;

  //  assetIndexes: per star, (index + 1) in :assets
  //
  //    We delete assets by moving the last entry in the array to the
  //    newly emptied slot, which is (n - 1) where n is the value of
  //    assetIndexes[star].
  //
  mapping(uint16 => uint256) public assetIndexes;

  //  constructor(): register ships state data store
  //
  constructor(Ships _ships)
    public
  {
    ships = _ships;
  }

  //  getAllAssets(): return array of assets held by this contract
  //
  //    Note: only useful for clients, as Solidity does not currently
  //    support returning dynamic arrays.
  //
  function getAllAssets()
    view
    external
    returns (uint16[] allAssets)
  {
    return assets;
  }

  //  deposit(): add a star _star to the pool, receive a token in return
  //
  //    to be able to deposit, either of the following conditions must be
  //    satisfied:
  //
  //    (1) the caller is the owner of the star, the star has a key revision
  //    of zero, and this contract is configured as the star&#39;s transfer proxy
  //
  //    (2) the caller is the owner of the parent of the star, the star is
  //    inactive, and this contract is configured at the galaxy&#39;s spawn proxy
  //
  //    Note: in the if-else-if blocks below, any checks beyond the first
  //    practically don&#39;t matter. it would be fine to let the constitution
  //    revert in our stead, but we implement the checks anyway to make the
  //    required conditions clear through local contract code.
  //
  function deposit(uint16 _star)
    external
    isStar(_star)
  {
    //  case (1)
    //
    if ( //  :msg.sender must be the _star&#39;s owner
         //
         ships.isOwner(_star, msg.sender) &&
         //
         //  the _star may not have been used yet
         //
         !ships.hasBeenBooted(_star) &&
         //
         //  :this contract must be allowed to transfer the _star
         //
         ships.isTransferProxy(_star, this) )
    {
      //  transfer ownership of the _star to :this contract
      //
      Constitution(ships.owner()).transferShip(_star, this, true);
    }
    //
    //  case (2)
    //
    else if ( //  :msg.sender must be the _star&#39;s prefix&#39;s owner
              //
              ships.isOwner(ships.getPrefix(_star), msg.sender) &&
              //
              //  the _star must be inactive
              //
              !ships.isActive(_star) &&
              //
              //  :this contract must be allowed to spawn the _star
              //
              ships.isSpawnProxy(ships.getPrefix(_star), this) )
    {
      //  transfer ownership of the _star to :this contract
      //
      Constitution(ships.owner()).spawn(_star, this);
    }
    //
    //  if neither case is applicable, abort the transaction
    //
    else
    {
      revert();
    }

    //  update state to include the deposited star
    //
    assets.push(_star);
    assetIndexes[_star] = assets.length;

    //  mint a star token and grant it to the :msg.sender
    //
    totalSupply_ = totalSupply_.add(oneStar);
    balances[msg.sender] = balances[msg.sender].add(oneStar);
    emit Transfer(address(0), msg.sender, oneStar);
  }

  //  withdrawAny(): pay a token, receive the most recently deposited star
  //
  function withdrawAny()
    public
  {
    withdraw(assets[assets.length-1]);
  }

  //  withdraw(): pay a token, receive the star _star in return
  //
  function withdraw(uint16 _star)
    public
    isStar(_star)
  {
    //  make sure the :msg.sender has sufficient balance
    //
    require(balanceOf(msg.sender) >= oneStar);

    //  do some gymnastics to keep the list of owned assets gapless.
    //  delete the withdrawn asset from the list, then fill that gap with
    //  the list tail

    //  i: current index of _star in list of assets
    //
    uint256 i = assetIndexes[_star];

    //  we store index + 1, because 0 is the eth default value
    //
    require(i > 0);
    i--;

    //  copy the last item in the list into the now-unused slot
    //
    uint256 last = assets.length - 1;
    uint16 move = assets[last];
    assets[i] = move;

    //  delete the last item
    //
    delete(assets[last]);
    assets.length = last;
    assetIndexes[_star] = 0;

    //  we own one less star, so burn one token.
    //
    balances[msg.sender] = balances[msg.sender].sub(oneStar);
    totalSupply_ = totalSupply_.sub(oneStar);
    emit Transfer(msg.sender, address(0), oneStar);

    //  transfer ownership of the _star to :msg.sender
    //
    //    we don&#39;t need to reset because we already did so when
    //    transferring the ship to this contract.
    //
    Constitution(ships.owner()).transferShip(_star, msg.sender, false);
  }

  //  test if _star is a star, not a galaxy
  //
  modifier isStar(uint16 _star)
  {
    require(_star > 255);
    _;
  }
}