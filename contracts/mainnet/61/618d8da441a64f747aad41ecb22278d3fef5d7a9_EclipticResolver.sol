//  ENS resolver for the Ecliptic contract
//  https://azimuth.network

pragma solidity 0.4.24;

////////////////////////////////////////////////////////////////////////////////
//  Imports
////////////////////////////////////////////////////////////////////////////////


// ENS&#39;s ResolverInterface.sol

contract ResolverInterface {
    function addr(bytes32 node) public view returns (address);
    function supportsInterface(bytes4 interfaceID) public pure returns (bool);
}

// OpenZeppelin&#39;s Owneable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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

// Azimuth&#39;s Azimuth.sol

//  Azimuth: point state data contract
//
//    This contract is used for storing all data related to Azimuth points
//    and their ownership. Consider this contract the Azimuth ledger.
//
//    It also contains permissions data, which ties in to ERC721
//    functionality. Operators of an address are allowed to transfer
//    ownership of all points owned by their associated address
//    (ERC721&#39;s approveAll()). A transfer proxy is allowed to transfer
//    ownership of a single point (ERC721&#39;s approve()).
//    Separate from ERC721 are managers, assigned per point. They are
//    allowed to perform "low-impact" operations on the owner&#39;s points,
//    like configuring public keys and making escape requests.
//
//    Since data stores are difficult to upgrade, this contract contains
//    as little actual business logic as possible. Instead, the data stored
//    herein can only be modified by this contract&#39;s owner, which can be
//    changed and is thus upgradable/replaceable.
//
//    This contract will be owned by the Ecliptic contract.
//
contract Azimuth is Ownable
{
//
//  Events
//

  //  OwnerChanged: :point is now owned by :owner
  //
  event OwnerChanged(uint32 indexed point, address indexed owner);

  //  Activated: :point is now active
  //
  event Activated(uint32 indexed point);

  //  Spawned: :prefix has spawned :child
  //
  event Spawned(uint32 indexed prefix, uint32 indexed child);

  //  EscapeRequested: :point has requested a new :sponsor
  //
  event EscapeRequested(uint32 indexed point, uint32 indexed sponsor);

  //  EscapeCanceled: :point&#39;s :sponsor request was canceled or rejected
  //
  event EscapeCanceled(uint32 indexed point, uint32 indexed sponsor);

  //  EscapeAccepted: :point confirmed with a new :sponsor
  //
  event EscapeAccepted(uint32 indexed point, uint32 indexed sponsor);

  //  LostSponsor: :point&#39;s :sponsor is now refusing it service
  //
  event LostSponsor(uint32 indexed point, uint32 indexed sponsor);

  //  ChangedKeys: :point has new network public keys
  //
  event ChangedKeys( uint32 indexed point,
                     bytes32 encryptionKey,
                     bytes32 authenticationKey,
                     uint32 cryptoSuiteVersion,
                     uint32 keyRevisionNumber );

  //  BrokeContinuity: :point has a new continuity number, :number
  //
  event BrokeContinuity(uint32 indexed point, uint32 number);

  //  ChangedSpawnProxy: :spawnProxy can now spawn using :point
  //
  event ChangedSpawnProxy(uint32 indexed point, address indexed spawnProxy);

  //  ChangedTransferProxy: :transferProxy can now transfer ownership of :point
  //
  event ChangedTransferProxy( uint32 indexed point,
                              address indexed transferProxy );

  //  ChangedManagementProxy: :managementProxy can now manage :point
  //
  event ChangedManagementProxy( uint32 indexed point,
                                address indexed managementProxy );

  //  ChangedVotingProxy: :votingProxy can now vote using :point
  //
  event ChangedVotingProxy(uint32 indexed point, address indexed votingProxy);

  //  ChangedDns: dnsDomains have been updated
  //
  event ChangedDns(string primary, string secondary, string tertiary);

//
//  Structures
//

  //  Size: kinds of points registered on-chain
  //
  //    NOTE: the order matters, because of Solidity enum numbering
  //
  enum Size
  {
    Galaxy, // = 0
    Star,   // = 1
    Planet  // = 2
  }

  //  Point: state of a point
  //
  //    While the ordering of the struct members is semantically chaotic,
  //    they are ordered to tightly pack them into Ethereum&#39;s 32-byte storage
  //    slots, which reduces gas costs for some function calls.
  //    The comment ticks indicate assumed slot boundaries.
  //
  struct Point
  {
    //  encryptionKey: (curve25519) encryption public key, or 0 for none
    //
    bytes32 encryptionKey;
  //
    //  authenticationKey: (ed25519) authentication public key, or 0 for none
    //
    bytes32 authenticationKey;
  //
    //  spawned: for stars and galaxies, all :active children
    //
    uint32[] spawned;
  //
    //  hasSponsor: true if the sponsor still supports the point
    //
    bool hasSponsor;

    //  active: whether point can be linked
    //
    //    false: point belongs to prefix, cannot be configured or linked
    //    true: point no longer belongs to prefix, can be configured and linked
    //
    bool active;

    //  escapeRequested: true if the point has requested to change sponsors
    //
    bool escapeRequested;

    //  sponsor: the point that supports this one on the network, or,
    //           if :hasSponsor is false, the last point that supported it.
    //           (by default, the point&#39;s half-width prefix)
    //
    uint32 sponsor;

    //  escapeRequestedTo: if :escapeRequested is true, new sponsor requested
    //
    uint32 escapeRequestedTo;

    //  cryptoSuiteVersion: version of the crypto suite used for the pubkeys
    //
    uint32 cryptoSuiteVersion;

    //  keyRevisionNumber: incremented every time the public keys change
    //
    uint32 keyRevisionNumber;

    //  continuityNumber: incremented to indicate network-side state loss
    //
    uint32 continuityNumber;
  }

  //  Deed: permissions for a point
  //
  struct Deed
  {
    //  owner: address that owns this point
    //
    address owner;

    //  managementProxy: 0, or another address with the right to perform
    //                   low-impact, managerial operations on this point
    //
    address managementProxy;

    //  spawnProxy: 0, or another address with the right to spawn children
    //              of this point
    //
    address spawnProxy;

    //  votingProxy: 0, or another address with the right to vote as this point
    //
    address votingProxy;

    //  transferProxy: 0, or another address with the right to transfer
    //                 ownership of this point
    //
    address transferProxy;
  }

//
//  General state
//

  //  points: per point, general network-relevant point state
  //
  mapping(uint32 => Point) public points;

  //  rights: per point, on-chain ownership and permissions
  //
  mapping(uint32 => Deed) public rights;

  //  operators: per owner, per address, has the right to transfer ownership
  //             of all the owner&#39;s points (ERC721)
  //
  mapping(address => mapping(address => bool)) public operators;

  //  dnsDomains: base domains for contacting galaxies
  //
  //    dnsDomains[0] is primary, the others are used as fallbacks
  //
  string[3] public dnsDomains;

//
//  Lookups
//

  //  sponsoring: per point, the points they are sponsoring
  //
  mapping(uint32 => uint32[]) public sponsoring;

  //  sponsoringIndexes: per point, per point, (index + 1) in
  //                     the sponsoring array
  //
  mapping(uint32 => mapping(uint32 => uint256)) public sponsoringIndexes;

  //  escapeRequests: per point, the points they have open escape requests from
  //
  mapping(uint32 => uint32[]) public escapeRequests;

  //  escapeRequestsIndexes: per point, per point, (index + 1) in
  //                         the escapeRequests array
  //
  mapping(uint32 => mapping(uint32 => uint256)) public escapeRequestsIndexes;

  //  pointsOwnedBy: per address, the points they own
  //
  mapping(address => uint32[]) public pointsOwnedBy;

  //  pointOwnerIndexes: per owner, per point, (index + 1) in
  //                     the pointsOwnedBy array
  //
  //    We delete owners by moving the last entry in the array to the
  //    newly emptied slot, which is (n - 1) where n is the value of
  //    pointOwnerIndexes[owner][point].
  //
  mapping(address => mapping(uint32 => uint256)) public pointOwnerIndexes;

  //  managerFor: per address, the points they are the management proxy for
  //
  mapping(address => uint32[]) public managerFor;

  //  managerForIndexes: per address, per point, (index + 1) in
  //                     the managerFor array
  //
  mapping(address => mapping(uint32 => uint256)) public managerForIndexes;

  //  spawningFor: per address, the points they can spawn with
  //
  mapping(address => uint32[]) public spawningFor;

  //  spawningForIndexes: per address, per point, (index + 1) in
  //                      the spawningFor array
  //
  mapping(address => mapping(uint32 => uint256)) public spawningForIndexes;

  //  votingFor: per address, the points they can vote with
  //
  mapping(address => uint32[]) public votingFor;

  //  votingForIndexes: per address, per point, (index + 1) in
  //                    the votingFor array
  //
  mapping(address => mapping(uint32 => uint256)) public votingForIndexes;

  //  transferringFor: per address, the points they can transfer
  //
  mapping(address => uint32[]) public transferringFor;

  //  transferringForIndexes: per address, per point, (index + 1) in
  //                          the transferringFor array
  //
  mapping(address => mapping(uint32 => uint256)) public transferringForIndexes;

//
//  Logic
//

  //  constructor(): configure default dns domains
  //
  constructor()
    public
  {
    setDnsDomains("example.com", "example.com", "example.com");
  }

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

  //
  //  Point reading
  //

    //  isActive(): return true if _point is active
    //
    function isActive(uint32 _point)
      view
      external
      returns (bool equals)
    {
      return points[_point].active;
    }

    //  getKeys(): returns the public keys and their details, as currently
    //             registered for _point
    //
    function getKeys(uint32 _point)
      view
      external
      returns (bytes32 crypt, bytes32 auth, uint32 suite, uint32 revision)
    {
      Point storage point = points[_point];
      return (point.encryptionKey,
              point.authenticationKey,
              point.cryptoSuiteVersion,
              point.keyRevisionNumber);
    }

    //  getKeyRevisionNumber(): gets the revision number of _point&#39;s current
    //                          public keys
    //
    function getKeyRevisionNumber(uint32 _point)
      view
      external
      returns (uint32 revision)
    {
      return points[_point].keyRevisionNumber;
    }

    //  hasBeenLinked(): returns true if the point has ever been assigned keys
    //
    function hasBeenLinked(uint32 _point)
      view
      external
      returns (bool result)
    {
      return ( points[_point].keyRevisionNumber > 0 );
    }

    //  isLive(): returns true if _point currently has keys properly configured
    //
    function isLive(uint32 _point)
      view
      external
      returns (bool result)
    {
      Point storage point = points[_point];
      return ( point.encryptionKey != 0 &&
               point.authenticationKey != 0 &&
               point.cryptoSuiteVersion != 0 );
    }

    //  getContinuityNumber(): returns _point&#39;s current continuity number
    //
    function getContinuityNumber(uint32 _point)
      view
      external
      returns (uint32 continuityNumber)
    {
      return points[_point].continuityNumber;
    }

    //  getSpawnCount(): return the number of children spawned by _point
    //
    function getSpawnCount(uint32 _point)
      view
      external
      returns (uint32 spawnCount)
    {
      uint256 len = points[_point].spawned.length;
      assert(len < 2**32);
      return uint32(len);
    }

    //  getSpawned(): return array of points created under _point
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getSpawned(uint32 _point)
      view
      external
      returns (uint32[] spawned)
    {
      return points[_point].spawned;
    }

    //  hasSponsor(): returns true if _point&#39;s sponsor is providing it service
    //
    function hasSponsor(uint32 _point)
      view
      external
      returns (bool has)
    {
      return points[_point].hasSponsor;
    }

    //  getSponsor(): returns _point&#39;s current (or most recent) sponsor
    //
    function getSponsor(uint32 _point)
      view
      external
      returns (uint32 sponsor)
    {
      return points[_point].sponsor;
    }

    //  isSponsor(): returns true if _sponsor is currently providing service
    //               to _point
    //
    function isSponsor(uint32 _point, uint32 _sponsor)
      view
      external
      returns (bool result)
    {
      Point storage point = points[_point];
      return ( point.hasSponsor &&
               (point.sponsor == _sponsor) );
    }

    //  getSponsoringCount(): returns the number of points _sponsor is
    //                        providing service to
    //
    function getSponsoringCount(uint32 _sponsor)
      view
      external
      returns (uint256 count)
    {
      return sponsoring[_sponsor].length;
    }

    //  getSponsoring(): returns a list of points _sponsor is providing
    //                   service to
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getSponsoring(uint32 _sponsor)
      view
      external
      returns (uint32[] sponsees)
    {
      return sponsoring[_sponsor];
    }

    //  escaping

    //  isEscaping(): returns true if _point has an outstanding escape request
    //
    function isEscaping(uint32 _point)
      view
      external
      returns (bool escaping)
    {
      return points[_point].escapeRequested;
    }

    //  getEscapeRequest(): returns _point&#39;s current escape request
    //
    //    the returned escape request is only valid as long as isEscaping()
    //    returns true
    //
    function getEscapeRequest(uint32 _point)
      view
      external
      returns (uint32 escape)
    {
      return points[_point].escapeRequestedTo;
    }

    //  isRequestingEscapeTo(): returns true if _point has an outstanding
    //                          escape request targetting _sponsor
    //
    function isRequestingEscapeTo(uint32 _point, uint32 _sponsor)
      view
      public
      returns (bool equals)
    {
      Point storage point = points[_point];
      return (point.escapeRequested && (point.escapeRequestedTo == _sponsor));
    }

    //  getEscapeRequestsCount(): returns the number of points _sponsor
    //                            is providing service to
    //
    function getEscapeRequestsCount(uint32 _sponsor)
      view
      external
      returns (uint256 count)
    {
      return escapeRequests[_sponsor].length;
    }

    //  getEscapeRequests(): get the points _sponsor has received escape
    //                       requests from
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getEscapeRequests(uint32 _sponsor)
      view
      external
      returns (uint32[] requests)
    {
      return escapeRequests[_sponsor];
    }

  //
  //  Point writing
  //

    //  activatePoint(): activate a point, register it as spawned by its prefix
    //
    function activatePoint(uint32 _point)
      onlyOwner
      external
    {
      //  make a point active, setting its sponsor to its prefix
      //
      Point storage point = points[_point];
      require(!point.active);
      point.active = true;
      registerSponsor(_point, true, getPrefix(_point));
      emit Activated(_point);
    }

    //  setKeys(): set network public keys of _point to _encryptionKey and
    //            _authenticationKey, with the specified _cryptoSuiteVersion
    //
    function setKeys(uint32 _point,
                     bytes32 _encryptionKey,
                     bytes32 _authenticationKey,
                     uint32 _cryptoSuiteVersion)
      onlyOwner
      external
    {
      Point storage point = points[_point];
      if ( point.encryptionKey == _encryptionKey &&
           point.authenticationKey == _authenticationKey &&
           point.cryptoSuiteVersion == _cryptoSuiteVersion )
      {
        return;
      }

      point.encryptionKey = _encryptionKey;
      point.authenticationKey = _authenticationKey;
      point.cryptoSuiteVersion = _cryptoSuiteVersion;
      point.keyRevisionNumber++;

      emit ChangedKeys(_point,
                       _encryptionKey,
                       _authenticationKey,
                       _cryptoSuiteVersion,
                       point.keyRevisionNumber);
    }

    //  incrementContinuityNumber(): break continuity for _point
    //
    function incrementContinuityNumber(uint32 _point)
      onlyOwner
      external
    {
      Point storage point = points[_point];
      point.continuityNumber++;
      emit BrokeContinuity(_point, point.continuityNumber);
    }

    //  registerSpawn(): add a point to its prefix&#39;s list of spawned points
    //
    function registerSpawned(uint32 _point)
      onlyOwner
      external
    {
      //  if a point is its own prefix (a galaxy) then don&#39;t register it
      //
      uint32 prefix = getPrefix(_point);
      if (prefix == _point)
      {
        return;
      }

      //  register a new spawned point for the prefix
      //
      points[prefix].spawned.push(_point);
      emit Spawned(prefix, _point);
    }

    //  loseSponsor(): indicates that _point&#39;s sponsor is no longer providing
    //                 it service
    //
    function loseSponsor(uint32 _point)
      onlyOwner
      external
    {
      Point storage point = points[_point];
      if (!point.hasSponsor)
      {
        return;
      }
      registerSponsor(_point, false, point.sponsor);
      emit LostSponsor(_point, point.sponsor);
    }

    //  setEscapeRequest(): for _point, start an escape request to _sponsor
    //
    function setEscapeRequest(uint32 _point, uint32 _sponsor)
      onlyOwner
      external
    {
      if (isRequestingEscapeTo(_point, _sponsor))
      {
        return;
      }
      registerEscapeRequest(_point, true, _sponsor);
      emit EscapeRequested(_point, _sponsor);
    }

    //  cancelEscape(): for _point, stop the current escape request, if any
    //
    function cancelEscape(uint32 _point)
      onlyOwner
      external
    {
      Point storage point = points[_point];
      if (!point.escapeRequested)
      {
        return;
      }
      uint32 request = point.escapeRequestedTo;
      registerEscapeRequest(_point, false, 0);
      emit EscapeCanceled(_point, request);
    }

    //  doEscape(): perform the requested escape
    //
    function doEscape(uint32 _point)
      onlyOwner
      external
    {
      Point storage point = points[_point];
      require(point.escapeRequested);
      registerSponsor(_point, true, point.escapeRequestedTo);
      registerEscapeRequest(_point, false, 0);
      emit EscapeAccepted(_point, point.sponsor);
    }

  //
  //  Point utils
  //

    //  getPrefix(): compute prefix ("parent") of _point
    //
    function getPrefix(uint32 _point)
      pure
      public
      returns (uint16 prefix)
    {
      if (_point < 0x10000)
      {
        return uint16(_point % 0x100);
      }
      return uint16(_point % 0x10000);
    }

    //  getPointSize(): return the size of _point
    //
    function getPointSize(uint32 _point)
      external
      pure
      returns (Size _size)
    {
      if (_point < 0x100) return Size.Galaxy;
      if (_point < 0x10000) return Size.Star;
      return Size.Planet;
    }

    //  internal use

    //  registerSponsor(): set the sponsorship state of _point and update the
    //                     reverse lookup for sponsors
    //
    function registerSponsor(uint32 _point, bool _hasSponsor, uint32 _sponsor)
      internal
    {
      Point storage point = points[_point];
      bool had = point.hasSponsor;
      uint32 prev = point.sponsor;

      //  if we didn&#39;t have a sponsor, and won&#39;t get one,
      //  or if we get the sponsor we already have,
      //  nothing will change, so jump out early.
      //
      if ( (!had && !_hasSponsor) ||
           (had && _hasSponsor && prev == _sponsor) )
      {
        return;
      }

      //  if the point used to have a different sponsor, do some gymnastics
      //  to keep the reverse lookup gapless.  delete the point from the old
      //  sponsor&#39;s list, then fill that gap with the list tail.
      //
      if (had)
      {
        //  i: current index in previous sponsor&#39;s list of sponsored points
        //
        uint256 i = sponsoringIndexes[prev][_point];

        //  we store index + 1, because 0 is the solidity default value
        //
        assert(i > 0);
        i--;

        //  copy the last item in the list into the now-unused slot,
        //  making sure to update its :sponsoringIndexes reference
        //
        uint32[] storage prevSponsoring = sponsoring[prev];
        uint256 last = prevSponsoring.length - 1;
        uint32 moved = prevSponsoring[last];
        prevSponsoring[i] = moved;
        sponsoringIndexes[prev][moved] = i + 1;

        //  delete the last item
        //
        delete(prevSponsoring[last]);
        prevSponsoring.length = last;
        sponsoringIndexes[prev][_point] = 0;
      }

      if (_hasSponsor)
      {
        uint32[] storage newSponsoring = sponsoring[_sponsor];
        newSponsoring.push(_point);
        sponsoringIndexes[_sponsor][_point] = newSponsoring.length;
      }

      point.sponsor = _sponsor;
      point.hasSponsor = _hasSponsor;
    }

    //  registerEscapeRequest(): set the escape state of _point and update the
    //                           reverse lookup for sponsors
    //
    function registerEscapeRequest( uint32 _point,
                                    bool _isEscaping, uint32 _sponsor )
      internal
    {
      Point storage point = points[_point];
      bool was = point.escapeRequested;
      uint32 prev = point.escapeRequestedTo;

      //  if we weren&#39;t escaping, and won&#39;t be,
      //  or if we were escaping, and the new target is the same,
      //  nothing will change, so jump out early.
      //
      if ( (!was && !_isEscaping) ||
           (was && _isEscaping && prev == _sponsor) )
      {
        return;
      }

      //  if the point used to have a different request, do some gymnastics
      //  to keep the reverse lookup gapless.  delete the point from the old
      //  sponsor&#39;s list, then fill that gap with the list tail.
      //
      if (was)
      {
        //  i: current index in previous sponsor&#39;s list of sponsored points
        //
        uint256 i = escapeRequestsIndexes[prev][_point];

        //  we store index + 1, because 0 is the solidity default value
        //
        assert(i > 0);
        i--;

        //  copy the last item in the list into the now-unused slot,
        //  making sure to update its :escapeRequestsIndexes reference
        //
        uint32[] storage prevRequests = escapeRequests[prev];
        uint256 last = prevRequests.length - 1;
        uint32 moved = prevRequests[last];
        prevRequests[i] = moved;
        escapeRequestsIndexes[prev][moved] = i + 1;

        //  delete the last item
        //
        delete(prevRequests[last]);
        prevRequests.length = last;
        escapeRequestsIndexes[prev][_point] = 0;
      }

      if (_isEscaping)
      {
        uint32[] storage newRequests = escapeRequests[_sponsor];
        newRequests.push(_point);
        escapeRequestsIndexes[_sponsor][_point] = newRequests.length;
      }

      point.escapeRequestedTo = _sponsor;
      point.escapeRequested = _isEscaping;
    }

  //
  //  Deed reading
  //

    //  owner

    //  getOwner(): return owner of _point
    //
    function getOwner(uint32 _point)
      view
      external
      returns (address owner)
    {
      return rights[_point].owner;
    }

    //  isOwner(): true if _point is owned by _address
    //
    function isOwner(uint32 _point, address _address)
      view
      external
      returns (bool result)
    {
      return (rights[_point].owner == _address);
    }

    //  getOwnedPointCount(): return length of array of points that _whose owns
    //
    function getOwnedPointCount(address _whose)
      view
      external
      returns (uint256 count)
    {
      return pointsOwnedBy[_whose].length;
    }

    //  getOwnedPoints(): return array of points that _whose owns
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getOwnedPoints(address _whose)
      view
      external
      returns (uint32[] ownedPoints)
    {
      return pointsOwnedBy[_whose];
    }

    //  getOwnedPointAtIndex(): get point at _index from array of points that
    //                         _whose owns
    //
    function getOwnedPointAtIndex(address _whose, uint256 _index)
      view
      external
      returns (uint32 point)
    {
      uint32[] storage owned = pointsOwnedBy[_whose];
      require(_index < owned.length);
      return owned[_index];
    }

    //  management proxy

    //  getManagementProxy(): returns _point&#39;s current management proxy
    //
    function getManagementProxy(uint32 _point)
      view
      external
      returns (address manager)
    {
      return rights[_point].managementProxy;
    }

    //  isManagementProxy(): returns true if _proxy is _point&#39;s management proxy
    //
    function isManagementProxy(uint32 _point, address _proxy)
      view
      external
      returns (bool result)
    {
      return (rights[_point].managementProxy == _proxy);
    }

    //  canManage(): true if _who is the owner or manager of _point
    //
    function canManage(uint32 _point, address _who)
      view
      external
      returns (bool result)
    {
      Deed storage deed = rights[_point];
      return ( (0x0 != _who) &&
               ( (_who == deed.owner) ||
                 (_who == deed.managementProxy) ) );
    }

    //  getManagerForCount(): returns the amount of points _proxy can manage
    //
    function getManagerForCount(address _proxy)
      view
      external
      returns (uint256 count)
    {
      return managerFor[_proxy].length;
    }

    //  getManagerFor(): returns the points _proxy can manage
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getManagerFor(address _proxy)
      view
      external
      returns (uint32[] mfor)
    {
      return managerFor[_proxy];
    }

    //  spawn proxy

    //  getSpawnProxy(): returns _point&#39;s current spawn proxy
    //
    function getSpawnProxy(uint32 _point)
      view
      external
      returns (address spawnProxy)
    {
      return rights[_point].spawnProxy;
    }

    //  isSpawnProxy(): returns true if _proxy is _point&#39;s spawn proxy
    //
    function isSpawnProxy(uint32 _point, address _proxy)
      view
      external
      returns (bool result)
    {
      return (rights[_point].spawnProxy == _proxy);
    }

    //  canSpawnAs(): true if _who is the owner or spawn proxy of _point
    //
    function canSpawnAs(uint32 _point, address _who)
      view
      external
      returns (bool result)
    {
      Deed storage deed = rights[_point];
      return ( (0x0 != _who) &&
               ( (_who == deed.owner) ||
                 (_who == deed.spawnProxy) ) );
    }

    //  getSpawningForCount(): returns the amount of points _proxy
    //                         can spawn with
    //
    function getSpawningForCount(address _proxy)
      view
      external
      returns (uint256 count)
    {
      return spawningFor[_proxy].length;
    }

    //  getSpawningFor(): get the points _proxy can spawn with
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getSpawningFor(address _proxy)
      view
      external
      returns (uint32[] sfor)
    {
      return spawningFor[_proxy];
    }

    //  voting proxy

    //  getVotingProxy(): returns _point&#39;s current voting proxy
    //
    function getVotingProxy(uint32 _point)
      view
      external
      returns (address voter)
    {
      return rights[_point].votingProxy;
    }

    //  isVotingProxy(): returns true if _proxy is _point&#39;s voting proxy
    //
    function isVotingProxy(uint32 _point, address _proxy)
      view
      external
      returns (bool result)
    {
      return (rights[_point].votingProxy == _proxy);
    }

    //  canVoteAs(): true if _who is the owner of _point,
    //               or the voting proxy of _point&#39;s owner
    //
    function canVoteAs(uint32 _point, address _who)
      view
      external
      returns (bool result)
    {
      Deed storage deed = rights[_point];
      return ( (0x0 != _who) &&
               ( (_who == deed.owner) ||
                 (_who == deed.votingProxy) ) );
    }

    //  getVotingForCount(): returns the amount of points _proxy can vote as
    //
    function getVotingForCount(address _proxy)
      view
      external
      returns (uint256 count)
    {
      return votingFor[_proxy].length;
    }

    //  getVotingFor(): returns the points _proxy can vote as
    //
    //    Note: only useful for clients, as Solidity does not currently
    //    support returning dynamic arrays.
    //
    function getVotingFor(address _proxy)
      view
      external
      returns (uint32[] vfor)
    {
      return votingFor[_proxy];
    }

    //  transfer proxy

    //  getTransferProxy(): returns _point&#39;s current transfer proxy
    //
    function getTransferProxy(uint32 _point)
      view
      external
      returns (address transferProxy)
    {
      return rights[_point].transferProxy;
    }

    //  isTransferProxy(): returns true if _proxy is _point&#39;s transfer proxy
    //
    function isTransferProxy(uint32 _point, address _proxy)
      view
      external
      returns (bool result)
    {
      return (rights[_point].transferProxy == _proxy);
    }

    //  canTransfer(): true if _who is the owner or transfer proxy of _point,
    //                 or is an operator for _point&#39;s current owner
    //
    function canTransfer(uint32 _point, address _who)
      view
      external
      returns (bool result)
    {
      Deed storage deed = rights[_point];
      return ( (0x0 != _who) &&
               ( (_who == deed.owner) ||
                 (_who == deed.transferProxy) ||
                 operators[deed.owner][_who] ) );
    }

    //  getTransferringForCount(): returns the amount of points _proxy
    //                             can transfer
    //
    function getTransferringForCount(address _proxy)
      view
      external
      returns (uint256 count)
    {
      return transferringFor[_proxy].length;
    }

    //  getTransferringFor(): get the points _proxy can transfer
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

    //  isOperator(): returns true if _operator is allowed to transfer
    //                ownership of _owner&#39;s points
    //
    function isOperator(address _owner, address _operator)
      view
      external
      returns (bool result)
    {
      return operators[_owner][_operator];
    }

  //
  //  Deed writing
  //

    //  setOwner(): set owner of _point to _owner
    //
    //    Note: setOwner() only implements the minimal data storage
    //    logic for a transfer; the full transfer is implemented in
    //    Ecliptic.
    //
    //    Note: _owner must not be the zero address.
    //
    function setOwner(uint32 _point, address _owner)
      onlyOwner
      external
    {
      //  prevent burning of points by making zero the owner
      //
      require(0x0 != _owner);

      //  prev: previous owner, if any
      //
      address prev = rights[_point].owner;

      if (prev == _owner)
      {
        return;
      }

      //  if the point used to have a different owner, do some gymnastics to
      //  keep the list of owned points gapless.  delete this point from the
      //  list, then fill that gap with the list tail.
      //
      if (0x0 != prev)
      {
        //  i: current index in previous owner&#39;s list of owned points
        //
        uint256 i = pointOwnerIndexes[prev][_point];

        //  we store index + 1, because 0 is the solidity default value
        //
        assert(i > 0);
        i--;

        //  copy the last item in the list into the now-unused slot,
        //  making sure to update its :pointOwnerIndexes reference
        //
        uint32[] storage owner = pointsOwnedBy[prev];
        uint256 last = owner.length - 1;
        uint32 moved = owner[last];
        owner[i] = moved;
        pointOwnerIndexes[prev][moved] = i + 1;

        //  delete the last item
        //
        delete(owner[last]);
        owner.length = last;
        pointOwnerIndexes[prev][_point] = 0;
      }

      //  update the owner list and the owner&#39;s index list
      //
      rights[_point].owner = _owner;
      pointsOwnedBy[_owner].push(_point);
      pointOwnerIndexes[_owner][_point] = pointsOwnedBy[_owner].length;
      emit OwnerChanged(_point, _owner);
    }

    //  setManagementProxy(): makes _proxy _point&#39;s management proxy
    //
    function setManagementProxy(uint32 _point, address _proxy)
      onlyOwner
      external
    {
      Deed storage deed = rights[_point];
      address prev = deed.managementProxy;
      if (prev == _proxy)
      {
        return;
      }

      //  if the point used to have a different manager, do some gymnastics
      //  to keep the reverse lookup gapless.  delete the point from the
      //  old manager&#39;s list, then fill that gap with the list tail.
      //
      if (0x0 != prev)
      {
        //  i: current index in previous manager&#39;s list of managed points
        //
        uint256 i = managerForIndexes[prev][_point];

        //  we store index + 1, because 0 is the solidity default value
        //
        assert(i > 0);
        i--;

        //  copy the last item in the list into the now-unused slot,
        //  making sure to update its :managerForIndexes reference
        //
        uint32[] storage prevMfor = managerFor[prev];
        uint256 last = prevMfor.length - 1;
        uint32 moved = prevMfor[last];
        prevMfor[i] = moved;
        managerForIndexes[prev][moved] = i + 1;

        //  delete the last item
        //
        delete(prevMfor[last]);
        prevMfor.length = last;
        managerForIndexes[prev][_point] = 0;
      }

      if (0x0 != _proxy)
      {
        uint32[] storage mfor = managerFor[_proxy];
        mfor.push(_point);
        managerForIndexes[_proxy][_point] = mfor.length;
      }

      deed.managementProxy = _proxy;
      emit ChangedManagementProxy(_point, _proxy);
    }

    //  setSpawnProxy(): makes _proxy _point&#39;s spawn proxy
    //
    function setSpawnProxy(uint32 _point, address _proxy)
      onlyOwner
      external
    {
      Deed storage deed = rights[_point];
      address prev = deed.spawnProxy;
      if (prev == _proxy)
      {
        return;
      }

      //  if the point used to have a different spawn proxy, do some
      //  gymnastics to keep the reverse lookup gapless.  delete the point
      //  from the old proxy&#39;s list, then fill that gap with the list tail.
      //
      if (0x0 != prev)
      {
        //  i: current index in previous proxy&#39;s list of spawning points
        //
        uint256 i = spawningForIndexes[prev][_point];

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
        spawningForIndexes[prev][_point] = 0;
      }

      if (0x0 != _proxy)
      {
        uint32[] storage sfor = spawningFor[_proxy];
        sfor.push(_point);
        spawningForIndexes[_proxy][_point] = sfor.length;
      }

      deed.spawnProxy = _proxy;
      emit ChangedSpawnProxy(_point, _proxy);
    }

    //  setVotingProxy(): makes _proxy _point&#39;s voting proxy
    //
    function setVotingProxy(uint32 _point, address _proxy)
      onlyOwner
      external
    {
      Deed storage deed = rights[_point];
      address prev = deed.votingProxy;
      if (prev == _proxy)
      {
        return;
      }

      //  if the point used to have a different voter, do some gymnastics
      //  to keep the reverse lookup gapless.  delete the point from the
      //  old voter&#39;s list, then fill that gap with the list tail.
      //
      if (0x0 != prev)
      {
        //  i: current index in previous voter&#39;s list of points it was
        //     voting for
        //
        uint256 i = votingForIndexes[prev][_point];

        //  we store index + 1, because 0 is the solidity default value
        //
        assert(i > 0);
        i--;

        //  copy the last item in the list into the now-unused slot,
        //  making sure to update its :votingForIndexes reference
        //
        uint32[] storage prevVfor = votingFor[prev];
        uint256 last = prevVfor.length - 1;
        uint32 moved = prevVfor[last];
        prevVfor[i] = moved;
        votingForIndexes[prev][moved] = i + 1;

        //  delete the last item
        //
        delete(prevVfor[last]);
        prevVfor.length = last;
        votingForIndexes[prev][_point] = 0;
      }

      if (0x0 != _proxy)
      {
        uint32[] storage vfor = votingFor[_proxy];
        vfor.push(_point);
        votingForIndexes[_proxy][_point] = vfor.length;
      }

      deed.votingProxy = _proxy;
      emit ChangedVotingProxy(_point, _proxy);
    }

    //  setManagementProxy(): makes _proxy _point&#39;s transfer proxy
    //
    function setTransferProxy(uint32 _point, address _proxy)
      onlyOwner
      external
    {
      Deed storage deed = rights[_point];
      address prev = deed.transferProxy;
      if (prev == _proxy)
      {
        return;
      }

      //  if the point used to have a different transfer proxy, do some
      //  gymnastics to keep the reverse lookup gapless.  delete the point
      //  from the old proxy&#39;s list, then fill that gap with the list tail.
      //
      if (0x0 != prev)
      {
        //  i: current index in previous proxy&#39;s list of transferable points
        //
        uint256 i = transferringForIndexes[prev][_point];

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
        transferringForIndexes[prev][_point] = 0;
      }

      if (0x0 != _proxy)
      {
        uint32[] storage tfor = transferringFor[_proxy];
        tfor.push(_point);
        transferringForIndexes[_proxy][_point] = tfor.length;
      }

      deed.transferProxy = _proxy;
      emit ChangedTransferProxy(_point, _proxy);
    }

    //  setOperator(): dis/allow _operator to transfer ownership of all points
    //                 owned by _owner
    //
    //    operators are part of the ERC721 standard
    //
    function setOperator(address _owner, address _operator, bool _approved)
      onlyOwner
      external
    {
      operators[_owner][_operator] = _approved;
    }
}

////////////////////////////////////////////////////////////////////////////////
//  EclipticResolver
////////////////////////////////////////////////////////////////////////////////


contract EclipticResolver is ResolverInterface
{
  Azimuth azimuth;

  constructor(Azimuth _azimuth)
    public
  {
    azimuth = _azimuth;
  }

  function addr(bytes32 node)
    constant
    public
    returns (address)
  {
    //  resolve to the Ecliptic contract
    return azimuth.owner();
  }

  function supportsInterface(bytes4 interfaceID)
    pure
    public
    returns (bool)
  {
    //  supports ERC-137 addr() and ERC-165
    return interfaceID == 0x3b3b57de || interfaceID == 0x01ffc9a7;
  }

  //  ERC-137 resolvers MUST specify a fallback function that throws
  function()
    public
  {
    revert();
  }
}