pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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

// File: openzeppelin-solidity/contracts/ownership/rbac/Roles.sol

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

// File: openzeppelin-solidity/contracts/ownership/rbac/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 * to avoid typos.
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
    view
    public
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
    view
    public
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

// File: contracts/access/RoleManager.sol

contract RoleManager is Ownable, RBAC {
  function addAddressToRole(address _operator, string _roleName)
    onlyOwner
    public
  {
    addRole(_operator, _roleName);
  }

  function isAccess(address _operator, string _roleName)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, _roleName);
  }

  function addAddressesToRole(address[] _operators, string _roleName)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToRole(_operators[i], _roleName);
    }
  }

  function removeAddressFromRole(address _operator, string _roleName)
    onlyOwner
    public
  {
    removeRole(_operator, _roleName);
  }

  function removeAddressesFromRole(address[] _operators, string _roleName)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromRole(_operators[i], _roleName);
    }
  }

}

// File: contracts/contents/ContentInterface.sol

contract ContentInterface {
    function updateContent(string _record, uint256 _marketerRate) external;
    function addEpisode(string _record, uint256 _price) external;
    function updateEpisode(uint256 _index, string _record, uint256 _price) external;
    function isPurchasedEpisode(uint256 _index, address _buyer) public view returns (bool);
    function getRecord() public view returns (string);
    function getWriter() public view returns (address);
    function getMarketerRate() public view returns (uint256);
    function getEpisodeLength() public view returns (uint256);
    function getEpisodeDetail(uint256 _index) public view returns (string, uint256, uint256);
    function episodePurchase(uint256 _index, address _buyer, uint256 _amount) external;
    event RegisterContent(address _sender, string _name);
    event RegisterEpisode(address _sender, string _name, uint256 _index);
    event ChangeContent(address _sender, string _name);
    event ChangeEpisode(address _sender, string _name, uint256 _index);
    event EpisodePurchase(address indexed _buyer, uint256 _index);
}

// File: contracts/utils/ExtendsOwnable.sol

contract ExtendsOwnable {

    mapping(address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// File: contracts/utils/ValidValue.sol

contract ValidValue {
  modifier validRange(uint256 _value) {
      require(_value > 0);
      _;
  }

  modifier validAddress(address _account) {
      require(_account != address(0));
      require(_account != address(this));
      _;
  }

  modifier validString(string _str) {
      require(bytes(_str).length > 0);
      _;
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: contracts/contents/Content.sol

contract Content is ContentInterface, ExtendsOwnable, ValidValue {
    using SafeMath for uint256;

    struct Episode {
        string record;
        uint256 price;
        uint256 buyCount;
        mapping (address => bool) buyUser;
    }

    string public constant ROLE_NAME = &quot;PXL_DISTRIBUTOR&quot;;

    string public record;
    address public writer;
    uint256 public marketerRate;
    address public roleManager;
    Episode[] public episodes;

    modifier contentOwner() {
        require(writer == msg.sender || owners[msg.sender]);
        _;
    }

    modifier validEpisodeLength(uint256 _index) {
        require(episodes.length > _index);
        _;
    }

    constructor(
        string _record,
        address _writer,
        uint256 _marketerRate,
        address _roleManager
    )
    public
    validAddress(_writer) validString(_record) validAddress(_roleManager)
    {
        record = _record;
        writer = _writer;
        marketerRate = _marketerRate;
        roleManager = _roleManager;

        emit RegisterContent(msg.sender, &quot;initializing content&quot;);
    }

    function updateContent(
        string _record,
        uint256 _marketerRate
    )
    external
    contentOwner validString(_record)
    {
        record = _record;
        marketerRate = _marketerRate;

        emit ChangeContent(msg.sender, &quot;update content&quot;);
    }

    function addEpisode(string _record, uint256 _price)
    external
    contentOwner validString(_record)
    {
        episodes.push(Episode(_record, _price, 0));

        emit RegisterEpisode(msg.sender, &quot;add episode&quot;, (episodes.length - 1));
    }

    function updateEpisode(uint256 _index, string _record, uint256 _price)
    external
    contentOwner validString(_record) validEpisodeLength(_index)
    {
        episodes[_index].record = _record;
        episodes[_index].price = _price;

        emit ChangeEpisode(msg.sender, &quot;update episode&quot;, _index);
    }

    function isPurchasedEpisode(uint256 _index, address _buyer)
    public
    view
    returns (bool)
    {
        return episodes[_index].buyUser[_buyer];
    }

    function getRecord() public view returns (string) {
        return record;
    }

    function getWriter() public view returns (address) {
        return writer;
    }

    function getMarketerRate() public view returns (uint256) {
        return marketerRate;
    }

    function getEpisodeLength() public view returns (uint256)
    {
        return episodes.length;
    }

    function getEpisodeDetail(uint256 _index) public view returns (string, uint256, uint256)
    {
        return (episodes[_index].record, episodes[_index].price, episodes[_index].buyCount);
    }

    function episodePurchase(uint256 _index, address _buyer, uint256 _amount)
    external
    validAddress(_buyer) validEpisodeLength(_index)
    {
        require(RoleManager(roleManager).isAccess(msg.sender, ROLE_NAME));
        require(!episodes[_index].buyUser[_buyer]);
        require(episodes[_index].price == _amount);

        episodes[_index].buyUser[_buyer] = true;
        episodes[_index].buyCount = episodes[_index].buyCount.add(1);

        emit EpisodePurchase(_buyer, _index);
    }
}