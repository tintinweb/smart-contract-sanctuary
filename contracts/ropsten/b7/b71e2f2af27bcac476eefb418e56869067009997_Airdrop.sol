pragma solidity ^0.4.24;

/**
 * @title -Airdrop
 * every erc20 token can doAirdrop here 
 * Contact us for further cooperation <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="eb989e9b9b84999fab8784998f878e9898c58284">[email&#160;protected]</a>
 *
 *  █████╗  ██╗ ██████╗  ██████╗  ██████╗   ██████╗  ██████╗
 * ██╔══██╗ ██║ ██╔══██╗ ██╔══██╗ ██╔══██╗ ██╔═══██╗ ██╔══██╗
 * ███████║ ██║ ██████╔╝ ██║  ██║ ██████╔╝ ██║   ██║ ██████╔╝
 * ██╔══██║ ██║ ██╔══██╗ ██║  ██║ ██╔══██╗ ██║   ██║ ██╔═══╝
 * ██║  ██║ ██║ ██║  ██║ ██████╔╝ ██║  ██║ ╚██████╔╝ ██║
 * ╚═╝  ╚═╝ ╚═╝ ╚═╝  ╚═╝ ╚═════╝  ╚═╝  ╚═╝  ╚═════╝  ╚═╝
 *
 * ---
 * POWERED BY
 * ╦   ╔═╗ ╦═╗ ╔╦╗ ╦   ╔═╗ ╔═╗ ╔═╗      ╔╦╗ ╔═╗ ╔═╗ ╔╦╗
 * ║   ║ ║ ╠╦╝  ║║ ║   ║╣  ╚═╗ ╚═╗       ║  ║╣  ╠═╣ ║║║
 * ╩═╝ ╚═╝ ╩╚═ ═╩╝ ╩═╝ ╚═╝ ╚═╝ ╚═╝       ╩  ╚═╝ ╩ ╩ ╩ ╩
 * game at http://lordless.games
 * code at https://github.com/lordlessio
 */


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


/**
 * @title -airdrop Interface
 */

interface IAirdrop {

  function isVerifiedUser(address user) external view returns (bool);
  function isCollected(address user, bytes32 airdropId) external view returns (bool);
  function getAirdropIds()external view returns(bytes32[]);
  function getAirdropIdsByContractAddress(address contractAddress)external view returns(bytes32[]);
  function getUser(address userAddress) external view returns (
    address,
    string,
    uint256,
    uint256
  );
  function getAirdrop(
    bytes32 airdropId
    ) external view returns (address, uint256, bool);
  function updateVeifyFee(uint256 fee) external;
  function verifyUser(string name) external payable;
  function addAirdrop (address contractAddress, uint256 countPerUser, bool needVerifiedUser) external;
  function claim(bytes32 airdropId) external;
  function withdrawToken(address contractAddress, address to) external;
  function withdrawEth(address to) external;

  
  

  /* Events */

  event UpdateVeifyFee (
    uint256 indexed fee
  );

  event VerifyUser (
    address indexed user
  );

  event AddAirdrop (
    address indexed contractAddress,
    uint256 countPerUser,
    bool needVerifiedUser
  );

