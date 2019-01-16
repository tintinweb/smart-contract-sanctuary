pragma solidity ^0.4.24;

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}



contract ProxyTokenBurnerRole {
  using Roles for Roles.Role;

  event BurnerAdded(address indexed account);
  event BurnerRemoved(address indexed account);

  Roles.Role private burners;

  constructor() internal {
    _addBurner(msg.sender);
  }

  modifier onlyBurner() {
    require(isBurner(msg.sender));

    _;
  }

  function isBurner(address account) public view returns (bool) {
    return burners.has(account);
  }

  function addBurner(address account) public onlyBurner {
    _addBurner(account);
  }

  function renounceBurner() public {
    _removeBurner(msg.sender);
  }

  function _addBurner(address account) internal {
    burners.add(account);
    emit BurnerAdded(account);
  }

  function _removeBurner(address account) internal {
    burners.remove(account);
    emit BurnerRemoved(account);
  }
}


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ProxyTokenBurnable is ERC20, ProxyTokenBurnerRole {

  /**
  * @dev Function to burn tokens
  * @param account The address that will have tokens burned.
  * @param amount The amount of tokens to burn.
  * @return A boolean that indicates if the operation was successful.
  */
  function burn(address account, uint256 amount) public onlyBurner returns (bool) {
    _burn(account, amount);

    return true;
  }

  /**
  * @dev Burns a specific amount of tokens from the target address and decrements allowance
  * @param account address The address which you want to send tokens from
  * @param amount uint256 The amount of token to be burned
  */
  function burnFrom(address account, uint256 amount) public onlyBurner returns (bool) {
    _burnFrom(account, amount);

    return true;
  }
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}



contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}


/**
 * @title ProxyToken
 */
contract ProxyToken is ERC20, ERC20Detailed, ERC20Mintable, ProxyTokenBurnable {
  /**
  * @notice Constructor for the ProxyToken
  * @param owner owner of the initial proxy tokens
  * @param name name of the proxy token
  * @param symbol symbol of the proxy token
  * @param decimals divisibility of proxy token
  * @param initialProxySupply initial amount of proxy tokens
  */
  constructor(
    address owner,
    string name,
    string symbol,
    uint8 decimals,
    uint256 initialProxySupply)
  public ERC20Detailed(name, symbol, decimals) {
    mint(owner, initialProxySupply * (10 ** uint256(decimals)));

    if (owner == msg.sender) {
      return;
    }

    addBurner(owner);
    addMinter(owner);
    renounceBurner();
    renounceMinter();
  }
}

/**
 * @title ProxyTokenAuthorizableV0
 * @dev ProxyTokenAuthorizableV0 offers modifiers to verify authorization of a user
 * and functions to authorize and deauthorize users
 */
