pragma solidity ^0.4.24;


/**
 * @title -
 * play a luckyblock : )
 * Contact us for further cooperation <span class="__cf_email__" data-cfemail="285b5d5858475a5c6844475a4c444d5b5b064147">[email&#160;protected]</span>
 *
 * ██╗      ██╗   ██╗  ██████╗ ██╗  ██╗ ██╗   ██╗ ██████╗  ██╗       ██████╗   ██████╗ ██╗  ██╗
 * ██║      ██║   ██║ ██╔════╝ ██║ ██╔╝ ╚██╗ ██╔╝ ██╔══██╗ ██║      ██╔═══██╗ ██╔════╝ ██║ ██╔╝
 * ██║      ██║   ██║ ██║      █████╔╝   ╚████╔╝  ██████╔╝ ██║      ██║   ██║ ██║      █████╔╝
 * ██║      ██║   ██║ ██║      ██╔═██╗    ╚██╔╝   ██╔══██╗ ██║      ██║   ██║ ██║      ██╔═██╗
 * ███████╗ ╚██████╔╝ ╚██████╗ ██║  ██╗    ██║    ██████╔╝ ███████╗ ╚██████╔╝ ╚██████╗ ██║  ██╗
 * ╚══════╝  ╚═════╝   ╚═════╝ ╚═╝  ╚═╝    ╚═╝    ╚═════╝  ╚══════╝  ╚═════╝   ╚═════╝ ╚═╝  ╚═╝
 *
 * ---
 * POWERED BY
 * ╦   ╔═╗ ╦═╗ ╔╦╗ ╦   ╔═╗ ╔═╗ ╔═╗      ╔╦╗ ╔═╗ ╔═╗ ╔╦╗
 * ║   ║ ║ ╠╦╝  ║║ ║   ║╣  ╚═╗ ╚═╗       ║  ║╣  ╠═╣ ║║║
 * ╩═╝ ╚═╝ ╩╚═ ═╩╝ ╩═╝ ╚═╝ ╚═╝ ╚═╝       ╩  ╚═╝ ╩ ╩ ╩ ╩
 * game at https://game.lordless.io
 * code at https://github.com/lordlessio
 */





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

// File: node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

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

// File: contracts/luckyblock/ILuckyblock.sol

/**
 * @title -luckyblock Interface
 */

interface ILuckyblock{

  function getLuckyblockSpend(
    bytes32 luckyblockId
  ) external view returns (
    address[],
    uint256[],
    uint256
  ); 

  function getLuckyblockEarn(
    bytes32 luckyblockId
    ) external view returns (
    address[],
    uint256[],
    int[],
    uint256,
    int
  );

  function getLuckyblockBase(
    bytes32 luckyblockId
    ) external view returns (
      bool
  );

  function addLuckyblock(uint256 seed) external;

  function start(
    bytes32 luckyblockId
  ) external;

  function stop(
    bytes32 luckyblockId
  ) external;

  function updateLuckyblockSpend(
    bytes32 luckyblockId,
    address[] spendTokenAddresses, 
    uint256[] spendTokenCount,
    uint256 spendEtherCount
  ) external;

  function updateLuckyblockEarn (
    bytes32 luckyblockId,
    address[] earnTokenAddresses,
    uint256[] earnTokenCount,
    int[] earnTokenProbability, // (0 - 100)
    uint256 earnEtherCount,
    int earnEtherProbability
  ) external;
  function setRandomContract(address _randomContract) external;
  function getLuckyblockIds()external view returns(bytes32[]);
  function play(bytes32 luckyblockId) public payable;
  function withdrawToken(address contractAddress, address to, uint256 balance) external;
  function withdrawEth(address to, uint256 balance) external;

  
  

  /* Events */

  event Play (
    bytes32 indexed luckyblockId,
    address user,
    uint8 random
  );

  event WithdrawToken (
    address indexed contractAddress,
    address to,
    uint256 count
  );

  event WithdrawEth (
    address to,
    uint256 count
  );

  event Pay (
    address from,
    uint256 value
  );
}


contract ERC20Interface {
  function transfer(address to, uint tokens) public returns (bool);
  function transferFrom(address from, address to, uint tokens) public returns (bool);
  function balanceOf(address tokenOwner) public view returns (uint256);
  function allowance(address tokenOwner, address spender) public view returns (uint);
}

contract Random {
  function getRandom() external view returns (uint8);
}

