pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: zeppelin-solidity/contracts/ownership/rbac/Roles.sol

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

// File: zeppelin-solidity/contracts/ownership/rbac/RBAC.sol

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
    RoleAdded(addr, roleName);
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
    RoleRemoved(addr, roleName);
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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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
    Transfer(msg.sender, _to, _value);
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/PausableToken.sol

contract PausableToken is StandardToken, Pausable, RBAC {

    string public constant ROLE_ADMINISTRATOR = "administrator";

    modifier whenNotPausedOrAuthorized() {
        require(!paused || hasRole(msg.sender, ROLE_ADMINISTRATOR));
        _;
    }
    /**
     * @dev Add an address that can administer the token even when paused.
     * @param _administrator Address of the given administrator.
     * @return True if the administrator has been added, false if the address was already an administrator.
     */
    function addAdministrator(address _administrator) onlyOwner public returns (bool) {
        if (isAdministrator(_administrator)) {
            return false;
        } else {
            addRole(_administrator, ROLE_ADMINISTRATOR);
            return true;
        }
    }

    /**
     * @dev Remove an administrator.
     * @param _administrator Address of the administrator to be removed.
     * @return True if the administrator has been removed,
     *  false if the address wasn&#39;t an administrator in the first place.
     */
    function removeAdministrator(address _administrator) onlyOwner public returns (bool) {
        if (isAdministrator(_administrator)) {
            removeRole(_administrator, ROLE_ADMINISTRATOR);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Determine if address is an administrator.
     * @param _administrator Address of the administrator to be checked.
     */
    function isAdministrator(address _administrator) public view returns (bool) {
        return hasRole(_administrator, ROLE_ADMINISTRATOR);
    }

    /**
    * @dev Transfer token for a specified address with pause feature for administrator.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public whenNotPausedOrAuthorized returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another with pause feature for administrator.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPausedOrAuthorized returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

// File: contracts/CurrentToken.sol

contract CurrentToken is PausableToken {
    string constant public name = "CurrentCoin";
    string constant public symbol = "CUR";
    uint8 constant public decimals = 18;

    uint256 constant public INITIAL_TOTAL_SUPPLY = 1e11 * (uint256(10) ** decimals);

    /**
    * @dev Create CurrentToken contract and set pause
    */
    function CurrentToken() public {
        totalSupply_ = totalSupply_.add(INITIAL_TOTAL_SUPPLY);
        balances[msg.sender] = totalSupply_;
        Transfer(address(0), msg.sender, totalSupply_);

        pause();
    }
}

// File: contracts/VariableTimeBonusRate.sol

/**
 * @title VariableTimeRate
 * @dev Contract with time dependent token distribution rate variable.
 */
contract VariableTimeBonusRate {
    using SafeMath for uint256;

    // Struct specifying the stages of rate modification.
    struct RateModifier {
        // Percentage by which the rate should be modified.
        uint256 ratePermilles;

        // start time for a given rate
        uint256 start;
    }

    RateModifier[] private modifiers;

    /**
     * @dev Finds currently applicable rate modifier.
     * @return Current rate modifier percentage.
     */
    function currentModifier() public view returns (uint256 rateModifier) {
        // solium-disable-next-line security/no-block-members
        uint256 comparisonVariable = now;
        for (uint i = 0; i < modifiers.length; i++) {
            if (comparisonVariable >= modifiers[i].start) {
                rateModifier = modifiers[i].ratePermilles;
            }
        }
    }

    function getRateModifierInPermilles() public view returns (uint256) {
        return currentModifier();
    }

    /**
     * @dev Adds rate modifier checking not to add one with a start smaller than the previous.
     * @param _rateModifier RateModifier struct.
     */
    function pushModifier(RateModifier _rateModifier) internal {
        require(modifiers.length == 0 || _rateModifier.start > modifiers[modifiers.length - 1].start);
        modifiers.push(_rateModifier);
    }
}

// File: contracts/TokenRate.sol

contract TokenRate is VariableTimeBonusRate {

    uint256 constant public REFERRED_BONUS_PERMILLE  = 5;
    uint256 constant public REFERRAL_BONUS_PERMILLE = 50;

    uint256 public rate;

    function TokenRate(uint256 _rate) public {
        rate = _rate;
    }

    function getCurrentBuyerRateInPermilles(bool isReferred) view public returns (uint256) {
        uint256 permillesRate = VariableTimeBonusRate.getRateModifierInPermilles();
        if (isReferred) {
            permillesRate = permillesRate.add(REFERRED_BONUS_PERMILLE);
        }
        return permillesRate.add(1000);
    }

    /**
     * @dev amount for given wei calculation based on rate modifier percentage.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmountForBuyer(uint256 _weiAmount, bool isReferred) internal view returns (uint256) {
        return _weiAmount.mul(rate).mul(getCurrentBuyerRateInPermilles(isReferred)).div(1000);
    }

    function _getTokenAmountForReferral(uint256 _weiAmount, bool isReferred) internal view returns (uint256) {
        if (isReferred) {
            return _weiAmount.mul(rate).mul(REFERRAL_BONUS_PERMILLE).div(1000);
        }
        return 0;
    }

    /**
     * @dev amount of wei to pay for tokens - calculation based on rate modifier percentage.
     * @param _tokensLeft Value in tokens to be converted into wei
     * @return Number of wei that you must pay (bonus rate is taken into account)
     */
    function _getWeiValueOfTokens(uint256 _tokensLeft, bool isReferred) internal view returns (uint256) {
        uint256 permillesRate = getCurrentBuyerRateInPermilles(isReferred);
        if (isReferred) {
            permillesRate = permillesRate.add(REFERRAL_BONUS_PERMILLE);
        }
        uint256 tokensToBuy = _tokensLeft.mul(1000).div(permillesRate);
        return tokensToBuy.div(rate);
    }

}

// File: contracts/Whitelist.sol

/**
 * @title Whitelist contract
 * @dev Whitelist for wallets.
*/
contract Whitelist is Ownable {
    mapping(address => bool) whitelist;

    uint256 public whitelistLength = 0;

    /**
    * @dev Add wallet to whitelist.
    * @dev Accept request from the owner only.
    * @param _wallet The address of wallet to add.
    */  
    function addWallet(address _wallet) onlyOwner public {
        require(_wallet != address(0));
        require(!isWhitelisted(_wallet));
        whitelist[_wallet] = true;
        whitelistLength++;
    }

    /**
    * @dev Remove wallet from whitelist.
    * @dev Accept request from the owner only.
    * @param _wallet The address of whitelisted wallet to remove.
    */  
    function removeWallet(address _wallet) onlyOwner public {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        whitelist[_wallet] = false;
        whitelistLength--;
    }

    /**
    * @dev Check the specified wallet whether it is in the whitelist.
    * @param _wallet The address of wallet to check.
    */ 
    function isWhitelisted(address _wallet) constant public returns (bool) {
        return whitelist[_wallet];
    }

}

// File: contracts/CurrentCrowdsale.sol

contract CurrentCrowdsale is Pausable, TokenRate {
    using SafeMath for uint256;

    uint256 constant private DECIMALS = 18;
    uint256 constant public HARDCAP_TOKENS_PRE_ICO = 100e6 * (10 ** DECIMALS);
    uint256 constant public HARDCAP_TOKENS_ICO = 499e8 * (10 ** DECIMALS);

    uint256 public startPhase1 = 0;
    uint256 public startPhase2 = 0;
    uint256 public startPhase3 = 0;
    uint256 public endOfPhase3 = 0;

    uint256 public maxcap = 0;

    uint256 public tokensSoldIco = 0;
    uint256 public tokensRemainingIco = HARDCAP_TOKENS_ICO;
    uint256 public tokensSoldTotal = 0;

    uint256 public weiRaisedIco = 0;
    uint256 public weiRaisedTotal = 0;

    address private withdrawalWallet;

    CurrentToken public token;
    Whitelist public whitelist;

    modifier beforeReachingHardCap() {
        require(tokensRemainingIco > 0 && weiRaisedIco < maxcap);
        _;
    }

    modifier whenWhitelisted(address _wallet) {
        require(whitelist.isWhitelisted(_wallet));
        _;
    }

    /**
    * @dev Constructor for CurrentCrowdsale contract.
    * @dev Set the owner who can manage whitelist and token.
    * @param _maxcap The maxcap value.
    * @param _startPhase1 The phase1 ICO start time.
    * @param _startPhase2 The phase2 ICO start time.
    * @param _startPhase3 The phase3 ICO start time.
    * @param _endOfPhase3 The end time of ICO.
    * @param _withdrawalWallet The address to which raised funds will be withdrawn.
    * @param _rate exchange rate for ico.
    * @param _token address of token used for ico.
    * @param _whitelist address of whitelist contract used for ico.
    */
    function CurrentCrowdsale(
        uint256 _maxcap,
        uint256 _startPhase1,
        uint256 _startPhase2,
        uint256 _startPhase3,
        uint256 _endOfPhase3,
        address _withdrawalWallet,
        uint256 _rate,
        CurrentToken _token,
        Whitelist _whitelist
    )  TokenRate(_rate) public
    {
        require(_withdrawalWallet != address(0));
        require(_token != address(0) && _whitelist != address(0));
        require(_startPhase1 >= now);
        require(_endOfPhase3 > _startPhase3);
        require(_maxcap > 0);

        token = _token;
        whitelist = _whitelist;

        startPhase1 = _startPhase1;
        startPhase2 = _startPhase2;
        startPhase3 = _startPhase3;
        endOfPhase3 = _endOfPhase3;

        withdrawalWallet = _withdrawalWallet;

        maxcap = _maxcap;
        tokensSoldTotal = HARDCAP_TOKENS_PRE_ICO;
        weiRaisedTotal = tokensSoldTotal.div(_rate.mul(2));

        pushModifier(RateModifier(200, startPhase1));
        pushModifier(RateModifier(150, startPhase2));
        pushModifier(RateModifier(100, startPhase3));
    }

    /**
    * @dev Fallback function can be used to buy tokens.
    */
    function() public payable {
        if (isIco()) {
            sellTokensIco();
        } else {
            revert();
        }
    }

    /**
    * @dev Check whether the ICO is active at the moment.
    */
    function isIco() public constant returns (bool) {
        return now >= startPhase1 && now <= endOfPhase3;
    }

    function sellTokensIco() beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused public payable {
        sellTokens(address(0));
    }

    function sellTokensIcoWithReferal(address referral) beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused public payable {
        if (referral != msg.sender && whitelist.isWhitelisted(referral)) {
            sellTokens(referral);
        } else {
            revert();
        }
    }

    /**
    * @dev Manual send tokens to the specified address.
    * @param _beneficiary The address of a investor.
    * @param _tokensAmount Amount of tokens.
    */
    function manualSendTokens(address _beneficiary, uint256 _tokensAmount) public  onlyOwner {
        require(_beneficiary != address(0));
        require(_tokensAmount > 0);

        token.transfer(_beneficiary, _tokensAmount);
        tokensSoldIco = tokensSoldIco.add(_tokensAmount);
        tokensSoldTotal = tokensSoldTotal.add(_tokensAmount);
        tokensRemainingIco = tokensRemainingIco.sub(_tokensAmount);
    }

    /**
    * @dev Sell tokens during ICO with referral.
    */
    function sellTokens(address referral) beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused internal {
        require(isIco());
        require(msg.value > 0);

        uint256 weiAmount = msg.value;
        uint256 excessiveFunds = 0;

        uint256 plannedWeiTotal = weiRaisedIco.add(weiAmount);

        if (plannedWeiTotal > maxcap) {
            excessiveFunds = plannedWeiTotal.sub(maxcap);
            weiAmount = maxcap.sub(weiRaisedIco);
        }
        bool isReferred = referral != address(0);
        uint256 tokensForUser = _getTokenAmountForBuyer(weiAmount, isReferred);
        uint256 tokensForReferral = _getTokenAmountForReferral(weiAmount, isReferred);
        uint256 tokensAmount = tokensForUser.add(tokensForReferral);

        if (tokensAmount > tokensRemainingIco) {
            uint256 weiToAccept = _getWeiValueOfTokens(tokensRemainingIco, isReferred);
            tokensForReferral = _getTokenAmountForReferral(weiToAccept, isReferred);
            tokensForUser = tokensRemainingIco.sub(tokensForReferral);
            excessiveFunds = excessiveFunds.add(weiAmount.sub(weiToAccept));

            tokensAmount = tokensRemainingIco;
            weiAmount = weiToAccept;
        }

        tokensSoldIco = tokensSoldIco.add(tokensAmount);
        tokensSoldTotal = tokensSoldTotal.add(tokensAmount);
        tokensRemainingIco = tokensRemainingIco.sub(tokensAmount);

        weiRaisedIco = weiRaisedIco.add(weiAmount);
        weiRaisedTotal = weiRaisedTotal.add(weiAmount);

        token.transfer(msg.sender, tokensForUser);
        if (isReferred) {
            token.transfer(referral, tokensForReferral);
        }

        if (excessiveFunds > 0) {
            msg.sender.transfer(excessiveFunds);
        }

        withdrawalWallet.transfer(this.balance);
    }
}