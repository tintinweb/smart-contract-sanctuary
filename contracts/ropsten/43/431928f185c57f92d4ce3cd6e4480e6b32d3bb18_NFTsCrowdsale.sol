pragma solidity ^0.4.24;


/**
 * @title -NFTs crowdsale
 * NFTsCrowdsale provides a marketplace for NFTs
 *
 *  ██████╗ ██████╗   ██████╗  ██╗    ██╗ ██████╗  ███████╗  █████╗  ██╗      ███████╗ ██╗
 * ██╔════╝ ██╔══██╗ ██╔═══██╗ ██║    ██║ ██╔══██╗ ██╔════╝ ██╔══██╗ ██║      ██╔════╝ ██║
 * ██║      ██████╔╝ ██║   ██║ ██║ █╗ ██║ ██║  ██║ ███████╗ ███████║ ██║      █████╗   ██║
 * ██║      ██╔══██╗ ██║   ██║ ██║███╗██║ ██║  ██║ ╚════██║ ██╔══██║ ██║      ██╔══╝   ╚═╝
 * ╚██████╗ ██║  ██║ ╚██████╔╝ ╚███╔███╔╝ ██████╔╝ ███████║ ██║  ██║ ███████╗ ███████╗ ██╗
 *  ╚═════╝ ╚═╝  ╚═╝  ╚═════╝   ╚══╝╚══╝  ╚═════╝  ╚══════╝ ╚═╝  ╚═╝ ╚══════╝ ╚══════╝ ╚═╝
 *
 * ---
 * POWERED BY
 * ╦   ╔═╗ ╦═╗ ╔╦╗ ╦   ╔═╗ ╔═╗ ╔═╗      ╔╦╗ ╔═╗ ╔═╗ ╔╦╗
 * ║   ║ ║ ╠╦╝  ║║ ║   ║╣  ╚═╗ ╚═╗       ║  ║╣  ╠═╣ ║║║
 * ╩═╝ ╚═╝ ╩╚═ ═╩╝ ╩═╝ ╚═╝ ╚═╝ ╚═╝       ╩  ╚═╝ ╩ ╩ ╩ ╩
 * game at https://lordless.io
 * code at https://github.com/lordlessio
 */

// File: node_modules/zeppelin-solidity/contracts/access/rbac/Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

// File: node_modules/zeppelin-solidity/contracts/access/rbac/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: node_modules/zeppelin-solidity/contracts/ownership/Superuser.sol

/**
 * @title Superuser
 * @dev The Superuser contract defines a single superuser who can transfer the ownership
 * of a contract to a new address, even if he is not the owner.
 * A superuser can transfer his role to a new address.
 */
contract Superuser is Ownable, RBAC {
  string public constant ROLE_SUPERUSER = "superuser";

  constructor () public {
    addRole(msg.sender, ROLE_SUPERUSER);
  }

  /**
   * @dev Throws if called by any account that&#39;s not a superuser.
   */
  modifier onlySuperuser() {
    checkRole(msg.sender, ROLE_SUPERUSER);
    _;
  }

  modifier onlyOwnerOrSuperuser() {
    require(msg.sender == owner || isSuperuser(msg.sender));
    _;
  }

  /**
   * @dev getter to determine if address has superuser role
   */
  function isSuperuser(address _addr)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, ROLE_SUPERUSER);
  }

  /**
   * @dev Allows the current superuser to transfer his role to a newSuperuser.
   * @param _newSuperuser The address to transfer ownership to.
   */
  function transferSuperuser(address _newSuperuser) public onlySuperuser {
    require(_newSuperuser != address(0));
    removeRole(msg.sender, ROLE_SUPERUSER);
    addRole(_newSuperuser, ROLE_SUPERUSER);
  }

  /**
   * @dev Allows the current superuser or owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwnerOrSuperuser {
    _transferOwnership(_newOwner);
  }
}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: node_modules/zeppelin-solidity/contracts/introspection/ERC165.sol

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

// File: node_modules/zeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

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

// File: node_modules/zeppelin-solidity/contracts/token/ERC721/ERC721.sol

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

// File: contracts/lib/SafeMath.sol

/**
 * @title SafeMath
 */
library SafeMath {
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
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) 
      internal 
      pure 
      returns (uint256 c) 
  {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "SafeMath mul failed");
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b)
      internal
      pure
      returns (uint256) 
  {
    require(b <= a, "SafeMath sub failed");
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b)
      internal
      pure
      returns (uint256 c) 
  {
    c = a + b;
    require(c >= a, "SafeMath add failed");
    return c;
  }
  
  /**
    * @dev gives square root of given x.
    */
  function sqrt(uint256 x)
      internal
      pure
      returns (uint256 y) 
  {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y) 
    {
      y = z;
      z = ((add((x / z),z)) / 2);
    }
  }
  
  /**
    * @dev gives square. batchplies x by x
    */
  function sq(uint256 x)
      internal
      pure
      returns (uint256)
  {
    return (mul(x,x));
  }
  
  /**
    * @dev x to the power of y 
    */
  function pwr(uint256 x, uint256 y)
      internal 
      pure 
      returns (uint256)
  {
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else 
    {
      uint256 z = x;
      for (uint256 i=1; i < y; i++)
        z = mul(z,x);
      return (z);
    }
  }
}

