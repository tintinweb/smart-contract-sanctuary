pragma solidity 0.4.25;

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


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title DividendDistributingToken
 * @dev An ERC20-compliant token that distributes any Ether it receives to its token holders proportionate to their share.
 *
 * Implementation exactly based on: https://blog.pennyether.com/posts/realtime-dividend-token.html#the-token
 *
 * The user is responsible for when they transact tokens (transacting before a dividend payout is probably not ideal).
 *
 * `TokenizedProperty` inherits from `this` and is the front-facing contract representing the rights / ownership to a property.
 */
contract DividendDistributingToken is StandardToken {
  using SafeMath for uint256;

  uint256 public constant POINTS_PER_WEI = uint256(10) ** 32;

  uint256 public pointsPerToken = 0;
  mapping(address => uint256) public credits;
  mapping(address => uint256) public lastPointsPerToken;

  event DividendsDeposited(address indexed payer, uint256 amount);
  event DividendsCollected(address indexed collector, uint256 amount);

  function collectOwedDividends() public {
    creditAccount(msg.sender);

    uint256 _wei = credits[msg.sender] / POINTS_PER_WEI;

    credits[msg.sender] = 0;

    msg.sender.transfer(_wei);
    emit DividendsCollected(msg.sender, _wei);
  }

  function creditAccount(address _account) internal {
    uint256 amount = balanceOf(_account).mul(pointsPerToken.sub(lastPointsPerToken[_account]));
    credits[_account] = credits[_account].add(amount);
    lastPointsPerToken[_account] = pointsPerToken;
  }

  function deposit(uint256 _value) internal {
    pointsPerToken = pointsPerToken.add(_value.mul(POINTS_PER_WEI) / totalSupply_);
    emit DividendsDeposited(msg.sender, _value);
  }
}



contract LandRegistryInterface {
  function getProperty(string _eGrid) public view returns (address property);
}


contract LandRegistryProxyInterface {
  function owner() public view returns (address);
  function landRegistry() public view returns (LandRegistryInterface);
}


contract WhitelistInterface {
  function checkRole(address _operator, string _permission) public view;
}


contract WhitelistProxyInterface {
  function whitelist() public view returns (WhitelistInterface);
}


/**
 * @title TokenizedProperty
 * @dev An asset-backed security token (a property as identified by its E-GRID (a UUID) in the (Swiss) land registry).
 *
 * Ownership of `this` must be transferred to `ShareholderDAO` before blockimmo will verify `this` as legitimate in `LandRegistry`.
 * Until verified legitimate, transferring tokens is not possible (locked).
 *
 * Tokens can be freely listed on exchanges (especially decentralized / 0x).
 *
 * `this.owner` can make two suggestions that blockimmo will always (try) to take: `setManagementCompany` and `untokenize`.
 * `this.owner` can also transfer or rescind ownership.
 * See `ShareholderDAO` documentation for more information...
 *
 * Our legal framework requires a `TokenizedProperty` must be possible to `untokenize`.
 * Un-tokenizing is also the first step to upgrading or an outright sale of `this`.
 *
 * For both:
 *   1. `owner` emits an `UntokenizeRequest`
 *   2. blockimmo removes `this` from the `LandRegistry`
 *
 * Upgrading:
 *   3. blockimmo migrates `this` to the new `TokenizedProperty` (ie perfectly preserving `this.balances`)
 *   4. blockimmo attaches `owner` to the property (1)
 *   5. blockimmo adds the property to `LandRegistry`
 *
 * Outright sale:
 *   3. blockimmo deploys a new `TokenizedProperty` and adds it to the `LandRegistry`
 *   4. blockimmo configures and deploys a `TokenSale` for the property with `TokenSale.wallet == address(this)`
 *      (raised Ether distributed to current token holders as a dividend payout)
 *        - if the sale is unsuccessful, the new property is removed from the `LandRegistry`, and `this` is added back
 */
contract TokenizedProperty is Ownable, DividendDistributingToken {
  address public constant LAND_REGISTRY_PROXY_ADDRESS = 0xe72AD2A335AE18e6C7cdb6dAEB64b0330883CD56;  // 0xec8be1a5630364292e56d01129e8ee8a9578d7d8
  address public constant WHITELIST_PROXY_ADDRESS = 0x7223b032180CDb06Be7a3D634B1E10032111F367;  // 0xc4c7497fbe1a886841a195a5d622cd60053c1376;

  LandRegistryProxyInterface public registryProxy = LandRegistryProxyInterface(LAND_REGISTRY_PROXY_ADDRESS);
  WhitelistProxyInterface public whitelistProxy = WhitelistProxyInterface(WHITELIST_PROXY_ADDRESS);

  uint8 public constant decimals = 18;
  uint256 public constant NUM_TOKENS = 1000000;
  string public symbol;

  string public managementCompany;
  string public name;

  mapping(address => uint256) public lastTransferBlock;
  mapping(address => uint256) public minTransferAccepted;

  event MinTransferSet(address indexed account, uint256 minTransfer);
  event ManagementCompanySet(string managementCompany);
  event UntokenizeRequest();
  event Generic(string generic);

  modifier isValid() {
    LandRegistryInterface registry = LandRegistryInterface(registryProxy.landRegistry());
    require(registry.getProperty(name) == address(this), "invalid TokenizedProperty");
    _;
  }

  constructor(string _eGrid, string _grundstuckNumber) public {
    require(bytes(_eGrid).length > 0, "eGrid must be non-empty string");
    require(bytes(_grundstuckNumber).length > 0, "grundstuck must be non-empty string");
    name = _eGrid;
    symbol = _grundstuckNumber;

    totalSupply_ = NUM_TOKENS * (uint256(10) ** decimals);
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }

  function () public payable {  // dividends
    uint256 value = msg.value;
    require(value > 0, "must send wei in fallback");

    address blockimmo = registryProxy.owner();
    if (blockimmo != address(0)) {  // 1% blockimmo fee
      uint256 fee = value / 100;
      blockimmo.transfer(fee);
      value = value.sub(fee);
    }

    deposit(value);
  }

  function setManagementCompany(string _managementCompany) public onlyOwner isValid {
    managementCompany = _managementCompany;
    emit ManagementCompanySet(managementCompany);
  }

  function untokenize() public onlyOwner isValid {
    emit UntokenizeRequest();
  }

  function emitGenericProposal(string _generic) public onlyOwner isValid {
    emit Generic(_generic);
  }

  function transfer(address _to, uint256 _value) public isValid returns (bool) {
    require(_value >= minTransferAccepted[_to], "tokens transferred less than _to&#39;s minimum accepted transfer");
    transferBookKeeping(msg.sender, _to);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public isValid returns (bool) {
    require(_value >= minTransferAccepted[_to], "tokens transferred less than _to&#39;s minimum accepted transfer");
    transferBookKeeping(_from, _to);
    return super.transferFrom(_from, _to, _value);
  }

  function setMinTransfer(uint256 _amount) public {
    minTransferAccepted[msg.sender] = _amount;
    emit MinTransferSet(msg.sender, _amount);
  }

  function transferBookKeeping(address _from, address _to) internal {
    whitelistProxy.whitelist().checkRole(_to, "authorized");

    creditAccount(_from);  // required for dividends...
    creditAccount(_to);

    lastTransferBlock[_from] = block.number;  //required for voting
    lastTransferBlock[_to] = block.number;
  }
}