contract Luckyblock is Superuser, Pausable, ILuckyblock {

  using SafeMath for *;

  address public randomContract;

  struct User {
    address user;
    string name;
    uint256 verifytime;
    uint256 verifyFee;
  }

  struct LuckyblockBase {
    bool ended;
  }

  struct LuckyblockSpend {
    address[] spendTokenAddresses;
    uint256[] spendTokenCount;
    uint256 spendEtherCount;
  }

  struct LuckyblockEarn {
    address[] earnTokenAddresses;
    uint256[] earnTokenCount;
    int[] earnTokenProbability; // (0 - 100)
    uint256 earnEtherCount;
    int earnEtherProbability;
  }

  bytes32[] public luckyblockIds; //

  mapping (address => bytes32[]) contractAddressToLuckyblockId;

  mapping (bytes32 => LuckyblockEarn) luckyblockIdToLuckyblockEarn;
  mapping (bytes32 => LuckyblockSpend) luckyblockIdToLuckyblockSpend;
  mapping (bytes32 => LuckyblockBase) luckyblockIdToLuckyblockBase;


  mapping (bytes32 => mapping (address => bool)) luckyblockIdToUserAddress;
  mapping (address => uint256) contractAddressToLuckyblockCount;

  function () public payable {
    emit Pay(msg.sender, msg.value);
  }

  function setRandomContract(address _randomContract) external onlyOwnerOrSuperuser {
    randomContract = _randomContract;
  }

  function getLuckyblockIds()external view returns(bytes32[]){
    return luckyblockIds;
  }

  function getLuckyblockSpend(
    bytes32 luckyblockId
    ) external view returns (
      address[],
      uint256[],
      uint256
    ) {
    LuckyblockSpend storage _luckyblockSpend = luckyblockIdToLuckyblockSpend[luckyblockId];
    return (
      _luckyblockSpend.spendTokenAddresses,
      _luckyblockSpend.spendTokenCount,
      _luckyblockSpend.spendEtherCount
      );
  }

  function getLuckyblockEarn(
    bytes32 luckyblockId
    ) external view returns (
      address[],
      uint256[],
      int[],
      uint256,
      int
    ) {
    LuckyblockEarn storage _luckyblockEarn = luckyblockIdToLuckyblockEarn[luckyblockId];
    return (
      _luckyblockEarn.earnTokenAddresses,
      _luckyblockEarn.earnTokenCount,
      _luckyblockEarn.earnTokenProbability,
      _luckyblockEarn.earnEtherCount,
      _luckyblockEarn.earnEtherProbability
      );
  }

  function getLuckyblockBase(
    bytes32 luckyblockId
    ) external view returns (
      bool
    ) {
    LuckyblockBase storage _luckyblockBase = luckyblockIdToLuckyblockBase[luckyblockId];
    return (
      _luckyblockBase.ended
      );
  }
  
  function addLuckyblock(uint256 seed) external onlyOwnerOrSuperuser {
    bytes32 luckyblockId = keccak256(
      abi.encodePacked(block.timestamp, seed)
    );
    LuckyblockBase memory _luckyblockBase = LuckyblockBase(
      false
    );
    luckyblockIds.push(luckyblockId);
    luckyblockIdToLuckyblockBase[luckyblockId] = _luckyblockBase;
  }

  function start(bytes32 luckyblockId) external{
    LuckyblockBase storage _luckyblockBase = luckyblockIdToLuckyblockBase[luckyblockId];
    _luckyblockBase.ended = false;
    luckyblockIdToLuckyblockBase[luckyblockId] = _luckyblockBase;
  }

  function stop(bytes32 luckyblockId) external{
    LuckyblockBase storage _luckyblockBase = luckyblockIdToLuckyblockBase[luckyblockId];
    _luckyblockBase.ended = true;
    luckyblockIdToLuckyblockBase[luckyblockId] = _luckyblockBase;
  }

  function updateLuckyblockSpend (
    bytes32 luckyblockId,
    address[] spendTokenAddresses, 
    uint256[] spendTokenCount,
    uint256 spendEtherCount
    ) external onlyOwnerOrSuperuser {
    LuckyblockSpend memory _luckyblockSpend = LuckyblockSpend(
      spendTokenAddresses,
      spendTokenCount,
      spendEtherCount
    );
    luckyblockIdToLuckyblockSpend[luckyblockId] = _luckyblockSpend;
  }

  function updateLuckyblockEarn (
    bytes32 luckyblockId,
    address[] earnTokenAddresses,
    uint256[] earnTokenCount,
    int[] earnTokenProbability, // (0 - 100)
    uint256 earnEtherCount,
    int earnEtherProbability
    ) external onlyOwnerOrSuperuser {
    LuckyblockEarn memory _luckyblockEarn = LuckyblockEarn(
      earnTokenAddresses,
      earnTokenCount,
      earnTokenProbability, // (0 - 100)
      earnEtherCount,
      earnEtherProbability
    );
    luckyblockIdToLuckyblockEarn[luckyblockId] = _luckyblockEarn;
  }

  // function isContract(address _address) private view returns (bool){
  //   uint size;
  //   assembly { size := extcodesize(addr) }
  //   return size > 0;
  // }

  function isContract(address addr) private returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  function play(bytes32 luckyblockId) public payable whenNotPaused {
    require(!isContract(msg.sender));
    LuckyblockBase storage _luckyblockBase = luckyblockIdToLuckyblockBase[luckyblockId];
    LuckyblockSpend storage _luckyblockSpend = luckyblockIdToLuckyblockSpend[luckyblockId];
    LuckyblockEarn storage _luckyblockEarn = luckyblockIdToLuckyblockEarn[luckyblockId];
    
    require(!_luckyblockBase.ended, "luckyblock is ended");

    // check sender&#39;s ether balance 
    require(msg.value >= _luckyblockSpend.spendEtherCount, "sender value not enough");

    // check spend
    if (_luckyblockSpend.spendTokenAddresses[0] != address(0x0)) {
      for (uint8 i = 0; i < _luckyblockSpend.spendTokenAddresses.length; i++) {

        // check sender&#39;s erc20 balance 
        require(
          ERC20Interface(
            _luckyblockSpend.spendTokenAddresses[i]
          ).balanceOf(address(msg.sender)) >= _luckyblockSpend.spendTokenCount[i]
        );

        require(
          ERC20Interface(
            _luckyblockSpend.spendTokenAddresses[i]
          ).allowance(address(msg.sender), address(this)) >= _luckyblockSpend.spendTokenCount[i]
        );

        // transfer erc20 token
        ERC20Interface(_luckyblockSpend.spendTokenAddresses[i])
          .transferFrom(msg.sender, address(this), _luckyblockSpend.spendTokenCount[i]);
        }
    }
    
    // check earn erc20
    if (_luckyblockEarn.earnTokenAddresses[0] !=
      address(0x0)) {
      for (uint8 j= 0; j < _luckyblockEarn.earnTokenAddresses.length; j++) {
        // check sender&#39;s erc20 balance 
        uint256 earnTokenCount = _luckyblockEarn.earnTokenCount[j];
        require(
          ERC20Interface(_luckyblockEarn.earnTokenAddresses[j])
          .balanceOf(address(this)) >= earnTokenCount
        );
      }
    }
    
    // check earn ether
    require(address(this).balance >= _luckyblockEarn.earnEtherCount, "contract value not enough");

    // do a random
    uint8 _random = random();

    // earn erc20
    for (uint8 k = 0; k < _luckyblockEarn.earnTokenAddresses.length; k++){
      // if win erc20
      if (_luckyblockEarn.earnTokenAddresses[0]
        != address(0x0)){
        if (_random + _luckyblockEarn.earnTokenProbability[k] >= 100) {
          ERC20Interface(_luckyblockEarn.earnTokenAddresses[k])
            .transfer(msg.sender, _luckyblockEarn.earnTokenCount[k]);
        }
      }
    }
    uint256 value = msg.value;
    uint256 payExcess = value.sub(_luckyblockSpend.spendEtherCount);
    
    // if win ether
    if (_random + _luckyblockEarn.earnEtherProbability >= 100) {
      uint256 balance = _luckyblockEarn.earnEtherCount.add(payExcess);
      if (balance > 0){
        msg.sender.transfer(balance);
      }
    } else if (payExcess > 0) {
      msg.sender.transfer(payExcess);
    }
    
    emit Play(luckyblockId, msg.sender, _random);
  }

  function withdrawToken(address contractAddress, address to, uint256 balance)
    external onlyOwnerOrSuperuser {
    ERC20Interface erc20 = ERC20Interface(contractAddress);
    if (balance == uint256(0x0)){
      erc20.transfer(to, erc20.balanceOf(address(this)));
      emit WithdrawToken(contractAddress, to, erc20.balanceOf(address(this)));
    } else {
      erc20.transfer(to, balance);
      emit WithdrawToken(contractAddress, to, balance);
    }
  }

  function withdrawEth(address to, uint256 balance) external onlySuperuser {
    if (balance == uint256(0x0)) {
      to.transfer(address(this).balance);
      emit WithdrawEth(to, address(this).balance);
    } else {
      to.transfer(balance);
      emit WithdrawEth(to, balance);
    }
  }

  function random() private view returns (uint8) {
    return Random(randomContract).getRandom(); // random 0-99
  }
}