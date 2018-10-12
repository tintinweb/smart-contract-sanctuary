pragma solidity 0.4.24;

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
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
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/CappedToken.sol

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: zeppelin-solidity/contracts/access/rbac/Roles.sol

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

// File: zeppelin-solidity/contracts/access/rbac/RBAC.sol

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

// File: contracts/RBACBurnableToken.sol

/**
 * @title RBACBurnableToken
 * @dev Burnable Token, with RBAC burner permissions
 */
contract RBACBurnableToken is BurnableToken, Ownable, RBAC {
  /**
   * A constant role name for indicating burners.
   */
  string public constant ROLE_BURNER = "burner";

  /**
   * @dev override the Burnable token _burn function
   */
  function _burn(address _who, uint256 _value) internal {
    checkRole(msg.sender, ROLE_BURNER);
    super._burn(_who, _value);    
  }

  /**
   * @dev add a burner role to an address
   * @param _burner address
   */
  function addBurner(address _burner) public onlyOwner {
    addRole(_burner, ROLE_BURNER);
  }

  /**
   * @dev remove a burner role from an address
   * @param _burner address
   */
  function removeBurner(address _burner) public onlyOwner {
    removeRole(_burner, ROLE_BURNER);
  }
}

// File: contracts/ABCToken.sol

contract ABCToken is MintableToken, CappedToken, RBACBurnableToken {
    string public name = "ABC Token";
    string public symbol = "ABC";
    uint8 public decimals = 18;
    function ABCToken
        (
            uint256 _cap
        )
        public 
        CappedToken(_cap) {

        }
}

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: zeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropriate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method: 
   *   super._preValidatePurchase(_beneficiary, _weiAmount);
   *   require(weiRaised.add(_weiAmount) <= cap);
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

// File: zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol

/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
contract MintedCrowdsale is Crowdsale {

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    // Potentially dangerous assumption about the type of the token.
    require(MintableToken(address(token)).mint(_beneficiary, _tokenAmount));
  }
}

// File: zeppelin-solidity/contracts/access/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

// File: zeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol

/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistedCrowdsale is Whitelist, Crowdsale {
  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyIfWhitelisted(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: zeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: zeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Ownable, TimedCrowdsale {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }

}

// File: zeppelin-solidity/contracts/payment/Escrow.sol

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds destinated to a payee until they
 * withdraw them. The contract that uses the escrow as its payment method
 * should be its owner, and provide public methods redirecting to the escrow&#39;s
 * deposit and withdraw.
 */
contract Escrow is Ownable {
  using SafeMath for uint256;

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) private deposits;

  function depositsOf(address _payee) public view returns (uint256) {
    return deposits[_payee];
  }

  /**
  * @dev Stores the sent amount as credit to be withdrawn.
  * @param _payee The destination address of the funds.
  */
  function deposit(address _payee) public onlyOwner payable {
    uint256 amount = msg.value;
    deposits[_payee] = deposits[_payee].add(amount);

    emit Deposited(_payee, amount);
  }

  /**
  * @dev Withdraw accumulated balance for a payee.
  * @param _payee The address whose funds will be withdrawn and transferred to.
  */
  function withdraw(address _payee) public onlyOwner {
    uint256 payment = deposits[_payee];
    assert(address(this).balance >= payment);

    deposits[_payee] = 0;

    _payee.transfer(payment);

    emit Withdrawn(_payee, payment);
  }
}

// File: zeppelin-solidity/contracts/payment/ConditionalEscrow.sol

/**
 * @title ConditionalEscrow
 * @dev Base abstract escrow to only allow withdrawal if a condition is met.
 */
contract ConditionalEscrow is Escrow {
  /**
  * @dev Returns whether an address is allowed to withdraw their funds. To be
  * implemented by derived contracts.
  * @param _payee The destination address of the funds.
  */
  function withdrawalAllowed(address _payee) public view returns (bool);

  function withdraw(address _payee) public {
    require(withdrawalAllowed(_payee));
    super.withdraw(_payee);
  }
}

// File: zeppelin-solidity/contracts/payment/RefundEscrow.sol

/**
 * @title RefundEscrow
 * @dev Escrow that holds funds for a beneficiary, deposited from multiple parties.
 * The contract owner may close the deposit period, and allow for either withdrawal
 * by the beneficiary, or refunds to the depositors.
 */