contract ProxyTokenAuthorizableV0 is Ownable {
  mapping (address => bool) public mintRequestAuthorization;
  mapping (address => bool) public mintFulfillAuthorization;
  mapping (address => bool) public burnRequestAuthorization;
  mapping (address => bool) public burnFulfillAuthorization;

  /**
  * @dev Runs a function only after checking if a user is authorized to request mints
  * @param user Address for verifying authorization
  */
  modifier onlyAuthorizedMintRequester(address user) {
    require(mintRequestAuthorization[user]);
    _;
  }

  /**
  * @dev Runs a function only after checking if a user is authorized to fulfill mints
  * @param user Address for verifying authorization
  */
  modifier onlyAuthorizedMintFulfiller(address user) {
    require(mintFulfillAuthorization[user]);
    _;
  }

  /**
  * @dev Runs a function only after checking if a user is authorized to request burns
  * @param user Address for verifying authorization
  */
  modifier onlyAuthorizedBurnRequester(address user) {
    require(burnRequestAuthorization[user]);
    _;
  }

  /**
  * @dev Runs a function only after checking if a user is authorized to fulfill burns
  * @param user Address for verifying authorization
  */
  modifier onlyAuthorizedBurnFulfiller(address user) {
    require(burnFulfillAuthorization[user]);
    _;
  }

  /**
  * @dev Constructor assigns authorization to the provided owner
  * @param owner Address of the owner of this contract
  */
  constructor (address owner) public {
    transferOwnership(owner);
  }

  /**
  * @dev Authorize a user under the onlyAuthorizedMintRequester modifier
  * @param user Address to authorize
  */
  function authorizeMintRequester(address user) public onlyOwner {
    require(user != owner());
    require(!mintRequestAuthorization[user]);
    require(!mintFulfillAuthorization[user]);
    mintRequestAuthorization[user] = true;
  }

  /**
  * @dev Deauthorize a user under the onlyAuthorizedMintRequester modifier
  * @param user Address to deauthorize
  */
  function deauthorizeMintRequester(address user) public onlyOwner {
    require(mintRequestAuthorization[user]);
    mintRequestAuthorization[user] = false;
  }

  /**
  * @dev Authorize a user under the onlyAuthorizedMintFulfiller modifier
  * @param user Address to authorize
  */
  function authorizeMintFulfiller(address user) public onlyOwner {
    require(user != owner());
    require(!mintRequestAuthorization[user]);
    require(!mintFulfillAuthorization[user]);
    mintFulfillAuthorization[user] = true;
  }

  /**
  * @dev Deauthorize a user under the onlyAuthorizedMintFulfiller modifier
  * @param user Address to deauthorize
  */
  function deauthorizeMintFulfiller(address user) public onlyOwner {
    require(mintFulfillAuthorization[user]);
    mintFulfillAuthorization[user] = false;
  }

  /**
  * @dev Authorize a user under the onlyAuthorizedBurnRequester modifier
  * @param user Address to authorize
  */
  function authorizeBurnRequester(address user) public onlyOwner {
    require(user != owner());
    require(!burnRequestAuthorization[user]);
    require(!burnFulfillAuthorization[user]);
    burnRequestAuthorization[user] = true;
  }

  /**
  * @dev Deauthorize a user under the onlyAuthorizedBurnRequester modifier
  * @param user Address to deauthorize
  */
  function deauthorizeBurnRequester(address user) public onlyOwner {
    require(burnRequestAuthorization[user]);
    burnRequestAuthorization[user] = false;
  }

  /**
  * @dev Authorize a user under the onlyAuthorizedBurnFulfiller modifier
  * @param user Address to authorize
  */
  function authorizeBurnFulfiller(address user) public onlyOwner {
    require(user != owner());
    require(!burnRequestAuthorization[user]);
    require(!burnFulfillAuthorization[user]);
    burnFulfillAuthorization[user] = true;
  }

  /**
  * @dev Deauthorize a user under the onlyAuthorizedBurnFulfiller modifier
  * @param user Address to deauthorize
  */
  function deauthorizeBurnFulfiller(address user) public onlyOwner {
    require(burnFulfillAuthorization[user]);
    burnFulfillAuthorization[user] = false;
  }
}

/**
 * @title Authorizable
 * @dev Authorizable offers a modifier to verify authorization of a user and functions to authorize/deauthorize users
 */
contract Authorizable is Ownable {
  mapping (address => bool) public authorized;

  /**
  * @dev constructor automatically authorizes the contract creator
  * @param owner address of the contract owner
  */
  constructor (address owner) public {
    transferOwnership(owner);
  }

  /**
  * @dev runs a function only after checking if a user is authorized
  * @param user address to verify authorization of
  */
  modifier isAuthorized(address user) {
    require(user != owner(), "Owner is not authorized");
    require(authorized[user], "Not authorized");

    _;
  }

  /**
  * @dev authorize a user under the isAuthorized modifier
  * @param user address to authorize
  */
  function authorize(address user) public onlyOwner {
    require(!authorized[user], "Already authorized");

    authorized[user] = true;
  }

  /**
  * @dev deauthorize a user under the isAuthorized modifier
  * @param user address to deauthorize
  */
  function deauthorize(address user) public onlyOwner {
    require(authorized[user], "Already unauthorized");

    authorized[user] = false;
  }
}


/**
 * @title ProxyTokenRequestsStorageV0
 */