// File: contracts/crowdsale/INFTsCrowdsale.sol

/**
 * @title -NFTs crowdsale Interface
 */

interface INFTsCrowdsale {

  function getAuction(uint256 tokenId) external view
  returns (
    bytes32,
    address,
    uint256,
    uint256,
    uint256,
    uint256
  );

  function isOnAuction(uint256 tokenId) external view returns (bool);

  function isOnPreAuction(uint256 tokenId) external view returns (bool);

  function newAuction(uint128 price, uint256 tokenId, uint256 startAt, uint256 endAt) external;

  function batchNewAuctions(uint128[] prices, uint256[] tokenIds, uint256[] startAts, uint256[] endAts) external;

  function payByEth (uint256 tokenId) external payable; 

  function payByErc20 (uint256 tokenId) external;

  function cancelAuction (uint256 tokenId) external;

  function batchCancelAuctions (uint256[] tokenIds) external;
  
  /* Events */

  event NewAuction (
    bytes32 id,
    address indexed seller,
    uint256 price,
    uint256 startAt,
    uint256 endAt,
    uint256 indexed tokenId
  );

  event PayByEth (
    bytes32 id,
    address indexed seller,
    address indexed buyer,
    uint256 price,
    uint256 endAt,
    uint256 indexed tokenId
  );

  event PayByErc20 (
    bytes32 id,
    address indexed seller,
    address indexed buyer, 
    uint256 price,
    uint256 endAt,
    uint256 indexed tokenId
  );

  event CancelAuction (
    bytes32 id,
    address indexed seller,
    uint256 indexed tokenId
  );

}

// File: contracts/crowdsale/NFTsCrowdsaleBase.sol

contract NFTsCrowdsaleBase is Superuser, INFTsCrowdsale {

  using SafeMath for uint256;

  ERC20 public erc20Contract;
  ERC721 public erc721Contract;
  // eth(price)/erc20(price)
  uint public eth2erc20;
  // Represents a auction
  struct Auction {
    bytes32 id; // Auction id
    address seller; // Seller
    uint256 price; // eth in wei
    uint256 startAt; //  Auction startAt
    uint256 endAt; //  Auction endAt
    uint256 tokenId; // ERC721 tokenId 
  }

  mapping (uint256 => Auction) tokenIdToAuction;
  
  constructor(address _erc721Address,address _erc20Address, uint _eth2erc20) public {
    erc721Contract = ERC721(_erc721Address);
    erc20Contract = ERC20(_erc20Address);
    eth2erc20 = _eth2erc20;
  }

  function getAuction(uint256 _tokenId) external view
  returns (
    bytes32,
    address,
    uint256,
    uint256,
    uint256,
    uint256
  ){
    Auction storage auction = tokenIdToAuction[_tokenId];
    return (auction.id, auction.seller, auction.price, auction.startAt, auction.endAt, auction.tokenId);
  }

  function isOnAuction(uint256 _tokenId) external view returns (bool) {
    Auction storage _auction = tokenIdToAuction[_tokenId];
    uint256 time = block.timestamp;
    return (time < _auction.endAt && time > _auction.startAt);
  }

  function isOnPreAuction(uint256 _tokenId) external view returns (bool) {
    Auction storage _auction = tokenIdToAuction[_tokenId];
    return (block.timestamp < _auction.startAt);
  }

  function _isTokenOwner(address _seller, uint256 _tokenId) internal view returns (bool){
    return (erc721Contract.ownerOf(_tokenId) == _seller);
  }

  function _isOnAuction(uint256 _tokenId) internal view returns (bool) {
    Auction storage _auction = tokenIdToAuction[_tokenId];
    uint256 time = block.timestamp;
    return (time < _auction.endAt && time > _auction.startAt);
  }
  function _escrow(address _owner, uint256 _tokenId) internal {
    erc721Contract.transferFrom(_owner, this, _tokenId);
  }

  function _cancelEscrow(address _owner, uint256 _tokenId) internal {
    erc721Contract.transferFrom(this, _owner, _tokenId);
  }

  function _transfer(address _receiver, uint256 _tokenId) internal {
    erc721Contract.safeTransferFrom(this, _receiver, _tokenId);
  }

  function _newAuction(uint256 _price, uint256 _tokenId, uint256 _startAt, uint256 _endAt) internal {
    require(_price == uint256(_price));
    address _seller = msg.sender;

    require(_isTokenOwner(_seller, _tokenId));
    _escrow(_seller, _tokenId);

    bytes32 auctionId = keccak256(
      abi.encodePacked(block.timestamp, _seller, _tokenId, _price)
    );
    
    Auction memory _order = Auction(
      auctionId,
      _seller,
      uint128(_price),
      _startAt,
      _endAt,
      _tokenId
    );

    tokenIdToAuction[_tokenId] = _order;
    emit NewAuction(auctionId, _seller, _price, _startAt, _endAt, _tokenId);
  }

  function _cancelAuction(uint256 _tokenId) internal {
    Auction storage _auction = tokenIdToAuction[_tokenId];
    require(_auction.seller == msg.sender || msg.sender == owner);
    emit CancelAuction(_auction.id, _auction.seller, _tokenId);
    _cancelEscrow(_auction.seller, _tokenId);
    delete tokenIdToAuction[_tokenId];
  }

  function _payByEth(uint256 _tokenId) internal {
    uint256 _ethAmount = msg.value;
    Auction storage _auction = tokenIdToAuction[_tokenId];
    uint256 price = _auction.price;
    require(_isOnAuction(_auction.tokenId));
    require(_ethAmount >= price);

    uint256 payExcess = _ethAmount.sub(price);

    if (price > 0) {
      _auction.seller.transfer(price);
    }
    address buyer = msg.sender;
    buyer.transfer(payExcess);
    _transfer(buyer, _tokenId);
    emit PayByEth(_auction.id, _auction.seller, msg.sender, _auction.price, _auction.endAt, _auction.tokenId);
    delete tokenIdToAuction[_tokenId];
  }

  function _payByErc20(uint256 _tokenId) internal {

    Auction storage _auction = tokenIdToAuction[_tokenId];
    uint256 price = uint256(_auction.price);
    uint256 computedErc20Price = price.mul(eth2erc20);
    uint256 balance = erc20Contract.balanceOf(msg.sender);
    require(balance >= computedErc20Price);
    require(_isOnAuction(_auction.tokenId));

    if (price > 0) {
      erc20Contract.transferFrom(msg.sender, _auction.seller, computedErc20Price);
    }
    _transfer(msg.sender, _tokenId);
    emit PayByErc20(_auction.id, _auction.seller, msg.sender, _auction.price, _auction.endAt, _auction.tokenId);
    delete tokenIdToAuction[_tokenId];
  }
  
}

