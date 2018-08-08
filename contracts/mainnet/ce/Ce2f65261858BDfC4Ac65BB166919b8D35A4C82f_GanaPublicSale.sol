pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}


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


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {

  uint256 public totalSupply;
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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


contract Releasable is Ownable {

  event Release();

  bool public released = false;

  modifier afterReleased() {
    require(released);
    _;
  }

  function release() onlyOwner public {
    require(!released);
    released = true;
    Release();
  }

}


contract Managed is Releasable {

  mapping (address => bool) public manager;
  event SetManager(address _addr);
  event UnsetManager(address _addr);

  function Managed() public {
    manager[msg.sender] = true;
  }

  modifier onlyManager() {
    require(manager[msg.sender]);
    _;
  }

  function setManager(address _addr) public onlyOwner {
    require(_addr != address(0) && manager[_addr] == false);
    manager[_addr] = true;

    SetManager(_addr);
  }

  function unsetManager(address _addr) public onlyOwner {
    require(_addr != address(0) && manager[_addr] == true);
    manager[_addr] = false;

    UnsetManager(_addr);
  }

}


contract ReleasableToken is StandardToken, Managed {

  function transfer(address _to, uint256 _value) public afterReleased returns (bool) {
    return super.transfer(_to, _value);
  }

  function saleTransfer(address _to, uint256 _value) public onlyManager returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public afterReleased returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public afterReleased returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public afterReleased returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public afterReleased returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}


contract BurnableToken is ReleasableToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) onlyManager public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= tota0lSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

}


/**
  *  GANA
  */
contract GANA is BurnableToken {

  string public constant name = "GANA";
  string public constant symbol = "GANA";
  uint8 public constant decimals = 18;

  event ClaimedTokens(address manager, address _token, uint256 claimedBalance);

  function GANA() public {
    totalSupply = 2000000000 * 1 ether;
    balances[msg.sender] = totalSupply;
  }

  function claimTokens(address _token, uint256 _claimedBalance) public onlyManager afterReleased {
    ERC20Basic token = ERC20Basic(_token);
    uint256 tokenBalance = token.balanceOf(this);
    require(tokenBalance >= _claimedBalance);

    address manager = msg.sender;
    token.transfer(manager, _claimedBalance);
    ClaimedTokens(manager, _token, _claimedBalance);
  }

}


/**
  *  Whitelist contract
  */
contract Whitelist is Ownable {

   mapping (address => bool) public whitelist;
   event Registered(address indexed _addr);
   event Unregistered(address indexed _addr);

   modifier onlyWhitelisted(address _addr) {
     require(whitelist[_addr]);
     _;
   }

   function isWhitelist(address _addr) public view returns (bool listed) {
     return whitelist[_addr];
   }

   function registerAddress(address _addr) public onlyOwner {
     require(_addr != address(0) && whitelist[_addr] == false);
     whitelist[_addr] = true;
     Registered(_addr);
   }

   function registerAddresses(address[] _addrs) public onlyOwner {
     for(uint256 i = 0; i < _addrs.length; i++) {
       require(_addrs[i] != address(0) && whitelist[_addrs[i]] == false);
       whitelist[_addrs[i]] = true;
       Registered(_addrs[i]);
     }
   }

   function unregisterAddress(address _addr) public onlyOwner onlyWhitelisted(_addr) {
       whitelist[_addr] = false;
       Unregistered(_addr);
   }

   function unregisterAddresses(address[] _addrs) public onlyOwner {
     for(uint256 i = 0; i < _addrs.length; i++) {
       require(whitelist[_addrs[i]]);
       whitelist[_addrs[i]] = false;
       Unregistered(_addrs[i]);
     }
   }

}


/**
  *  GANA PUBLIC-SALE
  */