  event Claim (
    bytes32 airdropId,
    address user
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
}







contract ERC20Interface {
  function transfer(address to, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  function balanceOf(address tokenOwner) public view returns (uint balance);
}
contract Airdrop is Superuser, Pausable, IAirdrop {

  using SafeMath for *;

  struct User {
    address user;
    string name;
    uint256 verifytime;
    uint256 verifyFee;
  }

  struct Airdrop {
    address contractAddress;
    uint256 countPerUser; // wei
    bool needVerifiedUser;
  }

  uint256 public verifyFee = 2e16; // 0.02 eth
  bytes32[] public airdropIds; //

  mapping (address => User) public userAddressToUser;
  mapping (address => bytes32[]) contractAddressToAirdropId;
  mapping (bytes32 => Airdrop) airdropIdToAirdrop;
  mapping (bytes32 => mapping (address => bool)) airdropIdToUserAddress;
  mapping (address => uint256) contractAddressToAirdropCount;


  function isVerifiedUser(address user) external view returns (bool){
    return userAddressToUser[user].user == user;
  }

  function isCollected(address user, bytes32 airdropId) external view returns (bool) {
    return airdropIdToUserAddress[airdropId][user];
  }

  function getAirdropIdsByContractAddress(address contractAddress)external view returns(bytes32[]){
    return contractAddressToAirdropId[contractAddress];
  }
  function getAirdropIds()external view returns(bytes32[]){
    return airdropIds;
  }

  function tokenTotalClaim(address contractAddress)external view returns(uint256){
    return contractAddressToAirdropCount[contractAddress];
  }

  function getUser(
    address userAddress
    ) external view returns (address, string, uint256 ,uint256){
    User storage user = userAddressToUser[userAddress];
    return (user.user, user.name, user.verifytime, user.verifyFee);
  }

  function getAirdrop(
    bytes32 airdropId
    ) external view returns (address, uint256, bool){
    Airdrop storage airdrop = airdropIdToAirdrop[airdropId];
    return (airdrop.contractAddress, airdrop.countPerUser, airdrop.needVerifiedUser);
  }
  
  function updateVeifyFee(uint256 fee) external onlyOwnerOrSuperuser{
    verifyFee = fee;
    emit UpdateVeifyFee(fee);
  }

  function verifyUser(string name) external payable whenNotPaused {
    address sender = msg.sender;
    require(!this.isVerifiedUser(sender), "Is Verified User");
    uint256 _ethAmount = msg.value;
    require(_ethAmount >= verifyFee, "LESS FEE");
    uint256 payExcess = _ethAmount.sub(verifyFee);
    if(payExcess > 0) {
      sender.transfer(payExcess);
    }
    
    User memory _user = User(
      sender,
      name,
      block.timestamp,
      verifyFee
    );

    userAddressToUser[sender] = _user;
    emit VerifyUser(msg.sender);
  }

  function addAirdrop(address contractAddress, uint256 countPerUser, bool needVerifiedUser) external onlyOwnerOrSuperuser{
    bytes32 airdropId = keccak256(
      abi.encodePacked(block.timestamp, contractAddress, countPerUser, needVerifiedUser)
    );

    Airdrop memory _airdrop = Airdrop(
      contractAddress,
      countPerUser,
      needVerifiedUser
    );
    airdropIdToAirdrop[airdropId] = _airdrop;
    airdropIds.push(airdropId);
    contractAddressToAirdropId[contractAddress].push(airdropId);
    emit AddAirdrop(contractAddress, countPerUser, needVerifiedUser);
  }

  function claim(bytes32 airdropId) external whenNotPaused {

    Airdrop storage _airdrop = airdropIdToAirdrop[airdropId];
    if (_airdrop.needVerifiedUser) {
      require(this.isVerifiedUser(msg.sender));
    }
    
    require(!this.isCollected(msg.sender, airdropId), "The same Airdrop can only be collected once per address.");
    ERC20Interface erc20 = ERC20Interface(_airdrop.contractAddress);
    erc20.transfer(msg.sender, _airdrop.countPerUser);
    airdropIdToUserAddress[airdropId][msg.sender] = true;
    // update to
    contractAddressToAirdropCount[_airdrop.contractAddress] = 
      contractAddressToAirdropCount[_airdrop.contractAddress].add(_airdrop.countPerUser);
    emit Claim(airdropId, msg.sender);
  }

  function withdrawToken(address contractAddress, address to) external onlyOwnerOrSuperuser {
    ERC20Interface erc20 = ERC20Interface(contractAddress);
    uint256 balance = erc20.balanceOf(address(this));
    erc20.transfer(to, balance);
    emit WithdrawToken(contractAddress, to, balance);
  }

  function withdrawEth(address to) external onlySuperuser {
    uint256 balance = address(this).balance;
    to.transfer(balance);
    emit WithdrawEth(to, balance);
  }

}