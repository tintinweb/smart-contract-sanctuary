/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-18
*/

// File: openzeppelin-solidity/contracts/AddressUtils.sol

pragma solidity ^0.4.23;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.23;


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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.23;



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
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/NokuPricingPlan.sol

pragma solidity ^0.4.23;

/**
* @dev The NokuPricingPlan contract defines the responsibilities of a Noku pricing plan.
*/
contract NokuPricingPlan {
    /**
    * @dev Pay the fee for the service identified by the specified name.
    * The fee amount shall already be approved by the client.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @param client The client of the target service.
    * @return true if fee has been paid.
    */
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

    /**
    * @dev Get the usage fee for the service identified by the specified name.
    * The returned fee amount shall be approved before using #payFee method.
    * @param serviceName The name of the target service.
    * @param multiplier The multiplier of the base service fee to apply.
    * @return The amount to approve before really paying such fee.
    */
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
}

// File: contracts/NokuCustomService.sol

pragma solidity ^0.4.23;




contract NokuCustomService is Pausable {
    using AddressUtils for address;

    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers
    NokuPricingPlan public pricingPlan;

    constructor(address _pricingPlan) internal {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");

        pricingPlan = NokuPricingPlan(_pricingPlan);
    }

    function setPricingPlan(address _pricingPlan) public onlyOwner {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");
        require(NokuPricingPlan(_pricingPlan) != pricingPlan, "_pricingPlan equal to current");
        
        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: contracts/NokuCustomToken.sol

pragma solidity ^0.4.23;



contract NokuCustomToken is Ownable {

    event LogBurnFinished();
    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

    // The pricing plan determining the fee to be paid in NOKU tokens by customers for using Noku services
    NokuPricingPlan public pricingPlan;

    // The entity acting as Custom Token service provider i.e. Noku
    address public serviceProvider;

    // Flag indicating if Custom Token burning has been permanently finished or not.
    bool public burningFinished;

    /**
    * @dev Modifier to make a function callable only by service provider i.e. Noku.
    */
    modifier onlyServiceProvider() {
        require(msg.sender == serviceProvider, "caller is not service provider");
        _;
    }

    modifier canBurn() {
        require(!burningFinished, "burning finished");
        _;
    }

    constructor(address _pricingPlan, address _serviceProvider) internal {
        require(_pricingPlan != 0, "_pricingPlan is zero");
        require(_serviceProvider != 0, "_serviceProvider is zero");

        pricingPlan = NokuPricingPlan(_pricingPlan);
        serviceProvider = _serviceProvider;
    }

    /**
    * @dev Presence of this function indicates the contract is a Custom Token.
    */
    function isCustomToken() public pure returns(bool isCustom) {
        return true;
    }

    /**
    * @dev Stop burning new tokens.
    * @return true if the operation was successful.
    */
    function finishBurning() public onlyOwner canBurn returns(bool finished) {
        burningFinished = true;

        emit LogBurnFinished();

        return true;
    }

    /**
    * @dev Change the pricing plan of service fee to be paid in NOKU tokens.
    * @param _pricingPlan The pricing plan of NOKU token to be paid, zero means flat subscription.
    */
    function setPricingPlan(address _pricingPlan) public onlyServiceProvider {
        require(_pricingPlan != 0, "_pricingPlan is 0");
        require(_pricingPlan != address(pricingPlan), "_pricingPlan == pricingPlan");

        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.23;


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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.23;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

pragma solidity ^0.4.23;



/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

pragma solidity ^0.4.23;




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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

pragma solidity ^0.4.23;




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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

pragma solidity ^0.4.23;




/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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
    hasMintPermission
    canMint
    public
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
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

pragma solidity ^0.4.23;



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
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: contracts/openzeppelin-origin/introspection/ERC165.sol

pragma solidity ^0.4.24;


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

// File: contracts/openzeppelin-origin/introspection/SupportsInterfaceWithLookup.sol

pragma solidity ^0.4.24;



/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
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

// File: openzeppelin-solidity/contracts/ownership/rbac/Roles.sol

pragma solidity ^0.4.23;


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
   * @dev remove an address' access to this role
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

pragma solidity ^0.4.23;



/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It's also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

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
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: contracts/ERC2980/Issuable.sol

pragma solidity ^0.4.24;




/**
 * @title Issuable
 * @dev The Issuable contract defines the issuer role who can perform certain kind of actions
 * even if he is not the owner.
 * An issuer can transfer his role to a new address.
 */
contract Issuable is Ownable, RBAC {
  string public constant ROLE_ISSUER = "issuer";

  /**
   * @dev Throws if called by any account that's not a issuer.
   */
  modifier onlyIssuer() {
    require(isIssuer(msg.sender), 'Issuable: caller is not the issuer');
    _;
  }

  modifier onlyOwnerOrIssuer() {
    require(msg.sender == owner || isIssuer(msg.sender), 'Issuable: caller is not the issuer or the owner');
    _;
  }

  /**
   * @dev getter to determine if address has issuer role
   */
  function isIssuer(address _addr) public view returns (bool) {
    return hasRole(_addr, ROLE_ISSUER);
  }

  /**
   * @dev add a new issuer address
   * @param _operator address
   * @return true if the address was not an issuer, false if the address was already an issuer
   */
  function addIssuer(address _operator) public onlyOwner {
    addRole(_operator, ROLE_ISSUER);
  }

    /**
   * @dev remove an address from issuers
   * @param _operator address
   * @return true if the address has been removed from issuers,
   * false if the address wasn't in the issuer list in the first place
   */
  function removeIssuer(address _operator) public onlyOwner {
    removeRole(_operator, ROLE_ISSUER);
  }

  /**
   * @dev Allows the current issuer to transfer his role to a newIssuer.
   * @param _newIssuer The address to transfer the issuer role to.
   */
  function transferIssuer(address _newIssuer) public onlyIssuer {
    require(_newIssuer != address(0));
    removeRole(msg.sender, ROLE_ISSUER);
    addRole(_newIssuer, ROLE_ISSUER);
  }

}

// File: contracts/ERC2980/Whitelist.sol

pragma solidity ^0.4.24;


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
    By default whitelist in not enabled.
 */
contract Whitelist is Issuable {
  string public constant ROLE_WHITELISTED = "whitelist";
  bool public whitelistEnabled;

  constructor(bool enableWhitelist)
    public {
      whitelistEnabled = enableWhitelist;
  }

  /**
   * @dev Throws if operator is not whitelisted and whitelist is enabled.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    if(whitelistEnabled) {
      checkRole(_operator, ROLE_WHITELISTED);
    }
    _;
  }

  function enableWhitelist() public onlyOwner {
    whitelistEnabled = true;
  }

  function disableWhitelist() public onlyOwner {
    whitelistEnabled = false;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator) public onlyIssuer {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator) public view returns (bool) {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators) public onlyIssuer {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator) public onlyIssuer {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators) public onlyIssuer {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

// File: contracts/ERC2980/Frozenlist.sol

pragma solidity ^0.4.24;


/**
 * @title Frozenlist
 * @dev The Frozenlist contract has a frozen list of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Frozenlist is Issuable {

  event FundsFrozen(address target);

  string public constant ROLE_FROZENLIST = "frozenlist";

  /**
   * @dev Throws if operator is frozen.
   * @param _operator address
   */
  modifier onlyIfNotFrozen(address _operator) {
    require(!hasRole(_operator, ROLE_FROZENLIST), "Account frozen");
    _;
  }

  /**
   * @dev add an address to the frozenlist
   * @param _operator address
   * @return true if the address was added to the frozenlist, false if the address was already in the frozenlist
   */
  function addAddressToFrozenlist(address _operator) public onlyIssuer {
    addRole(_operator, ROLE_FROZENLIST);
    emit FundsFrozen(_operator);
  }

  /**
   * @dev getter to determine if address is in frozenlist
   */
  function frozenlist(address _operator) public view returns (bool) {
    return hasRole(_operator, ROLE_FROZENLIST);
  }

  /**
   * @dev add addresses to the frozenlist
   * @param _operators addresses
   * @return true if at least one address was added to the frozenlist,
   * false if all addresses were already in the frozenlist
   */
  function addAddressesToFrozenlist(address[] _operators) public onlyIssuer {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToFrozenlist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the frozenlist
   * @param _operator address
   * @return true if the address was removed from the frozenlist,
   * false if the address wasn't in the frozenlist in the first place
   */
  function removeAddressFromFrozenlist(address _operator) public onlyIssuer {
    removeRole(_operator, ROLE_FROZENLIST);
  }

  /**
   * @dev remove addresses from the frozenlist
   * @param _operators addresses
   * @return true if at least one address was removed from the frozenlist,
   * false if all addresses weren't in the frozenlist in the first place
   */
  function removeAddressesFromFrozenlist(address[] _operators) public onlyIssuer {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromFrozenlist(_operators[i]);
    }
  }

}

// File: contracts/ERC2980/ERC2980.sol

pragma solidity ^0.4.23;

interface ERC2980 {
  
  /// @dev This emits when funds are reassigned
  event FundsReassigned(address from, address to, uint256 amount);

  /// @dev This emits when funds are revoked
  event FundsRevoked(address from, uint256 amount);

  /// @dev This emits when an address is frozen
  event FundsFrozen(address target);

  /**
  * @dev getter to determine if address is in frozenlist
  */
  function frozenlist(address _operator) external view returns (bool);

  /**
  * @dev getter to determine if address is in whitelist
  */
  function whitelist(address _operator) external view returns (bool);

}

// File: contracts/ERC2980/BasicSecurityToken.sol

pragma solidity ^0.4.23;











contract BasicSecurityToken is SupportsInterfaceWithLookup, ERC2980, Ownable, Issuable, DetailedERC20, MintableToken, BurnableToken, Frozenlist, Whitelist {

    bytes4 internal constant InterfaceId_ERC2980 = 0x780e9d63;
    /**
    * 0x780e9d63 ===
    *   bytes4(keccak256('whitelist(address)')) ^
    *   bytes4(keccak256('frozenlist(address)'))
    */

    constructor(string memory name, string memory symbol, bool enableWhitelist)
    Ownable()
    DetailedERC20(name, symbol, 0)
    Whitelist(enableWhitelist)
    public {
        _registerInterface(InterfaceId_ERC2980);
        addIssuer(owner);
        if(enableWhitelist) {
            addAddressToWhitelist(owner);
        }
    }

    //Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: caller is not the owner');
        _;
    }
    
    //Public functions (place the view and pure functions last)

    function mint(address account, uint256 amount) public onlyOwner onlyIfNotFrozen(account) onlyIfWhitelisted(account) returns (bool) {
        super.mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public onlyIfNotFrozen(msg.sender) {
        super._burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public onlyIfNotFrozen(account) {
        super._burn(account, amount);
    }

    function transfer(address recipient, uint256 amount) public onlyIfNotFrozen(msg.sender) onlyIfNotFrozen(recipient) onlyIfWhitelisted(recipient) returns (bool) {
        require(super.transfer(recipient, amount), "Transfer failed");

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public onlyIfNotFrozen(sender) onlyIfNotFrozen(recipient) onlyIfWhitelisted(recipient) returns (bool) {
        require(super.transferFrom(sender, recipient, amount), "Transfer failed");

        return true;
    }

    function reassign(address from, address to) public onlyIssuer {
        uint256 fundsReassigned = balanceOf(from);
        _transfer(from, to, fundsReassigned);

        emit FundsReassigned(from, to, fundsReassigned);
    }

    function revoke(address from) public onlyIssuer {
        uint256 fundsRevoked = balanceOf(from);
        _transfer(from, msg.sender, fundsRevoked);

        emit FundsRevoked(from, fundsRevoked);
    }

      function transferOwnership(address _newOwner) public onlyOwner {
        if(isIssuer(owner)) {
            if(whitelistEnabled) {
                removeAddressFromWhitelist(owner);
                addAddressToWhitelist(_newOwner);
            }
            transferIssuer(_newOwner);
        }
        super.transferOwnership(_newOwner);
    }

      function renounceOwnership() public onlyOwner {        
        if(whitelistEnabled) {
            removeAddressFromWhitelist(owner);
        }
        removeIssuer(owner);
        super.renounceOwnership();
    }

    //Internal functions

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_value <= balances[_from]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    //Private functions

}

// File: contracts/NokuCustomERC2980.sol

pragma solidity ^0.4.23;




/**
* @dev The NokuCustomERC2980Token contract is a custom ERC2980, a security token ERC20-compliant, token available in the Noku Service Platform (NSP).
* The Noku customer is able to choose the token name, symbol, decimals, initial supply and to administer its lifecycle
* by minting or burning tokens in order to increase or decrease the token supply.
*/
contract NokuCustomERC2980 is NokuCustomToken, BasicSecurityToken {
    using SafeMath for uint256;

    event LogNokuCustomERC2980Created(
        address indexed caller,
        string indexed name,
        string indexed symbol,
        address pricingPlan,
        address serviceProvider
    );
    
    constructor(
        string _name,
        string _symbol,
        bool _enableWhitelist,
        address _pricingPlan,
        address _serviceProvider
    )
    NokuCustomToken(_pricingPlan, _serviceProvider)
    BasicSecurityToken(_name, _symbol, _enableWhitelist) public
    {
        require(bytes(_name).length > 0, "_name is empty");
        require(bytes(_symbol).length > 0, "_symbol is empty");

        emit LogNokuCustomERC2980Created(
            msg.sender,
            _name,
            _symbol,
            _pricingPlan,
            _serviceProvider
        );
    }

}

// File: contracts/NokuCustomERC2980Service.sol

pragma solidity ^0.4.23;



/**
* @dev The NokuCustomERC2980Service contract .
*/
contract NokuCustomERC2980Service is NokuCustomService {
    event LogNokuCustomERC2980ServiceCreated(address caller, address indexed _pricingPlan);

    uint256 public constant CREATE_AMOUNT = 1 * 10**18;

    bytes32 public constant CUSTOM_ERC2980_CREATE_SERVICE_NAME = "NokuCustomERC2980.create";

    constructor(address _pricingPlan) NokuCustomService(_pricingPlan) public {
        emit LogNokuCustomERC2980ServiceCreated(msg.sender, _pricingPlan);
    }

    function createCustomToken(string _name, string _symbol, bool _enableWhitelist, NokuPricingPlan _pricingPlan) public returns(NokuCustomERC2980 customToken) {
        customToken = new NokuCustomERC2980(
            _name,
            _symbol,
            _enableWhitelist,
            _pricingPlan,
            owner
        );

        // Transfer NokuCustomERC2980 ownership to the client
        customToken.transferOwnership(msg.sender);

        require(_pricingPlan.payFee(CUSTOM_ERC2980_CREATE_SERVICE_NAME, CREATE_AMOUNT, msg.sender), "fee payment failed");
    }
}