contract GanaPublicSale is Ownable {
  using SafeMath for uint256;

  GANA public gana;
  Whitelist public whitelist;
  address public wallet;
  uint256 public hardCap   = 30000 ether; //publicsale cap
  uint256 public weiRaised = 0;
  uint256 public defaultRate = 20000;

  //uint256 public startTime = 1483228800; //TEST ONLY UTC 01/01/2017 00:00am
  uint256 public startTime = 1524218400; //UTC 04/20/2018 10:00am
  uint256 public endTime   = 1526637600; //UTC 05/18/2018 10:00am

  event TokenPurchase(address indexed sender, address indexed buyer, uint256 weiAmount, uint256 ganaAmount);
  event Refund(address indexed buyer, uint256 weiAmount);
  event TransferToSafe();
  event BurnAndReturnAfterEnded(uint256 burnAmount, uint256 returnAmount);

  function GanaPublicSale(address _gana, address _wallet, address _whitelist) public {
    require(_wallet != address(0));
    gana = GANA(_gana);
    whitelist = Whitelist(_whitelist);
    wallet = _wallet;
  }

  modifier onlyWhitelisted() {
    require(whitelist.isWhitelist(msg.sender));
    _;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyGana(msg.sender);
  }

  function buyGana(address buyer) public onlyWhitelisted payable {
    require(!hasEnded());
    require(afterStart());
    require(buyer != address(0));
    require(msg.value > 0);
    require(buyer == msg.sender);

    uint256 weiAmount = msg.value;
    //pre-calculate wei raise after buying
    uint256 preCalWeiRaised = weiRaised.add(weiAmount);
    uint256 ganaAmount;
    uint256 rate = getRate();

    if(preCalWeiRaised <= hardCap){
      //the pre-calculate wei raise is less than the hard cap
      ganaAmount = weiAmount.mul(rate);
      gana.saleTransfer(buyer, ganaAmount);
      weiRaised = preCalWeiRaised;
      TokenPurchase(msg.sender, buyer, weiAmount, ganaAmount);
    }else{
      //the pre-calculate weiRaised is more than the hard cap
      uint256 refundWeiAmount = preCalWeiRaised.sub(hardCap);
      uint256 fundWeiAmount =  weiAmount.sub(refundWeiAmount);
      ganaAmount = fundWeiAmount.mul(rate);
      gana.saleTransfer(buyer, ganaAmount);
      weiRaised = weiRaised.add(fundWeiAmount);
      TokenPurchase(msg.sender, buyer, fundWeiAmount, ganaAmount);
      buyer.transfer(refundWeiAmount);
      Refund(buyer,refundWeiAmount);
    }
  }

  function getRate() public view returns (uint256) {
    if(weiRaised < 12500 ether){
      return 21000;
    }else if(weiRaised < 25000 ether){
      return 20500;
    }else{
      return 20000;
    }
  }

  //Was it sold out or sale overdue
  function hasEnded() public view returns (bool) {
    bool hardCapReached = weiRaised >= hardCap; // balid cap
    return hardCapReached || afterEnded();
  }

  function afterEnded() internal constant returns (bool) {
    return now > endTime;
  }

  function afterStart() internal constant returns (bool) {
    return now >= startTime;
  }

  function transferToSafe() onlyOwner public {
    require(hasEnded());
    wallet.transfer(this.balance);
    TransferToSafe();
  }

  /**
  * @dev burn unsold token and return bonus token
  * @param reserveWallet reserve pool address
  */
  function burnAndReturnAfterEnded(address reserveWallet) onlyOwner public {
    require(reserveWallet != address(0));
    require(hasEnded());
    uint256 unsoldWei = hardCap.sub(weiRaised);
    uint256 ganaBalance = gana.balanceOf(this);
    require(ganaBalance > 0);

    if(unsoldWei > 0){
      //Burn unsold and return bonus
      uint256 unsoldGanaAmount = ganaBalance;
      uint256 burnGanaAmount = unsoldWei.mul(defaultRate);
      uint256 bonusGanaAmount = unsoldGanaAmount.sub(burnGanaAmount);
      gana.burn(burnGanaAmount);
      gana.saleTransfer(reserveWallet, bonusGanaAmount);
      BurnAndReturnAfterEnded(burnGanaAmount, bonusGanaAmount);
    }else{
      //All tokens were sold. return bonus
      gana.saleTransfer(reserveWallet, ganaBalance);
      BurnAndReturnAfterEnded(0, ganaBalance);
    }
  }

  /**
  * @dev emergency function before sale
  * @param returnAddress return token address
  */
  function returnGanaBeforeSale(address returnAddress) onlyOwner public {
    require(returnAddress != address(0));
    require(weiRaised == 0);
    uint256 returnGana = gana.balanceOf(this);
    gana.saleTransfer(returnAddress, returnGana);
  }

}