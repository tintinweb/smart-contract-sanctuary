pragma solidity ^0.4.24;

// File: contracts/MintableERC20.sol

interface MintableERC20 {

    function mint(address _to, uint256 _value) public;
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
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

// File: openzeppelin-solidity/contracts/access/Whitelist.sol

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
    onlyOwner
    public
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
    onlyOwner
    public
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
    onlyOwner
    public
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
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/FanCrowdsale.sol

contract FanCrowdsale is Pausable {
  using SafeMath for uint256;
  using AddressUtils for address;

  // helper with wei
  uint256 constant COIN = 1 ether;

  // token
  MintableERC20 public mintableToken;

  // wallet to hold funds
  address public wallet;

  Whitelist public whitelist;

  // Stage
  // ============
  struct Stage {
    uint tokenAllocated;
    uint rate;
  }

  uint8 public currentStage;
  mapping (uint8 => Stage) public stages;
  uint8 public totalStages; //stages count

  // Amount raised
  // ==================
  uint256 public totalTokensSold;
  uint256 public totalWeiRaised;

  // timed
  // ======
  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && !hasClosed());
    _;
  }

  // Token Cap
  // =============================
  uint256 public totalTokensForSale; // = 424000000 * COIN; // tokens be sold in Crowdsale

  // Finalize
  // =============================
  bool public isFinalized = false;


  // Constructor
  // ============
  /**
   * @dev constructor
   * @param _token token contract address
   * @param _startTime start time of crowdscale
   * @param _endTime end time of crowdsale
   * @param _wallet foundation/multi-sig wallet to store raised eth
   * @param _cap max eth to raise in wei
   */
  constructor(
    address _token,
    uint256 _startTime,
    uint256 _endTime,
    address _wallet,
    uint256 _cap) public
  {
    require(_wallet != address(0), "need a good wallet to store fund");
    require(_token != address(0), "token is not deployed?");
    // require(_startTime > block.timestamp, "startTime must be in future");
    require(_endTime > _startTime, "endTime must be greater than startTime");

    // make sure this crowdsale contract has ability to mint or make sure token&#39;s mint authority has me
    // yet fan token contract doesn&#39;t expose a public check func must manually make sure crowdsale contract address is added to authorities of token contract
    mintableToken  = MintableERC20(_token);
    wallet = _wallet;

    openingTime = _startTime;
    closingTime = _endTime;

    totalTokensForSale  = _cap;

    _initStages();
    _setCrowdsaleStage(0);

    // require that the sum of the stages is equal to the totalTokensForSale, _cap is for double check
    require(stages[totalStages - 1].tokenAllocated == totalTokensForSale);
    
  }
  // =============

  // fallback
  function () external payable {
    purchase(msg.sender);
  }

  function purchase(address _buyer) public payable whenNotPaused onlyWhileOpen {
    contribute(_buyer, msg.value);
  }
  
  // Token Purchase
  // =========================

  /**
   * @dev crowdsale must be open and we do not accept contribution sent from contract
   * because we credit tokens back it might trigger problem, eg, from exchange withdraw contract
   */
  function contribute(address _buyer, uint256 _weiAmount) internal {
    require(_buyer != address(0));
    require(!_buyer.isContract());
    require(whitelist.whitelist(_buyer));

    if (_weiAmount == 0) {
      return;
    }

    // double check not to over sell
    require(totalTokensSold < totalTokensForSale);

    uint currentRate = stages[currentStage].rate;
    uint256 tokensToMint = _weiAmount.mul(currentRate);

    // refund excess
    uint256 saleableTokens;
    uint256 acceptedWei;
    if (currentStage == (totalStages - 1) && totalTokensSold.add(tokensToMint) > totalTokensForSale) {
      saleableTokens = totalTokensForSale - totalTokensSold;
      acceptedWei = saleableTokens.div(currentRate);

      _buyTokensInCurrentStage(_buyer, acceptedWei, saleableTokens);

      // return the excess
      uint256 weiToRefund = _weiAmount.sub(acceptedWei);
      _buyer.transfer(weiToRefund);
      emit EthRefunded(_buyer, weiToRefund);
    } else if (totalTokensSold.add(tokensToMint) < stages[currentStage].tokenAllocated) {
      _buyTokensInCurrentStage(_buyer, _weiAmount, tokensToMint);
    } else {
      // cross stage yet within cap
      saleableTokens = stages[currentStage].tokenAllocated.sub(totalTokensSold);
      acceptedWei = saleableTokens.div(currentRate);

      // buy first stage partial
      _buyTokensInCurrentStage(_buyer, acceptedWei, saleableTokens);

      // update stage
      if (totalTokensSold >= stages[currentStage].tokenAllocated && currentStage + 1 < totalStages) {
        _setCrowdsaleStage(currentStage + 1);
      }

      // buy next stage for the rest
      if ( _weiAmount.sub(acceptedWei) > 0)
      {
        contribute(_buyer, _weiAmount.sub(acceptedWei));
      }
    }
  }

  function changeWhitelist(address _newWhitelist) public onlyOwner {
    require(_newWhitelist != address(0));
    emit WhitelistTransferred(whitelist, _newWhitelist);
    whitelist = Whitelist(_newWhitelist);
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime || totalTokensSold >= totalTokensForSale;
  }

  /**
   * @dev extend closing time to a future time
   */
  function extendClosingTime(uint256 _extendToTime) public onlyOwner onlyWhileOpen {
    closingTime = _extendToTime;
  }

  // ===========================

  // Finalize Crowdsale
  // ====================================================================

  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    emit Finalized();

    isFinalized = true;
  }


  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  // Crowdsale Stage Management
  // =========================================================
  // Change Crowdsale Stage. Available Options: 0..4
  function _setCrowdsaleStage(uint8 _stageId) internal {
    require(_stageId >= 0 && _stageId < totalStages);

    currentStage = _stageId;

    emit StageUp(_stageId);
  }

  function _initStages() internal {
    // production setting
    stages[0] = Stage(25000000 * COIN, 12500);
    stages[1] = Stage(stages[0].tokenAllocated + 46000000 * COIN, 11500);
    stages[2] = Stage(stages[1].tokenAllocated + 88000000 * COIN, 11000);
    stages[3] = Stage(stages[2].tokenAllocated + 105000000 * COIN, 10500);
    stages[4] = Stage(stages[3].tokenAllocated + 160000000 * COIN, 10000);

    // development setting
    // 0.1 ETH allocation per stage for faster forward test
    // stages[0] = Stage(1250 * COIN,                            12500);    // 1 Ether(wei) = 12500 Coin(wei)
    // stages[1] = Stage(stages[0].tokenAllocated + 1150 * COIN, 11500);
    // stages[2] = Stage(stages[1].tokenAllocated + 1100 * COIN, 11000);
    // stages[3] = Stage(stages[2].tokenAllocated + 1050 * COIN, 10500);
    // stages[4] = Stage(stages[3].tokenAllocated + 1000 * COIN, 10000);

    totalStages = 5;
  }

  /**
   * @dev perform buyTokens action for buyer
   * @param _buyer Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _buyTokensInCurrentStage(address _buyer, uint _weiAmount, uint _tokenAmount) internal {
    totalWeiRaised = totalWeiRaised.add(_weiAmount);
    totalTokensSold = totalTokensSold.add(_tokenAmount);

    // mint tokens to buyer&#39;s account
    mintableToken.mint(_buyer, _tokenAmount);
    wallet.transfer(_weiAmount);

    emit TokenPurchase(_buyer, _weiAmount, _tokenAmount);
  }


//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) onlyOwner public {
      if (_token == 0x0) {
          owner.transfer(address(this).balance);
          return;
      }

      ERC20 token = ERC20(_token);
      uint balance = token.balanceOf(this);
      token.transfer(owner, balance);

      emit ClaimedTokens(_token, owner, balance);
  }

////////////////
// Events
////////////////
  event StageUp(uint8 stageId);

  event EthRefunded(address indexed buyer, uint256 value);

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  event WhitelistTransferred(address indexed previousWhitelist, address indexed newWhitelist);

  event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);

  event Finalized();

  // debug log event
  event DLog(uint num, string msg);
}