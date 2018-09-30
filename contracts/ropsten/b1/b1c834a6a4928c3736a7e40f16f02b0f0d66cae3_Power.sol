pragma solidity ^0.4.24;


/**
* @title - Tavern&#39;s Power Algorithm
* Power contract implements the algorithm of Tavern equity attribute
*
* ██████╗   ██████╗  ██╗    ██╗ ███████╗ ██████╗  ██╗
* ██╔══██╗ ██╔═══██╗ ██║    ██║ ██╔════╝ ██╔══██╗ ██║
* ██████╔╝ ██║   ██║ ██║ █╗ ██║ █████╗   ██████╔╝ ██║
* ██╔═══╝  ██║   ██║ ██║███╗██║ ██╔══╝   ██╔══██╗ ╚═╝
* ██║      ╚██████╔╝ ╚███╔███╔╝ ███████╗ ██║  ██║ ██╗
* ╚═╝       ╚═════╝   ╚══╝╚══╝  ╚══════╝ ╚═╝  ╚═╝ ╚═╝
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

// File: contracts/tavern/IPower.sol

interface IPower {
  function setTavernContract(address tavern) external;
  function influenceByToken(uint256 tokenId) external view returns(uint256);
  function levelByToken(uint256 tokenId) external view returns(uint256);
  function weightsApportion(uint256 userLevel, uint256 lordLevel) external view returns(uint256);

   /* Events */

  event SetTavernContract (
    address tavern
  );
}

// File: contracts/tavern/ITavern.sol

/**
 * @title Tavern Interface
 */

interface ITavern {

  function setPowerContract(address _powerContract) external;
  function influenceByToken(uint256 tokenId) external view returns(uint256);
  function levelByToken(uint256 tokenId) external view returns(uint256);
  function weightsApportion(uint256 ulevel1, uint256 ulevel2) external view returns(uint256);

  function tavern(uint256 tokenId) external view returns (uint256, int, int, uint8, uint256);
  function isBuilt(uint256 tokenId) external view returns (bool);

  function build(
    uint256 tokenId,
    int longitude,
    int latitude,
    uint8 popularity
    ) external;

  function batchBuild(
    uint256[] tokenIds,
    int[] longitudes,
    int[] latitudes,
    uint8[] popularitys
    ) external;

  function activenessUpgrade(uint256 tokenId, uint256 deltaActiveness) external;
  function batchActivenessUpgrade(uint256[] tokenIds, uint256[] deltaActiveness) external;

  function popularitySetting(uint256 tokenId, uint8 popularity) external;
  function batchPopularitySetting(uint256[] tokenIds, uint8[] popularitys) external;
  
  /* Events */

  event Build (
    uint256 time,
    uint256 indexed tokenId,
    int longitude,
    int latitude,
    uint8 popularity
  );

  event ActivenessUpgrade (
    uint256 indexed tokenId,
    uint256 oActiveness,
    uint256 newActiveness
  );

  event PopularitySetting (
    uint256 indexed tokenId,
    uint256 oPopularity,
    uint256 newPopularity
  );
}

// File: contracts/tavern/Power.sol

contract Power is Superuser, IPower{
  using SafeMath for *;
  ITavern public tavernContract;
  
  /**
   * @dev set the Tavern contract address
   * @return tavern Tavern contract address
   */
  function setTavernContract(address tavern) onlySuperuser external {
    tavernContract = ITavern(tavern);
    emit SetTavernContract(tavern);
  }

  /**
   * @dev get influence by token
   * @param tokenId tokenId
   * @return tavern Tavern contract address
   * influence is
   */
  function influenceByToken(uint256 tokenId) external view returns(uint256){


    uint8 popularity;
    uint256 activeness;
    ( , , , popularity, activeness) = tavernContract.tavern(tokenId);
    return _influenceAlgorithm(popularity, activeness);
  }

  /**
   * @dev get Tavern&#39;s level by tokenId
   * @param tokenId tokenId
   * @return uint256 Tavern&#39;s level
   */
  function levelByToken(uint256 tokenId) external view returns(uint256){

    uint256 activeness;
    ( , , , , activeness) = tavernContract.tavern(tokenId);
    return _activeness2level(activeness);
  }

  function _influenceAlgorithm(uint8 _popularity, uint256 _activeness) internal pure returns (uint256) {
    uint256 popularity = uint256(_popularity);
    return popularity.mul(_activeness).add(popularity);
  }
  
  function _activeness2level(uint256 _activeness) internal pure returns (uint256) {
    return (_activeness.mul(uint(108).sq())/10).sqrt()/108 + 1;
  }

  uint public constant weightsApportionDecimals = 4;
  /**
  * @dev get Tavern&#39;s weightsApportion 
  * @param userLevel userLevel
  * @param lordLevel lordLevel
  * @return uint256 Tavern&#39;s weightsApportion
  * The candy that the user rewards when completing the candy mission will be assigned to the user and the lord. 
  * The distribution ratio is determined by weightsApportion
  */
  function weightsApportion(uint256 userLevel, uint256 lordLevel) external view returns(uint256) {
    return 2000 + 6000 * userLevel / (userLevel + lordLevel);
  }

}