// File: contracts/crowdsale/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  event Pause2();
  event Unpause2();

  bool public paused = false;
  bool public paused2 = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenNotPaused2() {
    require(!paused2);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  modifier whenPaused2() {
    require(paused2);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  function pause2() public onlyOwner whenNotPaused2 {
    paused2 = true;
    emit Pause2();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }

  function unpause2() public onlyOwner whenPaused2 {
    paused2 = false;
    emit Unpause2();
  }
}

// File: contracts/crowdsale/NFTsCrowdsale.sol

contract NFTsCrowdsale is NFTsCrowdsaleBase, Pausable {

  constructor(address erc721Address, address erc20Address, uint eth2erc20) public 
  NFTsCrowdsaleBase(erc721Address, erc20Address, eth2erc20){}

  /**
   * @dev new a Auction
   * @param price price in wei
   * @param tokenId Tavern&#39;s tokenid
   * @param endAt auction end time
   */
  function newAuction(uint128 price, uint256 tokenId, uint256 startAt, uint256 endAt) whenNotPaused external {
    uint256 _startAt = startAt;
    if (msg.sender != owner) {
      _startAt = block.timestamp;
    }
    _newAuction(price, tokenId, _startAt, endAt);
  }

  /**
   * @dev batch New Auctions 
   * @param prices Array price in wei
   * @param tokenIds Array Tavern&#39;s tokenid
   * @param endAts  Array auction end time
   */
  function batchNewAuctions(uint128[] prices, uint256[] tokenIds, uint256[] startAts, uint256[] endAts) whenNotPaused external {
    uint256 i = 0;
    while (i < tokenIds.length) {
      _newAuction(prices[i], tokenIds[i], startAts[i], endAts[i]);
      i += 1;
    }
  }

  /**
   * @dev pay a auction by eth
   * @param tokenId tavern tokenid
   */
  function payByEth (uint256 tokenId) whenNotPaused external payable {
    _payByEth(tokenId); 
  }

  /**
   * @dev pay a auction by erc20 Token
   * @param tokenId Tavern&#39;s tokenid
   */
  function payByErc20 (uint256 tokenId) whenNotPaused2 external {
    _payByErc20(tokenId);
  }

  /**
   * @dev cancel a auction
   * @param tokenId Tavern&#39;s tokenid
   */
  function cancelAuction (uint256 tokenId) external {
    _cancelAuction(tokenId);
  }

  /**
   * @dev batch cancel auctions
   * @param tokenIds Array Tavern&#39;s tokenid
   */
  function batchCancelAuctions (uint256[] tokenIds) external {
    uint256 i = 0;
    while (i < tokenIds.length) {
      _cancelAuction(tokenIds[i]);
      i += 1;
    }
  }
}