contract RefundEscrow is Ownable, ConditionalEscrow {
  enum State { Active, Refunding, Closed }

  event Closed();
  event RefundsEnabled();

  State public state;
  address public beneficiary;

  /**
   * @dev Constructor.
   * @param _beneficiary The beneficiary of the deposits.
   */
  constructor(address _beneficiary) public {
    require(_beneficiary != address(0));
    beneficiary = _beneficiary;
    state = State.Active;
  }

  /**
   * @dev Stores funds that may later be refunded.
   * @param _refundee The address funds will be sent to if a refund occurs.
   */
  function deposit(address _refundee) public payable {
    require(state == State.Active);
    super.deposit(_refundee);
  }

  /**
   * @dev Allows for the beneficiary to withdraw their funds, rejecting
   * further deposits.
   */
  function close() public onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
  }

  /**
   * @dev Allows for refunds to take place, rejecting further deposits.
   */
  function enableRefunds() public onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @dev Withdraws the beneficiary&#39;s funds.
   */
  function beneficiaryWithdraw() public {
    require(state == State.Closed);
    beneficiary.transfer(address(this).balance);
  }

  /**
   * @dev Returns whether refundees can withdraw their deposits (be refunded).
   */
  function withdrawalAllowed(address _payee) public view returns (bool) {
    return state == State.Refunding;
  }
}

// File: zeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol

