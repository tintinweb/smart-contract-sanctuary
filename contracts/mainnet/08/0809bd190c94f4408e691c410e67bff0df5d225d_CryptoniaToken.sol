pragma solidity 0.4.21;

/**
 * @title Cryptonia Poker Chips token and crowdsale contracts
 * @author Kirill Varlamov (@ongrid), OnGridSystems
 * @dev https://github.com/OnGridSystems/CryptoniaPokerContracts
 */
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
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


/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 *      Supports unlimited numbers of roles and addresses.
 *      See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = "admin";

  /**
   * @dev constructor. Sets msg.sender as admin by default
   */
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to admins
   * // reverts
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }
}


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

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


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


/**
 * @title Cryptonia Poker Chips Contract
 * @author Kirill Varlamov (@ongrid), OnGrid systems
 * @dev ERC-20 compatible token with zeppelin&#39;s RBAC
 */
contract CryptoniaToken is StandardToken, RBAC {
  string public name = "Cryptonia Poker Chips";
  string public symbol = "CPC";
  uint8 public decimals = 2;
  uint256 public cap = 100000000000;
  bool public mintingFinished = false;
  string constant ROLE_MINTER = "minter";

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyRole(ROLE_MINTER) public returns (bool) {
    require(!mintingFinished);
    require(totalSupply_.add(_amount) <= cap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyAdmin public returns (bool) {
    require(!mintingFinished);
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}


/**
 * @title Crowdsale Contract
 * @author Kirill Varlamov (@ongrid), OnGrid systems
 * @dev Crowdsale is a contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether.
 */
contract CryptoniaCrowdsale is RBAC {
  using SafeMath for uint256;

  struct Phase {
    uint256 startDate;
    uint256 endDate;
    uint256 tokensPerETH;
    uint256 tokensIssued;
  }

  Phase[] public phases;

  // The token being sold
  CryptoniaToken public token;

  // Address where funds get collected
  address public wallet;

  // Minimal allowed purchase is 0.1 ETH
  uint256 public minPurchase = 100000000000000000;

  // Amount of ETH raised in wei. 1 wei is 10e-18 ETH
  uint256 public weiRaised;

  // Amount of tokens issued by this contract
  uint256 public tokensIssued;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @dev Events for contract states changes
   */
  event PhaseAdded(address indexed sender, uint256 index, uint256 startDate, uint256 endDate, uint256 tokensPerETH);
  event PhaseDeleted(address indexed sender, uint256 index);
  event WalletChanged(address newWallet);
  event OracleChanged(address newOracle);

  /**
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token  Address of the token being sold
   */
  function CryptoniaCrowdsale(address _wallet, CryptoniaToken _token) public {
    require(_wallet != address(0));
    require(_token != address(0));
    wallet = _wallet;
    token = _token;
  }

  /**
   * @dev fallback function receiving investor&#39;s ethers
   *      It calculates deposit USD value and corresponding token amount,
   *      runs some checks (if phase cap not exceeded, value and addresses are not null),
   *      then mints corresponding amount of tokens, increments state variables.
   *      After tokens issued Ethers get transferred to the wallet.
   */
  function() external payable {
    uint256 weiAmount = msg.value;
    address beneficiary = msg.sender;
    uint256 currentPhaseIndex = getCurrentPhaseIndex();
    uint256 tokens = weiAmount.mul(phases[currentPhaseIndex].tokensPerETH).div(1 ether);
    require(beneficiary != address(0));
    require(weiAmount >= minPurchase);
    weiRaised = weiRaised.add(weiAmount);
    phases[currentPhaseIndex].tokensIssued = phases[currentPhaseIndex].tokensIssued.add(tokens);
    tokensIssued = tokensIssued.add(tokens);
    token.mint(beneficiary, tokens);
    wallet.transfer(msg.value);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

  /**
   * @dev Checks if dates overlap with existing phases of the contract.
   * @param _startDate  Start date of the phase
   * @param _endDate    End date of the phase
   * @return true if provided dates valid
   */
  function validatePhaseDates(uint256 _startDate, uint256 _endDate) view public returns (bool) {
    if (_endDate <= _startDate) {
      return false;
    }
    for (uint i = 0; i < phases.length; i++) {
      if (_startDate >= phases[i].startDate && _startDate <= phases[i].endDate) {
        return false;
      }
      if (_endDate >= phases[i].startDate && _endDate <= phases[i].endDate) {
        return false;
      }
    }
    return true;
  }

  /**
   * @dev Adds a new phase
   * @param _startDate  Start date of the phase
   * @param _endDate    End date of the phase
   * @param _tokensPerETH  amount of tokens per ETH
   */
  function addPhase(uint256 _startDate, uint256 _endDate, uint256 _tokensPerETH) public onlyAdmin {
    require(validatePhaseDates(_startDate, _endDate));
    require(_tokensPerETH > 0);
    phases.push(Phase(_startDate, _endDate, _tokensPerETH, 0));
    uint256 index = phases.length - 1;
    emit PhaseAdded(msg.sender, index, _startDate, _endDate, _tokensPerETH);
  }

  /**
   * @dev Delete phase by its index
   * @param index Index of the phase
   */
  function delPhase(uint256 index) public onlyAdmin {
    require (index < phases.length);

    for (uint i = index; i < phases.length - 1; i++) {
      phases[i] = phases[i + 1];
    }
    phases.length--;
    emit PhaseDeleted(msg.sender, index);
  }

  /**
   * @dev Return current phase index
   * @return current phase id
   */
  function getCurrentPhaseIndex() view public returns (uint256) {
    for (uint i = 0; i < phases.length; i++) {
      if (phases[i].startDate <= now && now <= phases[i].endDate) {
        return i;
      }
    }
    revert();
  }

  /**
   * @dev Set new wallet to collect ethers
   * @param _newWallet EOA or the contract adderess of the new receiver
   */
  function setWallet(address _newWallet) onlyAdmin public {
    require(_newWallet != address(0));
    wallet = _newWallet;
    emit WalletChanged(_newWallet);
  }
}