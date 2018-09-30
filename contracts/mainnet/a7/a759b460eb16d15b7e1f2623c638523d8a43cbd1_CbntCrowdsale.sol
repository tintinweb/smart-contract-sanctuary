pragma solidity ^0.4.24;

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

contract CbntCrowdsale is TimedCrowdsale, WhitelistedCrowdsale {
 using SafeMath for uint256;


 struct FutureTransaction{
   address beneficiary;
   uint256 num;
   uint32  times;
   uint256 lastTime;
 }
 FutureTransaction[] public futureTrans;
 uint256 public oweCbnt;

 uint256[] public rateSteps;
 uint256[] public rateStepsValue;
 uint32[] public regularTransTime;
 uint32 public transTimes;

 uint256 public minInvest;

/**
  * @param _openingTime Crowdsale opening time
  * @param _closingTime Crowdsale closing time
  * @param _rate Number of token units a buyer gets per wei
  * @param _wallet Address where collected funds will be forwarded to
  * @param _token Address of the token being sold
  */
 constructor(uint256 _openingTime, uint256 _closingTime, uint256 _rate, address _wallet, ERC20 _token) TimedCrowdsale(_openingTime,_closingTime) Crowdsale(_rate,_wallet, _token) public {
  // Crowdsale(uint256(1),_wallet, _token);
   //TimedCrowdsale(_openingTime,_closingTime);
 }

 /** external functions **/
 function triggerTransaction(uint256 beginIdx, uint256 endIdx) public returns (bool){
   uint32 regularTime = findRegularTime();
   require(regularTime > 0 && endIdx < futureTrans.length);

   bool bRemove = false;
   uint256 i = 0;
   for(i = beginIdx; i<=endIdx && i<futureTrans.length; ){
     bRemove = false;
     if(futureTrans[i].lastTime < regularTime){  // need to set the regularTime again when it comes late than the last regularTime
        uint256 transNum = futureTrans[i].num;
        address beneficiary = futureTrans[i].beneficiary;
        //update data

        futureTrans[i].lastTime = now;
        futureTrans[i].times = futureTrans[i].times - 1;
        require(futureTrans[i].times <= transTimes);

        // remove item if it is the last time transaction
        if(futureTrans[i].times ==0 ){
           bRemove = true;
           futureTrans[i].beneficiary = futureTrans[futureTrans.length -1].beneficiary;
           futureTrans[i].num = futureTrans[futureTrans.length -1].num;
           futureTrans[i].lastTime = futureTrans[futureTrans.length -1].lastTime;
           futureTrans[i].times = futureTrans[futureTrans.length -1].times;
           futureTrans.length = futureTrans.length.sub(1);
        }
           // transfer token
        oweCbnt = oweCbnt.sub(transNum);
        _deliverTokens(beneficiary, transNum);
     }

     if(!bRemove){
       i++;
     }
   }

   return true;

 }
 function transferBonus(address _beneficiary, uint256 _tokenAmount) public onlyOwner returns(bool){
   _deliverTokens(_beneficiary, _tokenAmount);
   return true;
 }

 // need to set this param before start business
 function setMinInvest(uint256 _minInvest) public onlyOwner returns (bool){
   minInvest = _minInvest;
   return true;
 }

 // need to set this param before start business
 function setTransTimes(uint32 _times) public onlyOwner returns (bool){
   transTimes = _times;
   return true;
 }

 function setRegularTransTime(uint32[] _times) public onlyOwner returns (bool){
   for (uint256 i = 0; i + 1 < _times.length; i++) {
       require(_times[i] < _times[i+1]);
   }

   regularTransTime = _times;
   return true;
 }

 // need to set this param before start business
 function setRateSteps(uint256[] _steps, uint256[] _stepsValue) public onlyOwner returns (bool){
   require(_steps.length == _stepsValue.length);
   for (uint256 i = 0; i + 1 < _steps.length; i++) {
       require(_steps[i] > _steps[i+1]);
   }

   rateSteps = _steps;
   rateStepsValue = _stepsValue;
   return true;
 }

 // need to check these params before start business
 function normalCheck() public view returns (bool){
   return (transTimes > 0 && regularTransTime.length > 0 && minInvest >0 && rateSteps.length >0);
 }

 function getFutureTransLength() public view returns(uint256) {
     return futureTrans.length;
 }
 function getFutureTransByIdx(uint256 _idx) public view returns(address,uint256, uint32, uint256) {
     return (futureTrans[_idx].beneficiary, futureTrans[_idx].num, futureTrans[_idx].times, futureTrans[_idx].lastTime);
 }
 function getFutureTransIdxByAddress(address _beneficiary) public view returns(uint256[]) {
     uint256 i = 0;
     uint256 num = 0;
     for(i=0; i<futureTrans.length; i++){
       if(futureTrans[i].beneficiary == _beneficiary){
           num++;
       }
     }
     uint256[] memory transList = new uint256[](num);

     uint256 idx = 0;
     for(i=0; i<futureTrans.length; i++){
       if(futureTrans[i].beneficiary == _beneficiary){
         transList[idx] = i;
         idx++;
       }
     }
     return transList;
 }

 /** internal functions **/
 /**
  * @dev Returns the rate of tokens per wei.
  * Note that, as price _increases_ with invest number, the rate _increases_.
  * @param _weiAmount The value in wei to be converted into tokens
  * @return The number of tokens a buyer gets per wei
  */
 function getCurrentRate(uint256 _weiAmount) public view returns (uint256) {
   for (uint256 i = 0; i < rateSteps.length; i++) {
       if (_weiAmount >= rateSteps[i]) {
           return rateStepsValue[i];
       }
   }
   return 0;
 }

 /**
  * @dev Overrides parent method taking into account variable rate.
  * @param _weiAmount The value in wei to be converted into tokens
  * @return The number of tokens _weiAmount wei will send at present time
  */
 function _getTokenAmount(uint256 _weiAmount)
   internal view returns (uint256)
 {
   uint256 currentRate = getCurrentRate(_weiAmount);
   return currentRate.mul(_weiAmount).div(transTimes);
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
 {
   require(msg.value >= minInvest);
   super._preValidatePurchase(_beneficiary, _weiAmount);
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
   // update the future transactions for future using.
   FutureTransaction memory tran = FutureTransaction(_beneficiary, _tokenAmount, transTimes-1, now); // the trtanstimes always lagger than 0
   futureTrans.push(tran);

   //update owe cbnt
   oweCbnt = oweCbnt.add(_tokenAmount.mul(tran.times));
   super._processPurchase(_beneficiary, _tokenAmount);
 }

 function findRegularTime() internal view returns (uint32) {
   if(now < regularTransTime[0]){
     return 0;
   }

   uint256 i = 0;
   while(i<regularTransTime.length && now >= regularTransTime[i]){
     i++;
   }

   return regularTransTime[i -1];

 }

}