/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 */
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund escrow used to hold funds while crowdsale is running
  RefundEscrow private escrow;

  /**
   * @dev Constructor, creates RefundEscrow.
   * @param _goal Funding goal
   */
  constructor(uint256 _goal) public {
    require(_goal > 0);
    escrow = new RefundEscrow(wallet);
    goal = _goal;
  }

  /**
   * @dev Investors can claim refunds here if crowdsale is unsuccessful
   */
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    escrow.withdraw(msg.sender);
  }

  /**
   * @dev Checks whether funding goal was reached.
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

  /**
   * @dev escrow finalization task, called when owner calls finalize()
   */
  function finalization() internal {
    if (goalReached()) {
      escrow.close();
      escrow.beneficiaryWithdraw();
    } else {
      escrow.enableRefunds();
    }

    super.finalization();
  }

  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to escrow.
   */
  function _forwardFunds() internal {
    escrow.deposit.value(msg.value)(msg.sender);
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

// File: contracts/ABCTokenCrowdsale.sol

contract ABCTokenCrowdsale is WhitelistedCrowdsale, RefundableCrowdsale, MintedCrowdsale {
    
    // ICO Stages
    enum CrowdsaleStage { PrivateSale, PreSale, ICO }
    CrowdsaleStage public stage = CrowdsaleStage.PrivateSale; 

    uint256 public privateSaleRate;
    uint256 public preSaleRate;
    uint256 public publicRate;
    uint256 public totalTokensForSaleDuringPrivateSale;
    uint256 public totalTokensForSaleDuringPreSale;
    uint256 public totalTokensForSale;
    uint256 public privateSaleMinimumTokens;
    uint256 public preSaleMinimumTokens;
    uint256 public tokensForTeam;
    uint256 public tokensForAdvisors;

    uint256 public privateSaleTokensSold = 0;
    uint256 public preSaleTokensSold = 0;
    uint256 public tokensSold = 0;


    // Team, Advisor, Strategic partner Timelocks
    address public teamWallet;
    address public advisorsWallet;

	address public teamTimelock1;
	address public teamTimelock2;
	address public teamTimelock3;
	address public teamTimelock4;
	address public teamTimelock5;
	address public teamTimelock6;
	address public teamTimelock7;
	address public advisorTimelock;
    
	function ABCTokenCrowdsale
        (
        	uint256 _goal,
            uint256 _openingTime,
            uint256 _closingTime,
            uint256 _privateSaleRate,
            uint256 _preSaleRate,
            uint256 _rate,
            uint256 _totalTokensForSaleDuringPrivateSale,
            uint256 _totalTokensForSaleDuringPreSale,
            uint256 _totalTokensForSale,
            uint256 _privateSaleMinimumTokens,
            uint256 _preSaleMinimumTokens,
            uint256 _tokensForTeam,
            uint256 _tokensForAdvisors,
            address _wallet,
            MintableToken _token
        )
        public
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
        RefundableCrowdsale(_goal) {
        
        	uint256 tokenCap = CappedToken(address(_token)).cap();
			require(_totalTokensForSale.add(_tokensForTeam).add(_tokensForAdvisors) <= tokenCap);			
			
            publicRate = _rate;
            preSaleRate = _preSaleRate;
            privateSaleRate = _privateSaleRate;           

			totalTokensForSaleDuringPrivateSale = _totalTokensForSaleDuringPrivateSale;
            totalTokensForSaleDuringPreSale = _totalTokensForSaleDuringPreSale;
            totalTokensForSale = _totalTokensForSale;

			preSaleMinimumTokens = _preSaleMinimumTokens;
    		privateSaleMinimumTokens = _privateSaleMinimumTokens;

			tokensForTeam = _tokensForTeam;
    		tokensForAdvisors = _tokensForAdvisors;

            setCrowdsaleStage(uint(CrowdsaleStage.PrivateSale));
    }
    
    function setCrowdsaleStage(uint value) public onlyOwner {
    
        CrowdsaleStage _stage;
        
        if (uint(CrowdsaleStage.PrivateSale) == value) {
            _stage = CrowdsaleStage.PrivateSale;
        } else if (uint(CrowdsaleStage.PreSale) == value) {
            _stage = CrowdsaleStage.PreSale;
        } else if (uint(CrowdsaleStage.ICO) == value) {
            _stage = CrowdsaleStage.ICO;
        }
        
        stage = _stage;
        
        
        if (stage == CrowdsaleStage.PrivateSale) {
            setCurrentRate(privateSaleRate);
        } else if (stage == CrowdsaleStage.PreSale) {
            setCurrentRate(preSaleRate);
        } else if (stage == CrowdsaleStage.ICO) {
            setCurrentRate(publicRate);
        }
    }
    
    function setTeamWallet(address _wallet) public onlyOwner {
		teamWallet = _wallet;
	}    
    function setAdvisorWallet(address _wallet) public onlyOwner {
		advisorsWallet = _wallet;
	}    

    function setCurrentRate(uint256 _rate) private {
        rate = _rate;
    }
    
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);

        uint256 tokens = _getTokenAmount(_weiAmount);
        if (stage == CrowdsaleStage.PrivateSale) {
            require(tokens >= privateSaleMinimumTokens);
            require(privateSaleTokensSold.add(tokens) <= totalTokensForSaleDuringPrivateSale);
        } else if (stage == CrowdsaleStage.PreSale) {
            require(tokens >= preSaleMinimumTokens);
            require(preSaleTokensSold.add(tokens) <= totalTokensForSaleDuringPreSale);
        }
        require(tokensSold.add(tokens) <= totalTokensForSale);
    }    

    function _postValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        super._postValidatePurchase(_beneficiary, _weiAmount);

        uint256 tokens = _getTokenAmount(_weiAmount);
        if (stage == CrowdsaleStage.PrivateSale) {
            privateSaleTokensSold = privateSaleTokensSold.add(tokens);
        } else if (stage == CrowdsaleStage.PreSale) {
            preSaleTokensSold = preSaleTokensSold.add(tokens);
        }
        tokensSold = tokensSold.add(tokens);
    }    

	function finalization() 
	internal 
	{
    	if(goalReached()) {        
			require(teamWallet != address(0));
			require(advisorsWallet != address(0));

	        // mint team tokens
    	    uint256 teamReleaseTime1 = now + (182.5 * 24 * 60 * 60); // 182.5 days from now
        	teamTimelock1 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 25 / 100 ), teamReleaseTime1);
        
	        uint256 teamReleaseTime2 = teamReleaseTime1 + (91.25 * 24 * 60 * 60); // 91.25 days from last release
    	    teamTimelock2 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime2);
        
        	uint256 teamReleaseTime3 = teamReleaseTime2 + (91.25 * 24 * 60 * 60); // 91.25 days from last release
	        teamTimelock3 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime3);
        
        	uint256 teamReleaseTime4 = teamReleaseTime3 + (91.25 * 24 * 60 * 60); // 91.25 days from last release
        	teamTimelock4 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime4);
        
	        uint256 teamReleaseTime5 = teamReleaseTime4 + (91.25 * 24 * 60 * 60); // 91.25 days from last release
    	    teamTimelock5 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime5);
        
	        uint256 teamReleaseTime6 = teamReleaseTime5 + (91.25 * 24 * 60 * 60); // 91.25 days from last release
    	    teamTimelock6 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime6);
        
	        uint256 teamReleaseTime7 = teamReleaseTime6 + (91.25 * 24 * 60 * 60); // 91.25 days from last release
    	    teamTimelock7 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime7);

	        // mint advisor tokens in 3 months
	        uint256 advisorReleaseTime = now + (91.25 * 24 * 60 * 60); // 91.25 days from now
    	    advisorTimelock = mintTimeLockedTokens(advisorsWallet, tokensForAdvisors, advisorReleaseTime);
        
			MintableToken _mintableToken = MintableToken(token);
			_mintableToken.finishMinting();
		
	      	_mintableToken.transferOwnership(wallet);
    	}
	    super.finalization();    	          
    }    

    function mintTimeLockedTokens(address _to, uint256 _amount, uint256 _releaseTime) private returns (TokenTimelock) {
        TokenTimelock timelock = new TokenTimelock(token, _to, _releaseTime);
        MintableToken(address(token)).mint(timelock, _amount);
        return timelock;
    }        
}