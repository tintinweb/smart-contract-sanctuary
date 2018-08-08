pragma solidity ^0.4.18;

contract ERC20 {

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);

    // Stateless functions
    function totalSupply() constant public returns (uint256 supply);
    function balanceOf( address who ) constant public returns (uint256 value);
    function allowance(address owner, address spender) constant public returns (uint value);

    // Stateful functions
    function transfer( address to, uint256 value) public returns (bool success);
    function transferFrom( address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);

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



/**
 * @title SafeMath
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
    uint256 c = a / b;
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
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;
  
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist 
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      WhitelistedAddressAdded(addr);
      success = true; 
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist, 
   * false if all addresses were already in the whitelist  
   */
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist, 
   * false if the address wasn&#39;t in the whitelist in the first place 
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist, 
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

contract TalentCoin is ERC20, Ownable, Whitelist, Pausable{
  
  using SafeMath for uint256;

  mapping (address => bool) admins;  // Mapping of who is an admin
  mapping( address => uint256 ) balances;
  mapping( address => mapping( address => uint256 ) ) approvals;
  mapping( address => uint256 ) ratemapping;
  //How much ETH each address has invested
  mapping (address => uint) public investedAmountOf;
  address public owner;
  address public walletAddress;
  uint256 public supply;
  string public name;
  uint256 public decimals;
  string public symbol;
  uint256 public rate;
  uint public weiRaised;
  uint public soldTokens;
  uint public investorCount;
  

  function TalentCoin(address _walletAddress, uint256 _supply, string _name, uint256 _decimals, string _symbol, uint256 _rate ) public {
    require(_walletAddress != 0x0);
    balances[msg.sender] = _supply;
    ratemapping[msg.sender] = _rate;
    supply = _supply;
    name = _name;
    decimals = _decimals;
    symbol = _symbol;
    rate = _rate;
    owner = msg.sender;
    admins[msg.sender] = true;
    walletAddress = _walletAddress;
  }
  
    function () external payable {
        createTokens();
    }
    
    function createTokens() public payable onlyWhitelisted() whenNotPaused(){
    require(msg.value >0);
    if (investedAmountOf[msg.sender] == 0) {
            investorCount++;
        }
    uint256 tokens = msg.value.mul(rate);  
    require(supply >= tokens && balances[owner] >= tokens);
    balances[msg.sender] = balances[msg.sender].add(tokens);
    balances[owner] = balances[owner].sub(tokens); 
    walletAddress.transfer(msg.value); 
    Transfer(owner, msg.sender, tokens);
    investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(msg.value);
    weiRaised = weiRaised.add(msg.value);
    soldTokens = soldTokens.add(tokens);
    }
    
  function totalSupply() constant public returns (uint) {
    return supply;
  }

  function balanceOf( address _who ) constant public returns (uint) {
    return balances[_who];
  }

  function transfer( address _to, uint256 _value) onlyWhitelisted() public returns (bool success) {
    if (investedAmountOf[_to] == 0) {
        investorCount++;
    }
    require(_to != 0x0);
    require(balances[msg.sender] >= _value && _value > 0 && supply >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer( msg.sender, _to, _value );
    soldTokens = soldTokens.add(_value);
    return true;
  }

  function transferFrom( address _from, address _to, uint256 _value) onlyWhitelisted() public returns (bool success) {
    require(_from != 0x0 && _to != 0x0);
    require(approvals[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
    approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer( _from, _to, _value );
    soldTokens = soldTokens.add(_value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool ok) {
    require(_spender != 0x0);
    approvals[msg.sender][_spender] = _value;
    Approval( msg.sender, _spender, _value );
    return true;
  }

  function allowance(address _owner, address _spender) constant public returns (uint) {
    return approvals[_owner][_spender];
  }

  function increaseSupply(uint256 _value, address _to) onlyOwner() public returns(bool success) {
    require(_to != 0x0);
    supply = supply.add(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(0, _to, _value);
    return true;
  }

  function decreaseSupply(uint256 _value, address _from) onlyOwner() public returns(bool success) {
    require(_from != 0x0);
    balances[_from] = balances[_from].sub(_value);
    supply = supply.sub(_value);
    Transfer(_from, 0, _value);
    return true;
  }

  function increaseRate(uint256 _value, address _to) onlyOwner() public returns(bool success) {
    require(_to != 0x0);
    rate = rate.add(_value);
    ratemapping[_to] = ratemapping[_to].add(_value);
    Transfer(0, _to, _value);
    return true;
  }

  function decreaseRate(uint256 _value, address _from) onlyOwner() public returns(bool success) {
    require(_from != 0x0);
    ratemapping[_from] = ratemapping[_from].sub(_value);
    rate = rate.sub(_value);
    Transfer(_from, 0, _value);
    return true;
  }
  
  function increaseApproval (address _spender, uint _addedValue) onlyOwner() public returns (bool success) {
    approvals[msg.sender][_spender] = approvals[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, approvals[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) onlyOwner() public returns (bool success) {
    uint oldValue = approvals[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      approvals[msg.sender][_spender] = 0;
    } else {
      approvals[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, approvals[msg.sender][_spender]);
    return true;
  }

}