contract ProxyTokenRequestsStorageV0 is Authorizable {
  using SafeMath for uint256;

  enum Status { NEW, FULFILLED, CANCELLED, REJECTED }

  /**
  * @notice MintRequest organizes data for requests involving token minting
  * @param status the status of the request
  * @param mintID the id of the request
  * @param addressMap String to address mapping
  * @param uintMap String to uint256 mapping
  * @param stringMap String to string mapping
  */
  struct MintRequest {
    Status status;
    uint256 mintID;

    mapping (string => address) addressMap;
    mapping (string => uint256) uintMap;
    mapping (string => string) stringMap;
  }

  /**
  * @notice BurnRequest organizes data for requests involving token burning
  * @param status the status of the request
  * @param burnID the id of the request
  * @param addressMap String to address mapping
  * @param uintMap String to uint256 mapping
  * @param stringMap String to string mapping
  */
  struct BurnRequest {
    Status status;
    uint256 burnID;

    mapping (string => address) addressMap;
    mapping (string => uint256) uintMap;
    mapping (string => string) stringMap;
  }

  MintRequest[] public mintRequests;
  BurnRequest[] public burnRequests;

  function getBurnRequestsLength () public view returns(uint256) { return burnRequests.length; }
  function getMintRequestsLength () public view returns(uint256) { return mintRequests.length; }

  /**
  * @notice Constructor for the ProxyTokenRequestsStorageV0
  * @param owner address of owner
  */
  constructor(address owner) public Authorizable(owner) {}


  /**
  * @dev Runs a function only after checking if the requestId
  * is a valid burn request
  * @param requestId Identification for burn request
  */
  modifier onlyValidBurnRequest(uint256 requestId) {
    require(requestId < burnRequests.length, "Not a valid burn request ID");

    _;
  }

  /**
  * @dev Runs a function only after checking if the requestId
  * is a valid mint request
  * @param requestId Identification for mint request
  */
  modifier onlyValidMintRequest(uint256 requestId) {
    require(requestId < mintRequests.length, "Not a valid mint request ID");

    _;
  }

  /**
  * @notice Initialize a mint request
  */
  function createMintRequest()
    public
    isAuthorized(msg.sender)
    returns (uint256)
  {
    uint256 requestId = mintRequests.length;

    mintRequests.push(MintRequest(Status.NEW, requestId));

    return requestId;
  }

  /**
  * @notice Initialize a burn request
  */
  function createBurnRequest()
    public
    isAuthorized(msg.sender)
    returns (uint256)
  {
    uint256 requestId = burnRequests.length;

    burnRequests.push(BurnRequest(Status.NEW, requestId));

    return requestId;
  }

  /**
  * @notice Return a mintRequest status
  * @param mintRequestID mintRequestID of mint request
  */
  function getMintRequestStatus(
    uint256 mintRequestID)
    public
    onlyValidMintRequest(mintRequestID)
    view
    returns (Status)
  {
    MintRequest storage request = mintRequests[mintRequestID];

    return request.status;
  }

  /**
  * @notice Return a burnRequest status
  * @param burnRequestID burnRequestID of burn request
  */
  function getBurnRequestStatus(
    uint256 burnRequestID)
    public
    onlyValidBurnRequest(burnRequestID)
    view
    returns (Status)
  {
    BurnRequest storage request = burnRequests[burnRequestID];

    return request.status;
  }

  /**
  * @notice Get a mintRequest&#39;s addressMap value with a specific key
  * @param mintRequestID mintRequestID of mint request to return
  * @param key Key value for addressMap
  */
  function getMintRequestAddressMap(
    uint256 mintRequestID,
    string key)
    public
    onlyValidMintRequest(mintRequestID)
    view
    returns (address)
  {
    MintRequest storage request = mintRequests[mintRequestID];

    return request.addressMap[key];
  }

  /**
  * @notice Get a burnRequest&#39;s addressMap value with a specific key
  * @param burnRequestID burnRequestID of mint request to return
  * @param key Key value for addressMap
  */
  function getBurnRequestAddressMap(
    uint256 burnRequestID,
    string key)
    public
    onlyValidBurnRequest(burnRequestID)
    view
    returns (address)
  {
    BurnRequest storage request = burnRequests[burnRequestID];

    return request.addressMap[key];
  }

  /**
  * @notice Get a mintRequest&#39;s uintMap value with a specific key
  * @param mintRequestID mintRequestID of mint request to return
  * @param key Key value for uintMap
  */
  function getMintRequestUintMap(
    uint256 mintRequestID,
    string key)
    public
    onlyValidMintRequest(mintRequestID)
    view
    returns (uint256)
  {
    MintRequest storage request = mintRequests[mintRequestID];

    return request.uintMap[key];
  }

  /**
  * @notice Get a burnRequest&#39;s uintMap value with a specific key
  * @param burnRequestID burnRequestID of mint request to return
  * @param key Key value for uintMap
  */
  function getBurnRequestUintMap(
    uint256 burnRequestID,
    string key)
    public
    onlyValidBurnRequest(burnRequestID)
    view
    returns (uint256)
  {
    BurnRequest storage request = burnRequests[burnRequestID];

    return request.uintMap[key];
  }

  /**
  * @notice Get a mintRequest&#39;s stringMap value with a specific key
  * @param mintRequestID mintRequestID of mint request to return
  * @param key Key value for stringMap
  */
  function getMintRequestStringMap(
    uint256 mintRequestID,
    string key)
    public
    onlyValidMintRequest(mintRequestID)
    view
    returns (string)
  {
    MintRequest storage request = mintRequests[mintRequestID];

    return request.stringMap[key];
  }

  /**
  * @notice Get a burnRequest&#39;s stringMap value with a specific key
  * @param burnRequestID burnRequestID of mint request to return
  * @param key Key value for stringMap
  */
  function getBurnRequestStringMap(
    uint256 burnRequestID,
    string key)
    public
    onlyValidBurnRequest(burnRequestID)
    view
    returns (string)
  {
    BurnRequest storage request = burnRequests[burnRequestID];

    return request.stringMap[key];
  }

  /**
  * @notice Modify a mintRequest status
  * @param mintRequestID mintRequestID of mint request to modify
  * @param newStatus New status to be set
  */
  function setMintRequestStatus(
    uint256 mintRequestID,
    Status newStatus)
    public
    isAuthorized(msg.sender)
    onlyValidMintRequest(mintRequestID)
  {
    MintRequest storage request = mintRequests[mintRequestID];

    request.status = newStatus;
  }

  /**
  * @notice Modify a burnRequest status
  * @param burnRequestID burnRequestID of burn request to modify
  * @param newStatus New status to be set
  */
  function setBurnRequestStatus(
    uint256 burnRequestID,
    Status newStatus)
    public
    isAuthorized(msg.sender)
    onlyValidBurnRequest(burnRequestID)
  {
    BurnRequest storage request = burnRequests[burnRequestID];

    request.status = newStatus;
  }

  /**
  * @notice Modify a mintRequest&#39;s addressMap with a specific key pair
  * @param mintRequestID mintRequestID of mint request to modify
  * @param key Key value for addressMap
  * @param value Value addressMap[key] will be changed to
  */
  function setMintRequestAddressMap(
    uint256 mintRequestID,
    string key,
    address value)
    public
    isAuthorized(msg.sender)
    onlyValidMintRequest(mintRequestID)
  {
    MintRequest storage request = mintRequests[mintRequestID];

    request.addressMap[key] = value;
  }

  /**
  * @notice Modify a burnRequest&#39;s addressMap with a specific key pair
  * @param burnRequestID burnRequestID of burn request to modify
  * @param key Key value for addressMap
  * @param value Value addressMap[key] will be changed to
  */
  function setBurnRequestAddressMap(
    uint256 burnRequestID,
    string key,
    address value)
    public
    isAuthorized(msg.sender)
    onlyValidBurnRequest(burnRequestID)
  {
    BurnRequest storage request = burnRequests[burnRequestID];

    request.addressMap[key] = value;
  }

  /**
  * @notice Modify a mintRequest&#39;s uintMap with a specific key pair
  * @param mintRequestID mintRequestID of mint request to modify
  * @param key Key value for uintMap
  * @param value Value uintMap[key] will be changed to
  */
  function setMintRequestUintMap(
    uint256 mintRequestID,
    string key,
    uint value)
    public
    isAuthorized(msg.sender)
    onlyValidMintRequest(mintRequestID)
  {
    MintRequest storage request = mintRequests[mintRequestID];

    request.uintMap[key] = value;
  }

  /**
  * @notice Modify a burnRequest&#39;s uintMap with a specific key pair
  * @param burnRequestID burnRequestID of burn request to modify
  * @param key Key value for uintMap
  * @param value Value uintMap[key] will be changed to
  */
  function setBurnRequestUintMap(
    uint256 burnRequestID,
    string key,
    uint value)
    public
    isAuthorized(msg.sender)
    onlyValidBurnRequest(burnRequestID)
  {
    BurnRequest storage request = burnRequests[burnRequestID];

    request.uintMap[key] = value;
  }

  /**
  * @notice Modify a mintRequest&#39;s stringMap with a specific key pair
  * @param mintRequestID mintRequestID of mint request to modify
  * @param key Key value for stringMap
  * @param value Value stringMap[key] will be changed to
  */
  function setMintRequestStringMap(
    uint256 mintRequestID,
    string key,
    string value)
    public
    isAuthorized(msg.sender)
    onlyValidMintRequest(mintRequestID)
  {
    MintRequest storage request = mintRequests[mintRequestID];

    request.stringMap[key] = value;
  }

  /**
  * @notice Modify a burnRequest&#39;s stringMap with a specific key pair
  * @param burnRequestID burnRequestID of burn request to modify
  * @param key Key value for stringMap
  * @param value Value stringMap[key] will be changed to
  */
  function setBurnRequestStringMap(
    uint256 burnRequestID,
    string key,
    string value)
    public
    isAuthorized(msg.sender)
    onlyValidBurnRequest(burnRequestID)
  {
    BurnRequest storage request = burnRequests[burnRequestID];

    request.stringMap[key] = value;
  }
}