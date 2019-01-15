//  simple planet invitation management contract
//  https://azimuth.network

pragma solidity 0.4.24;

////////////////////////////////////////////////////////////////////////////////
//  Imports
////////////////////////////////////////////////////////////////////////////////

// OpenZeppelin&#39;s Ownable.sol

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

// Azimuth&#39;s SafeMath8.sol

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

// Azimuth&#39;s SafeMath16.sol

/**
 * @title SafeMath16
 * @dev Math operations for uint16 with safety checks that throw on error
 */
library SafeMath16 {
  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

// OpenZeppelin&#39;s SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// OpenZeppelin&#39;s ERC165.sol

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// OpenZeppelin&#39;s SupportsInterfaceWithLookup.sol

/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

// OpenZeppelin&#39;s ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256(&#39;exists(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// OpenZeppelin&#39;s ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// OpenZeppelin&#39;s ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

// OpenZeppelin&#39;s AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
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

// Azimuth&#39;s ReadsAzimuth.sol

//  ReadsAzimuth: referring to and testing against the Azimuth
//                data contract
//
//    To avoid needless repetition, this contract provides common
//    checks and operations using the Azimuth contract.
//
contract ReadsAzimuth
{
  //  azimuth: points data storage contract.
  //
  Azimuth public azimuth;

  //  constructor(): set the Azimuth data contract&#39;s address
  //
  constructor(Azimuth _azimuth)
    public
  {
    azimuth = _azimuth;
  }

  //  activePointOwner(): require that :msg.sender is the owner of _point,
  //                      and that _point is active
  //
  modifier activePointOwner(uint32 _point)
  {
    require( azimuth.isOwner(_point, msg.sender) &&
             azimuth.isActive(_point) );
    _;
  }

  //  activePointManager(): require that :msg.sender can manage _point,
  //                        and that _point is active
  //
  modifier activePointManager(uint32 _point)
  {
    require( azimuth.canManage(_point, msg.sender) &&
             azimuth.isActive(_point) );
    _;
  }
}

// Azimuth&#39;s Polls.sol

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
//    This contract will be owned by the Ecliptic contract.
//
contract Polls is Ownable
{
  using SafeMath for uint256;
  using SafeMath16 for uint16;
  using SafeMath8 for uint8;

  //  UpgradePollStarted: a poll on :proposal has opened
  //
  event UpgradePollStarted(address proposal);

  //  DocumentPollStarted: a poll on :proposal has opened
  //
  event DocumentPollStarted(bytes32 proposal);

  //  UpgradeMajority: :proposal has achieved majority
  //
  event UpgradeMajority(address proposal);

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
    uint16 yesVotes;

    //  noVotes: amount of votes against the proposal
    //
    uint16 noVotes;

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
  uint16 public totalVoters;

  //  upgradeProposals: list of all upgrades ever proposed
  //
  //    this allows clients to discover the existence of polls.
  //    from there, they can do liveness checks on the polls themselves.
  //
  address[] public upgradeProposals;

  //  upgradePolls: per address, poll held to determine if that address
  //                will become the new ecliptic
  //
  mapping(address => Poll) public upgradePolls;

  //  upgradeHasAchievedMajority: per address, whether that address
  //                              has ever achieved majority
  //
  //    If we did not store this, we would have to look at old poll data
  //    to see whether or not a proposal has ever achieved majority.
  //    Since the outcome of a poll is calculated based on :totalVoters,
  //    which may not be consistent across time, we need to store outcomes
  //    explicitly instead of re-calculating them. This allows us to always
  //    tell with certainty whether or not a majority was achieved,
  //    regardless of the current :totalVoters.
  //
  mapping(address => bool) public upgradeHasAchievedMajority;

  //  documentProposals: list of all documents ever proposed
  //
  //    this allows clients to discover the existence of polls.
  //    from there, they can do liveness checks on the polls themselves.
  //
  bytes32[] public documentProposals;

  //  documentPolls: per hash, poll held to determine if the corresponding
  //                 document is accepted by the galactic senate
  //
  mapping(bytes32 => Poll) public documentPolls;

  //  documentHasAchievedMajority: per hash, whether that hash has ever
  //                               achieved majority
  //
  //    the note for upgradeHasAchievedMajority above applies here as well
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
    require(totalVoters < 256);
    totalVoters = totalVoters.add(1);
  }

  //  getAllUpgradeProposals(): return array of all upgrade proposals ever made
  //
  //    Note: only useful for clients, as Solidity does not currently
  //    support returning dynamic arrays.
  //
  function getUpgradeProposals()
    external
    view
    returns (address[] proposals)
  {
    return upgradeProposals;
  }

  //  getUpgradeProposalCount(): get the number of unique proposed upgrades
  //
  function getUpgradeProposalCount()
    external
    view
    returns (uint256 count)
  {
    return upgradeProposals.length;
  }

  //  getAllDocumentProposals(): return array of all upgrade proposals ever made
  //
  //    Note: only useful for clients, as Solidity does not currently
  //    support returning dynamic arrays.
  //
  function getDocumentProposals()
    external
    view
    returns (bytes32[] proposals)
  {
    return documentProposals;
  }

  //  getDocumentProposalCount(): get the number of unique proposed upgrades
  //
  function getDocumentProposalCount()
    external
    view
    returns (uint256 count)
  {
    return documentProposals.length;
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

  //  hasVotedOnUpgradePoll(): returns true if _galaxy has voted
  //                           on the _proposal
  //
  function hasVotedOnUpgradePoll(uint8 _galaxy, address _proposal)
    external
    view
    returns (bool result)
  {
    return upgradePolls[_proposal].voted[_galaxy];
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

  //  startUpgradePoll(): open a poll on making _proposal the new ecliptic
  //
  function startUpgradePoll(address _proposal)
    external
    onlyOwner
  {
    //  _proposal must not have achieved majority before
    //
    require(!upgradeHasAchievedMajority[_proposal]);

    Poll storage poll = upgradePolls[_proposal];

    //  if the proposal is being made for the first time, register it.
    //
    if (0 == poll.start)
    {
      upgradeProposals.push(_proposal);
    }

    startPoll(poll);
    emit UpgradePollStarted(_proposal);
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

    Poll storage poll = documentPolls[_proposal];

    //  if the proposal is being made for the first time, register it.
    //
    if (0 == poll.start)
    {
      documentProposals.push(_proposal);
    }

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

  //  castUpgradeVote(): as galaxy _as, cast a vote on the _proposal
  //
  //    _vote is true when in favor of the proposal, false otherwise
  //
  function castUpgradeVote(uint8 _as, address _proposal, bool _vote)
    external
    onlyOwner
    returns (bool majority)
  {
    Poll storage poll = upgradePolls[_proposal];
    processVote(poll, _as, _vote);
    return updateUpgradePoll(_proposal);
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

  //  updateUpgradePoll(): check whether the _proposal has achieved
  //                            majority, updating state, sending an event,
  //                            and returning true if it has
  //
  function updateUpgradePoll(address _proposal)
    public
    onlyOwner
    returns (bool majority)
  {
    //  _proposal must not have achieved majority before
    //
    require(!upgradeHasAchievedMajority[_proposal]);

    //  check for majority in the poll
    //
    Poll storage poll = upgradePolls[_proposal];
    majority = checkPollMajority(poll);

    //  if majority was achieved, update the state and send an event
    //
    if (majority)
    {
      upgradeHasAchievedMajority[_proposal] = true;
      emit UpgradeMajority(_proposal);
    }
    return majority;
  }

  //  updateDocumentPoll(): check whether the _proposal has achieved majority,
  //                        updating the state and sending an event if it has
  //
  //    this can be called by anyone, because the ecliptic does not
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
               //  or there are more yes votes than there can be no votes
               //
               ( _poll.yesVotes > totalVoters.sub(_poll.yesVotes) ) ) );
  }
}

// Azimuth&#39;s Claims.sol

//  Claims: simple identity management
//
//    This contract allows points to document claims about their owner.
//    Most commonly, these are about identity, with a claim&#39;s protocol
//    defining the context or platform of the claim, and its dossier
//    containing proof of its validity.
//    Points are limited to a maximum of 16 claims.
//
//    For existing claims, the dossier can be updated, or the claim can
//    be removed entirely. It is recommended to remove any claims associated
//    with a point when it is about to be transferred to a new owner.
//    For convenience, the owner of the Azimuth contract (the Ecliptic)
//    is allowed to clear claims for any point, allowing it to do this for
//    you on-transfer.
//
contract Claims is ReadsAzimuth
{
  //  ClaimAdded: a claim was added by :by
  //
  event ClaimAdded( uint32 indexed by,
                    string _protocol,
                    string _claim,
                    bytes _dossier );

  //  ClaimRemoved: a claim was removed by :by
  //
  event ClaimRemoved(uint32 indexed by, string _protocol, string _claim);

  //  maxClaims: the amount of claims that can be registered per point
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

  //  per point, list of claims
  //
  mapping(uint32 => Claim[maxClaims]) public claims;

  //  constructor(): register the azimuth contract.
  //
  constructor(Azimuth _azimuth)
    ReadsAzimuth(_azimuth)
    public
  {
    //
  }

  //  addClaim(): register a claim as _point
  //
  function addClaim(uint32 _point,
                    string _protocol,
                    string _claim,
                    bytes _dossier)
    external
    activePointManager(_point)
  {
    //  cur: index + 1 of the claim if it already exists, 0 otherwise
    //
    uint8 cur = findClaim(_point, _protocol, _claim);

    //  if the claim doesn&#39;t yet exist, store it in state
    //
    if (cur == 0)
    {
      //  if there are no empty slots left, this throws
      //
      uint8 empty = findEmptySlot(_point);
      claims[_point][empty] = Claim(_protocol, _claim, _dossier);
    }
    //
    //  if the claim has been made before, update the version in state
    //
    else
    {
      claims[_point][cur-1] = Claim(_protocol, _claim, _dossier);
    }
    emit ClaimAdded(_point, _protocol, _claim, _dossier);
  }

  //  removeClaim(): unregister a claim as _point
  //
  function removeClaim(uint32 _point, string _protocol, string _claim)
    external
    activePointManager(_point)
  {
    //  i: current index + 1 in _point&#39;s list of claims
    //
    uint256 i = findClaim(_point, _protocol, _claim);

    //  we store index + 1, because 0 is the eth default value
    //  can only delete an existing claim
    //
    require(i > 0);
    i--;

    //  clear out the claim
    //
    delete claims[_point][i];

    emit ClaimRemoved(_point, _protocol, _claim);
  }

  //  clearClaims(): unregister all of _point&#39;s claims
  //
  //    can also be called by the ecliptic during point transfer
  //
  function clearClaims(uint32 _point)
    external
  {
    //  both point owner and ecliptic may do this
    //
    //    We do not necessarily need to check for _point&#39;s active flag here,
    //    since inactive points cannot have claims set. Doing the check
    //    anyway would make this function slightly harder to think about due
    //    to its relation to Ecliptic&#39;s transferPoint().
    //
    require( azimuth.canManage(_point, msg.sender) ||
             ( msg.sender == azimuth.owner() ) );

    Claim[maxClaims] storage currClaims = claims[_point];

    //  clear out all claims
    //
    for (uint8 i = 0; i < maxClaims; i++)
    {
      delete currClaims[i];
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

// Azimuth&#39;s EclipticBase.sol

//  EclipticBase: upgradable ecliptic
//
//    This contract implements the upgrade logic for the Ecliptic.
//    Newer versions of the Ecliptic are expected to provide at least
//    the onUpgrade() function. If they don&#39;t, upgrading to them will
//    fail.
//
//    Note that even though this contract doesn&#39;t specify any required
//    interface members aside from upgrade() and onUpgrade(), contracts
//    and clients may still rely on the presence of certain functions
//    provided by the Ecliptic proper. Keep this in mind when writing
//    new versions of it.
//
contract EclipticBase is Ownable, ReadsAzimuth
{
  //  Upgraded: _to is the new canonical Ecliptic
  //
  event Upgraded(address to);

  //  polls: senate voting contract
  //
  Polls public polls;

  //  previousEcliptic: address of the previous ecliptic this
  //                    instance expects to upgrade from, stored and
  //                    checked for to prevent unexpected upgrade paths
  //
  address public previousEcliptic;

  constructor( address _previous,
               Azimuth _azimuth,
               Polls _polls )
    ReadsAzimuth(_azimuth)
    internal
  {
    previousEcliptic = _previous;
    polls = _polls;
  }

  //  onUpgrade(): called by previous ecliptic when upgrading
  //
  //    in future ecliptics, this might perform more logic than
  //    just simple checks and verifications.
  //    when overriding this, make sure to call this original as well.
  //
  function onUpgrade()
    external
  {
    //  make sure this is the expected upgrade path,
    //  and that we have gotten the ownership we require
    //
    require( msg.sender == previousEcliptic &&
             this == azimuth.owner() &&
             this == polls.owner() );
  }

  //  upgrade(): transfer ownership of the ecliptic data to the new
  //             ecliptic contract, notify it, then self-destruct.
  //
  //    Note: any eth that have somehow ended up in this contract
  //          are also sent to the new ecliptic.
  //
  function upgrade(EclipticBase _new)
    internal
  {
    //  transfer ownership of the data contracts
    //
    azimuth.transferOwnership(_new);
    polls.transferOwnership(_new);

    //  trigger upgrade logic on the target contract
    //
    _new.onUpgrade();

    //  emit event and destroy this contract
    //
    emit Upgraded(_new);
    selfdestruct(_new);
  }
}

// Azimuth&#39;s Ecliptic

//  Ecliptic: logic for interacting with the Azimuth ledger
//
//    This contract is the point of entry for all operations on the Azimuth
//    ledger as stored in the Azimuth data contract. The functions herein
//    are responsible for performing all necessary business logic.
//    Examples of such logic include verifying permissions of the caller
//    and ensuring a requested change is actually valid.
//    Point owners can always operate on their own points. Ethereum addresses
//    can also perform specific operations if they&#39;ve been given the
//    appropriate permissions. (For example, managers for general management,
//    spawn proxies for spawning child points, etc.)
//
//    This contract uses external contracts (Azimuth, Polls) for data storage
//    so that it itself can easily be replaced in case its logic needs to
//    be changed. In other words, it can be upgraded. It does this by passing
//    ownership of the data contracts to a new Ecliptic contract.
//
//    Because of this, it is advised for clients to not store this contract&#39;s
//    address directly, but rather ask the Azimuth contract for its owner
//    attribute to ensure transactions get sent to the latest Ecliptic.
//    Alternatively, the ENS name ecliptic.eth will resolve to the latest
//    Ecliptic as well.
//
//    Upgrading happens based on polls held by the senate (galaxy owners).
//    Through this contract, the senate can submit proposals, opening polls
//    for the senate to cast votes on. These proposals can be either hashes
//    of documents or addresses of new Ecliptics.
//    If an ecliptic proposal gains majority, this contract will transfer
//    ownership of the data storage contracts to that address, so that it may
//    operate on the data they contain. This contract will selfdestruct at
//    the end of the upgrade process.
//
//    This contract implements the ERC721 interface for non-fungible tokens,
//    allowing points to be managed using generic clients that support the
//    standard. It also implements ERC165 to allow this to be discovered.
//
contract Ecliptic is EclipticBase, SupportsInterfaceWithLookup, ERC721Metadata
{
  using SafeMath for uint256;
  using AddressUtils for address;

  //  Transfer: This emits when ownership of any NFT changes by any mechanism.
  //            This event emits when NFTs are created (`from` == 0) and
  //            destroyed (`to` == 0). At the time of any transfer, the
  //            approved address for that NFT (if any) is reset to none.
  //
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

  //  Approval: This emits when the approved address for an NFT is changed or
  //            reaffirmed. The zero address indicates there is no approved
  //            address. When a Transfer event emits, this also indicates that
  //            the approved address for that NFT (if any) is reset to none.
  //
  event Approval(address indexed _owner, address indexed _approved,
                 uint256 _tokenId);

  //  ApprovalForAll: This emits when an operator is enabled or disabled for an
  //                  owner. The operator can manage all NFTs of the owner.
  //
  event ApprovalForAll(address indexed _owner, address indexed _operator,
                       bool _approved);

  // erc721Received: equal to:
  //        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
  //                 which can be also obtained as:
  //        ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant erc721Received = 0x150b7a02;

  //  claims: contract reference, for clearing claims on-transfer
  //
  Claims public claims;

  //  constructor(): set data contract addresses and signal interface support
  //
  //    Note: during first deploy, ownership of these data contracts must
  //    be manually transferred to this contract.
  //
  constructor(address _previous,
              Azimuth _azimuth,
              Polls _polls,
              Claims _claims)
    EclipticBase(_previous, _azimuth, _polls)
    public
  {
    claims = _claims;

    //  register supported interfaces for ERC165
    //
    _registerInterface(0x80ac58cd); // ERC721
    _registerInterface(0x5b5e139f); // ERC721Metadata
    _registerInterface(0x7f5828d0); // ERC173 (ownership)
  }

  //
  //  ERC721 interface
  //

    //  balanceOf(): get the amount of points owned by _owner
    //
    function balanceOf(address _owner)
      public
      view
      returns (uint256 balance)
    {
      require(0x0 != _owner);
      return azimuth.getOwnedPointCount(_owner);
    }

    //  ownerOf(): get the current owner of point _tokenId
    //
    function ownerOf(uint256 _tokenId)
      public
      view
      validPointId(_tokenId)
      returns (address owner)
    {
      uint32 id = uint32(_tokenId);

      //  this will throw if the owner is the zero address,
      //  active points always have a valid owner.
      //
      require(azimuth.isActive(id));

      return azimuth.getOwner(id);
    }

    //  exists(): returns true if point _tokenId is active
    //
    function exists(uint256 _tokenId)
      public
      view
      returns (bool doesExist)
    {
      return ( (_tokenId < 0x100000000) &&
               azimuth.isActive(uint32(_tokenId)) );
    }

    //  safeTransferFrom(): transfer point _tokenId from _from to _to
    //
    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
      public
    {
      //  transfer with empty data
      //
      safeTransferFrom(_from, _to, _tokenId, "");
    }

    //  safeTransferFrom(): transfer point _tokenId from _from to _to,
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
                        .onERC721Received(msg.sender, _from, _tokenId, _data);
        //
        //  standard return idiom to confirm contract semantics
        //
        require(retval == erc721Received);
      }
    }

    //  transferFrom(): transfer point _tokenId from _from to _to,
    //                  WITHOUT notifying recipient contract
    //
    function transferFrom(address _from, address _to, uint256 _tokenId)
      public
      validPointId(_tokenId)
    {
      uint32 id = uint32(_tokenId);
      require(azimuth.isOwner(id, _from));

      //  the ERC721 operator/approved address (if any) is
      //  accounted for in transferPoint()
      //
      transferPoint(id, _to, true);
    }

    //  approve(): allow _approved to transfer ownership of point
    //             _tokenId
    //
    function approve(address _approved, uint256 _tokenId)
      public
      validPointId(_tokenId)
    {
      setTransferProxy(uint32(_tokenId), _approved);
    }

    //  setApprovalForAll(): allow or disallow _operator to
    //                       transfer ownership of ALL points
    //                       owned by :msg.sender
    //
    function setApprovalForAll(address _operator, bool _approved)
      public
    {
      require(0x0 != _operator);
      azimuth.setOperator(msg.sender, _operator, _approved);
      emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    //  getApproved(): get the approved address for point _tokenId
    //
    function getApproved(uint256 _tokenId)
      public
      view
      validPointId(_tokenId)
      returns (address approved)
    {
      //NOTE  redundant, transfer proxy cannot be set for
      //      inactive points
      //
      require(azimuth.isActive(uint32(_tokenId)));
      return azimuth.getTransferProxy(uint32(_tokenId));
    }

    //  isApprovedForAll(): returns true if _operator is an
    //                      operator for _owner
    //
    function isApprovedForAll(address _owner, address _operator)
      public
      view
      returns (bool result)
    {
      return azimuth.isOperator(_owner, _operator);
    }

  //
  //  ERC721Metadata interface
  //

    //  name(): returns the name of a collection of points
    //
    function name()
      external
      view
      returns (string)
    {
      return "Azimuth Points";
    }

    //  symbol(): returns an abbreviates name for points
    //
    function symbol()
      external
      view
      returns (string)
    {
      return "AZP";
    }

    //  tokenURI(): returns a URL to an ERC-721 standard JSON file
    //
    function tokenURI(uint256 _tokenId)
      public
      view
      validPointId(_tokenId)
      returns (string _tokenURI)
    {
      _tokenURI = "https://azimuth.network/erc721/0000000000.json";
      bytes memory _tokenURIBytes = bytes(_tokenURI);
      _tokenURIBytes[31] = byte(48+(_tokenId / 1000000000) % 10);
      _tokenURIBytes[32] = byte(48+(_tokenId / 100000000) % 10);
      _tokenURIBytes[33] = byte(48+(_tokenId / 10000000) % 10);
      _tokenURIBytes[34] = byte(48+(_tokenId / 1000000) % 10);
      _tokenURIBytes[35] = byte(48+(_tokenId / 100000) % 10);
      _tokenURIBytes[36] = byte(48+(_tokenId / 10000) % 10);
      _tokenURIBytes[37] = byte(48+(_tokenId / 1000) % 10);
      _tokenURIBytes[38] = byte(48+(_tokenId / 100) % 10);
      _tokenURIBytes[39] = byte(48+(_tokenId / 10) % 10);
      _tokenURIBytes[40] = byte(48+(_tokenId / 1) % 10);
    }

  //
  //  Points interface
  //

    //  configureKeys(): configure _point with network public keys
    //                   _encryptionKey, _authenticationKey,
    //                   and corresponding _cryptoSuiteVersion,
    //                   incrementing the point&#39;s continuity number if needed
    //
    function configureKeys(uint32 _point,
                           bytes32 _encryptionKey,
                           bytes32 _authenticationKey,
                           uint32 _cryptoSuiteVersion,
                           bool _discontinuous)
      external
      activePointManager(_point)
    {
      if (_discontinuous)
      {
        azimuth.incrementContinuityNumber(_point);
      }
      azimuth.setKeys(_point,
                      _encryptionKey,
                      _authenticationKey,
                      _cryptoSuiteVersion);
    }

    //  spawn(): spawn _point, then either give, or allow _target to take,
    //           ownership of _point
    //
    //    if _target is the :msg.sender, _targets owns the _point right away.
    //    otherwise, _target becomes the transfer proxy of _point.
    //
    //    Requirements:
    //    - _point must not be active
    //    - _point must not be a planet with a galaxy prefix
    //    - _point&#39;s prefix must be linked and under its spawn limit
    //    - :msg.sender must be either the owner of _point&#39;s prefix,
    //      or an authorized spawn proxy for it
    //
    function spawn(uint32 _point, address _target)
      external
    {
      //  only currently unowned (and thus also inactive) points can be spawned
      //
      require(azimuth.isOwner(_point, 0x0));

      //  prefix: half-width prefix of _point
      //
      uint16 prefix = azimuth.getPrefix(_point);

      //  only allow spawning of points of the size directly below the prefix
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
      require( (uint8(azimuth.getPointSize(prefix)) + 1) ==
               uint8(azimuth.getPointSize(_point)) );

      //  prefix point must be linked and able to spawn
      //
      require( (azimuth.hasBeenLinked(prefix)) &&
               ( azimuth.getSpawnCount(prefix) <
                 getSpawnLimit(prefix, block.timestamp) ) );

      //  the owner of a prefix can always spawn its children;
      //  other addresses need explicit permission (the role
      //  of "spawnProxy" in the Azimuth contract)
      //
      require( azimuth.canSpawnAs(prefix, msg.sender) );

      //  if the caller is spawning the point to themselves,
      //  assume it knows what it&#39;s doing and resolve right away
      //
      if (msg.sender == _target)
      {
        doSpawn(_point, _target, true, 0x0);
      }
      //
      //  when sending to a "foreign" address, enforce a withdraw pattern
      //  making the _point prefix&#39;s owner the _point owner in the mean time
      //
      else
      {
        doSpawn(_point, _target, false, azimuth.getOwner(prefix));
      }
    }

    //  doSpawn(): actual spawning logic, used in spawn(). creates _point,
    //             making the _target its owner if _direct, or making the
    //             _holder the owner and the _target the transfer proxy
    //             if not _direct.
    //
    function doSpawn( uint32 _point,
                      address _target,
                      bool _direct,
                      address _holder )
      internal
    {
      //  register the spawn for _point&#39;s prefix, incrementing spawn count
      //
      azimuth.registerSpawned(_point);

      //  if the spawn is _direct, assume _target knows what they&#39;re doing
      //  and resolve right away
      //
      if (_direct)
      {
        //  make the point active and set its new owner
        //
        azimuth.activatePoint(_point);
        azimuth.setOwner(_point, _target);

        emit Transfer(0x0, _target, uint256(_point));
      }
      //
      //  when spawning indirectly, enforce a withdraw pattern by approving
      //  the _target for transfer of the _point instead.
      //  we make the _holder the owner of this _point in the mean time,
      //  so that it may cancel the transfer (un-approve) if _target flakes.
      //  we don&#39;t make _point active yet, because it still doesn&#39;t really
      //  belong to anyone.
      //
      else
      {
        //  have _holder hold on to the _point while _target gets to transfer
        //  ownership of it
        //
        azimuth.setOwner(_point, _holder);
        azimuth.setTransferProxy(_point, _target);

        emit Transfer(0x0, _holder, uint256(_point));
        emit Approval(_holder, _target, uint256(_point));
      }
    }

    //  transferPoint(): transfer _point to _target, clearing all permissions
    //                   data and keys if _reset is true
    //
    //    Note: the _reset flag is useful when transferring the point to
    //    a recipient who doesn&#39;t trust the previous owner.
    //
    //    Requirements:
    //    - :msg.sender must be either _point&#39;s current owner, authorized
    //      to transfer _point, or authorized to transfer the current
    //      owner&#39;s points (as in ERC721&#39;s operator)
    //    - _target must not be the zero address
    //
    function transferPoint(uint32 _point, address _target, bool _reset)
      public
    {
      //  transfer is legitimate if the caller is the current owner, or
      //  an operator for the current owner, or the _point&#39;s transfer proxy
      //
      require(azimuth.canTransfer(_point, msg.sender));

      //  if the point wasn&#39;t active yet, that means transferring it
      //  is part of the "spawn" flow, so we need to activate it
      //
      if ( !azimuth.isActive(_point) )
      {
        azimuth.activatePoint(_point);
      }

      //  if the owner would actually change, change it
      //
      //    the only time this deliberately wouldn&#39;t be the case is when a
      //    prefix owner wants to activate a spawned but untransferred child.
      //
      if ( !azimuth.isOwner(_point, _target) )
      {
        //  remember the previous owner, to be included in the Transfer event
        //
        address old = azimuth.getOwner(_point);

        azimuth.setOwner(_point, _target);

        //  according to ERC721, the approved address (here, transfer proxy)
        //  gets cleared during every Transfer event
        //
        azimuth.setTransferProxy(_point, 0);

        emit Transfer(old, _target, uint256(_point));
      }

      //  reset sensitive data
      //  used when transferring the point to a new owner
      //
      if ( _reset )
      {
        //  clear the network public keys and break continuity,
        //  but only if the point has already been linked
        //
        if ( azimuth.hasBeenLinked(_point) )
        {
          azimuth.incrementContinuityNumber(_point);
          azimuth.setKeys(_point, 0, 0, 0);
        }

        //  clear management proxy
        //
        azimuth.setManagementProxy(_point, 0);

        //  clear voting proxy
        //
        azimuth.setVotingProxy(_point, 0);

        //  clear transfer proxy
        //
        //    in most cases this is done above, during the ownership transfer,
        //    but we might not hit that and still be expected to reset the
        //    transfer proxy.
        //    doing it a second time is a no-op in Azimuth.
        //
        azimuth.setTransferProxy(_point, 0);

        //  clear spawning proxy
        //
        azimuth.setSpawnProxy(_point, 0);

        //  clear claims
        //
        claims.clearClaims(_point);
      }
    }

    //  escape(): request escape as _point to _sponsor
    //
    //    if an escape request is already active, this overwrites
    //    the existing request
    //
    //    Requirements:
    //    - :msg.sender must be the owner or manager of _point,
    //    - _point must be able to escape to _sponsor as per to canEscapeTo()
    //
    function escape(uint32 _point, uint32 _sponsor)
      external
      activePointManager(_point)
    {
      require(canEscapeTo(_point, _sponsor));
      azimuth.setEscapeRequest(_point, _sponsor);
    }

    //  cancelEscape(): cancel the currently set escape for _point
    //
    function cancelEscape(uint32 _point)
      external
      activePointManager(_point)
    {
      azimuth.cancelEscape(_point);
    }

    //  adopt(): as the relevant sponsor, accept the _point
    //
    //    Requirements:
    //    - :msg.sender must be the owner or management proxy
    //      of _point&#39;s requested sponsor
    //
    function adopt(uint32 _point)
      external
    {
      require( azimuth.isEscaping(_point) &&
               azimuth.canManage( azimuth.getEscapeRequest(_point),
                                  msg.sender ) );

      //  _sponsor becomes _point&#39;s sponsor
      //  its escape request is reset to "not escaping"
      //
      azimuth.doEscape(_point);
    }

    //  reject(): as the relevant sponsor, deny the _point&#39;s request
    //
    //    Requirements:
    //    - :msg.sender must be the owner or management proxy
    //      of _point&#39;s requested sponsor
    //
    function reject(uint32 _point)
      external
    {
      require( azimuth.isEscaping(_point) &&
               azimuth.canManage( azimuth.getEscapeRequest(_point),
                                  msg.sender ) );

      //  reset the _point&#39;s escape request to "not escaping"
      //
      azimuth.cancelEscape(_point);
    }

    //  detach(): as the _sponsor, stop sponsoring the _point
    //
    //    Requirements:
    //    - :msg.sender must be the owner or management proxy
    //      of _point&#39;s current sponsor
    //
    function detach(uint32 _point)
      external
    {
      require( azimuth.hasSponsor(_point) &&
               azimuth.canManage(azimuth.getSponsor(_point), msg.sender) );

      //  signal that its sponsor no longer supports _point
      //
      azimuth.loseSponsor(_point);
    }

  //
  //  Point rules
  //

    //  getSpawnLimit(): returns the total number of children the _point
    //                   is allowed to spawn at _time.
    //
    function getSpawnLimit(uint32 _point, uint256 _time)
      public
      view
      returns (uint32 limit)
    {
      Azimuth.Size size = azimuth.getPointSize(_point);

      if ( size == Azimuth.Size.Galaxy )
      {
        return 255;
      }
      else if ( size == Azimuth.Size.Star )
      {
        //  in 2019, stars may spawn at most 1024 planets. this limit doubles
        //  for every subsequent year.
        //
        //    Note: 1546300800 corresponds to 2019-01-01
        //
        uint256 yearsSince2019 = (_time - 1546300800) / 365 days;
        if (yearsSince2019 < 6)
        {
          limit = uint32( 1024 * (2 ** yearsSince2019) );
        }
        else
        {
          limit = 65535;
        }
        return limit;
      }
      else  //  size == Azimuth.Size.Planet
      {
        //  planets can create moons, but moons aren&#39;t on the chain
        //
        return 0;
      }
    }

    //  canEscapeTo(): true if _point could try to escape to _sponsor
    //
    function canEscapeTo(uint32 _point, uint32 _sponsor)
      public
      view
      returns (bool canEscape)
    {
      //  can&#39;t escape to a sponsor that hasn&#39;t been linked
      //
      if ( !azimuth.hasBeenLinked(_sponsor) ) return false;

      //  Can only escape to a point one size higher than ourselves,
      //  except in the special case where the escaping point hasn&#39;t
      //  been linked yet -- in that case we may escape to points of
      //  the same size, to support lightweight invitation chains.
      //
      //  The use case for lightweight invitations is that a planet
      //  owner should be able to invite their friends onto an
      //  Azimuth network in a two-party transaction, without a new
      //  star relationship.
      //  The lightweight invitation process works by escaping your
      //  own active (but never linked) point to one of your own
      //  points, then transferring the point to your friend.
      //
      //  These planets can, in turn, sponsor other unlinked planets,
      //  so the "planet sponsorship chain" can grow to arbitrary
      //  length. Most users, especially deep down the chain, will
      //  want to improve their performance by switching to direct
      //  star sponsors eventually.
      //
      Azimuth.Size pointSize = azimuth.getPointSize(_point);
      Azimuth.Size sponsorSize = azimuth.getPointSize(_sponsor);
      return ( //  normal hierarchical escape structure
               //
               ( (uint8(sponsorSize) + 1) == uint8(pointSize) ) ||
               //
               //  special peer escape
               //
               ( (sponsorSize == pointSize) &&
                 //
                 //  peer escape is only for points that haven&#39;t been linked
                 //  yet, because it&#39;s only for lightweight invitation chains
                 //
                 !azimuth.hasBeenLinked(_point) ) );
    }

  //
  //  Permission management
  //

    //  setManagementProxy(): configure the management proxy for _point
    //
    //    The management proxy may perform "reversible" operations on
    //    behalf of the owner. This includes public key configuration and
    //    operations relating to sponsorship.
    //
    function setManagementProxy(uint32 _point, address _manager)
      external
      activePointOwner(_point)
    {
      azimuth.setManagementProxy(_point, _manager);
    }

    //  setSpawnProxy(): give _spawnProxy the right to spawn points
    //                   with the prefix _prefix
    //
    function setSpawnProxy(uint16 _prefix, address _spawnProxy)
      external
      activePointOwner(_prefix)
    {
      azimuth.setSpawnProxy(_prefix, _spawnProxy);
    }

    //  setVotingProxy(): configure the voting proxy for _galaxy
    //
    //    the voting proxy is allowed to start polls and cast votes
    //    on the point&#39;s behalf.
    //
    function setVotingProxy(uint8 _galaxy, address _voter)
      external
      activePointOwner(_galaxy)
    {
      azimuth.setVotingProxy(_galaxy, _voter);
    }

    //  setTransferProxy(): give _transferProxy the right to transfer _point
    //
    //    Requirements:
    //    - :msg.sender must be either _point&#39;s current owner,
    //      or be an operator for the current owner
    //
    function setTransferProxy(uint32 _point, address _transferProxy)
      public
    {
      //  owner: owner of _point
      //
      address owner = azimuth.getOwner(_point);

      //  caller must be :owner, or an operator designated by the owner.
      //
      require((owner == msg.sender) || azimuth.isOperator(owner, msg.sender));

      //  set transfer proxy field in Azimuth contract
      //
      azimuth.setTransferProxy(_point, _transferProxy);

      //  emit Approval event
      //
      emit Approval(owner, _transferProxy, uint256(_point));
    }

  //
  //  Poll actions
  //

    //  startUpgradePoll(): as _galaxy, start a poll for the ecliptic
    //                      upgrade _proposal
    //
    //    Requirements:
    //    - :msg.sender must be the owner or voting proxy of _galaxy,
    //    - the _proposal must expect to be upgraded from this specific
    //      contract, as indicated by its previousEcliptic attribute
    //
    function startUpgradePoll(uint8 _galaxy, EclipticBase _proposal)
      external
      activePointVoter(_galaxy)
    {
      //  ensure that the upgrade target expects this contract as the source
      //
      require(_proposal.previousEcliptic() == address(this));
      polls.startUpgradePoll(_proposal);
    }

    //  startDocumentPoll(): as _galaxy, start a poll for the _proposal
    //
    //    the _proposal argument is the keccak-256 hash of any arbitrary
    //    document or string of text
    //
    function startDocumentPoll(uint8 _galaxy, bytes32 _proposal)
      external
      activePointVoter(_galaxy)
    {
      polls.startDocumentPoll(_proposal);
    }

    //  castUpgradeVote(): as _galaxy, cast a _vote on the ecliptic
    //                     upgrade _proposal
    //
    //    _vote is true when in favor of the proposal, false otherwise
    //
    //    If this vote results in a majority for the _proposal, it will
    //    be upgraded to immediately.
    //
    function castUpgradeVote(uint8 _galaxy,
                              EclipticBase _proposal,
                              bool _vote)
      external
      activePointVoter(_galaxy)
    {
      //  majority: true if the vote resulted in a majority, false otherwise
      //
      bool majority = polls.castUpgradeVote(_galaxy, _proposal, _vote);

      //  if a majority is in favor of the upgrade, it happens as defined
      //  in the ecliptic base contract
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
      activePointVoter(_galaxy)
    {
      polls.castDocumentVote(_galaxy, _proposal, _vote);
    }

    //  updateUpgradePoll(): check whether the _proposal has achieved
    //                      majority, upgrading to it if it has
    //
    function updateUpgradePoll(EclipticBase _proposal)
      external
    {
      //  majority: true if the poll ended in a majority, false otherwise
      //
      bool majority = polls.updateUpgradePoll(_proposal);

      //  if a majority is in favor of the upgrade, it happens as defined
      //  in the ecliptic base contract
      //
      if (majority)
      {
        upgrade(_proposal);
      }
    }

    //  updateDocumentPoll(): check whether the _proposal has achieved majority
    //
    //    Note: the polls contract publicly exposes the function this calls,
    //    but we offer it in the ecliptic interface as a convenience
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
      //  only currently unowned (and thus also inactive) galaxies can be
      //  created, and only to non-zero addresses
      //
      require( azimuth.isOwner(_galaxy, 0x0) &&
               0x0 != _target );

      //  new galaxy means a new registered voter
      //
      polls.incrementTotalVoters();

      //  if the caller is sending the galaxy to themselves,
      //  assume it knows what it&#39;s doing and resolve right away
      //
      if (msg.sender == _target)
      {
        doSpawn(_galaxy, _target, true, 0x0);
      }
      //
      //  when sending to a "foreign" address, enforce a withdraw pattern,
      //  making the caller the owner in the mean time
      //
      else
      {
        doSpawn(_galaxy, _target, false, msg.sender);
      }
    }

    function setDnsDomains(string _primary, string _secondary, string _tertiary)
      external
      onlyOwner
    {
      azimuth.setDnsDomains(_primary, _secondary, _tertiary);
    }

  //
  //  Function modifiers for this contract
  //

    //  validPointId(): require that _id is a valid point
    //
    modifier validPointId(uint256 _id)
    {
      require(_id < 0x100000000);
      _;
    }

    //  activePointVoter(): require that :msg.sender can vote as _point,
    //                      and that _point is active
    //
    modifier activePointVoter(uint32 _point)
    {
      require( azimuth.canVoteAs(_point, msg.sender) &&
               azimuth.isActive(_point) );
      _;
    }
}

////////////////////////////////////////////////////////////////////////////////
//  DelegatedSending
////////////////////////////////////////////////////////////////////////////////

//  DelegatedSending: invite-like point sending
//
//    This contract allows planet owners to gift planets to their friends,
//    if their prefix has allowed it.
//
//    Star owners can set a limit, the amount of "invite planets" each of
//    their planets is allowed to send. Enabling this by setting the limit
//    to a value higher than zero can help the network grow by providing
//    regular users with a way to get their friends and family onto it.
//
//    To allow planets to be sent by this contract, stars must set it as
//    their spawnProxy using the Ecliptic.
//
contract DelegatedSending is ReadsAzimuth
{
  //  Sent: :by sent :point
  //
  event Sent( uint16 indexed prefix,
              uint64 indexed fromPool,
              uint32 by,
              uint32 point,
              address to);

  //  limits: per star, the maximum amount of planets any of its planets may
  //          give away
  //
  mapping(uint16 => uint16) public limits;

  //  pools: per pool, the amount of planets that have been given away by
  //         the pool&#39;s planet itself or the ones it invited
  //
  //    pools are associated with planets by number, pool n belongs to
  //    planet n - 1.
  //    pool 0 does not exist, and is used symbolically by :fromPool.
  //
  mapping(uint64 => uint16) public pools;

  //  fromPool: per planet, the pool from which they were sent/invited
  //
  //    when invited by planet n, the invitee is registered in pool n + 1.
  //    a pool of 0 means the planet has its own invite pool.
  //    this is done so that all planets that were born outside of this
  //    contract start out with their own pool (0, solidity default),
  //    while we configure planets created through this contract to use
  //    their inviter&#39;s pool.
  //
  mapping(uint32 => uint64) public fromPool;

  //  constructor(): register the azimuth contract
  //
  constructor(Azimuth _azimuth)
    ReadsAzimuth(_azimuth)
    public
  {
    //
  }

  //  configureLimit(): as the owner of a star, configure the amount of
  //                    planets that may be given away per point.
  //
  function configureLimit(uint16 _prefix, uint16 _limit)
    external
    activePointOwner(_prefix)
  {
    limits[_prefix] = _limit;
  }

  //  resetPool(): grant _for their own invite pool in case they still
  //               share one and reset its counter to zero
  //
  function resetPool(uint32 _for)
    external
    activePointOwner(azimuth.getPrefix(_for))
  {
    fromPool[_for] = 0;
    pools[uint64(_for) + 1] = 0;
  }

  //  sendPoint(): as the point _as, spawn the point _point to _to.
  //
  //    Requirements:
  //    - :msg.sender must be the owner of _as,
  //    - _to must not be the :msg.sender,
  //    - _as must be able to send the _point according to canSend()
  //
  function sendPoint(uint32 _as, uint32 _point, address _to)
    external
    activePointOwner(_as)
  {
    require(canSend(_as, _point));

    //  caller may not send to themselves
    //
    require(msg.sender != _to);

    //  recipient must be eligible to receive a planet from this contract
    //
    require(canReceive(_to));

    //  increment the sent counter for _as.
    //
    uint64 pool = getPool(_as);
    pools[pool]++;

    //  associate the _point with this pool
    //
    fromPool[_point] = pool;

    //  spawn _point to _to, they still need to accept the transfer manually
    //
    Ecliptic(azimuth.owner()).spawn(_point, _to);

    emit Sent(azimuth.getPrefix(_point), pool, _as, _point, _to);
  }

  //  canSend(): check whether current conditions allow _as to send _point
  //
  function canSend(uint32 _as, uint32 _point)
    public
    view
    returns (bool result)
  {
    uint16 prefix = azimuth.getPrefix(_as);
    uint64 pool = getPool(_as);
    return ( //  can only send points with the same prefix
             //
             (prefix == azimuth.getPrefix(_point)) &&
             //
             //  _as must not have hit the allowed limit yet
             //
             (pools[pool] < limits[prefix]) &&
             //
             //  _point needs to not be (in the process of being) spawned
             //
             azimuth.isOwner(_point, 0x0) &&
             //
             //  this contract must have permission to spawn points
             //
             azimuth.isSpawnProxy(prefix, this) &&
             //
             //  the prefix must be linked
             //
             azimuth.hasBeenLinked(prefix) &&
             //
             //  the prefix must not have hit its spawn limit yet
             //
             ( azimuth.getSpawnCount(prefix) <
               Ecliptic(azimuth.owner())
               .getSpawnLimit(prefix, block.timestamp) ) );
  }

  //  getPool(): get the invite pool _point belongs to
  //
  function getPool(uint32 _point)
    internal
    view
    returns (uint64 pool)
  {
    pool = fromPool[_point];

    //  no pool explicitly registered means they have their own pool,
    //  because they either were not invited by this contract, or have
    //  been granted their own pool by their star.
    //
    if (0 == pool)
    {
      //  the pool for planet n is n + 1, see also :fromPool
      //
      return uint64(_point) + 1;
    }

    return pool;
  }

  //  canReceive(): whether the _recipient is eligible to receive a planet
  //                from this contract or not
  //
  //    only those who don&#39;t own or are entitled to any points may receive
  //
  function canReceive(address _recipient)
    public
    view
    returns (bool result)
  {
    return ( 0 == azimuth.getOwnedPointCount(_recipient) &&
             0 == azimuth.getTransferringForCount(_recipient) );
  }
}