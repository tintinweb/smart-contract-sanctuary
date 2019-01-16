pragma  solidity ^0.4.24;

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

contract Ownable{
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
    
}

library Locklist {
  
  struct List {
    mapping(address => bool) registry;
  }
  
  function add(List storage list, address _addr)
    internal
  {
    list.registry[_addr] = true;
  }

  function remove(List storage list, address _addr)
    internal
  {
    list.registry[_addr] = false;
  }

  function check(List storage list, address _addr)
    view
    internal
    returns (bool)
  {
    return list.registry[_addr];
  }
}



contract Locklisted  {

  Locklist.List private _list;
  
  modifier onlyLocklisted() {
    require(Locklist.check(_list, msg.sender) == true);
    _;
  }

  event AddressAdded(address _addr);
  event AddressRemoved(address _addr);
  
  function LocklistedAddress()
  public
  {
    Locklist.add(_list, msg.sender);
  }

  function LocklistAddressenable(address _addr)
    public
  {
    Locklist.add(_list, _addr);
    emit AddressAdded(_addr);
  }

  function LocklistAddressdisable(address _addr)
    public
  {
    Locklist.remove(_list, _addr);
   emit AddressRemoved(_addr);
  }
  
  function LocklistAddressisListed(address _addr)
  public
  view
  returns (bool)
  {
      return Locklist.check(_list, _addr);
  }
}

contract Fortune is Ownable,Locklisted {
 
  // event Mint(address indexed to, uint256 amount);
  // event MintFinished();

  event Transfer(address indexed from, address indexed to, uint256 value);
  using SafeMath for uint256;
  string public constant name = "Fortune";
  string public constant symbol = "FRT";
  uint8 public constant decimals = 5;  // 18 is the most common number of decimal places
  uint256 public totalSupply = 2000000000 * 10 ** uint256(decimals);
  uint256 public tokentransfered;
  mapping(address => uint256) balances;


  constructor() public {
    balances[msg.sender] = totalSupply;
  }

   

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function balanceEth(address _owner) public constant returns (uint256 balance) {
    return _owner.balance;
  }


  // modifier canMint() {
  //   require(!mintingFinished);
  //   _;
  // }
 
  // /**
  // * @dev Function to mint tokens
  // * @param _to The address that will receive the minted tokens.
  // * @param _amount The amount of tokens to mint.
  // * @return A boolean that indicates if the operation was successful.
  // */
  // function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
  //   require(!LocklistAddressisListed(_to));
  //   totalSupply = totalSupply.add(_amount);
  //   require(totalSupply <= 10000000000000);
  //   balances[_to] = balances[_to].add(_amount);
  //   emit  Mint(_to, _amount);
  //   emit Transfer(address(0), _to, _amount);

  //   return true;
  // }

  // /**
  // * @dev Function to stop minting new tokens.
  // * @return True if the operation was successful.
  // */
  // function finishMinting() onlyOwner canMint public returns (bool) {
  //   mintingFinished = true;
  //   emit MintFinished();
  //   return true;
  // }
 
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= totalSupply);
    require(!LocklistAddressisListed(_to));
      balances[_to] = balances[_to].add(_value);
      totalSupply = totalSupply.sub(_value);
      tokentransfered = tokentransfered.add(_value);
      balances[msg.sender] = balances[msg.sender].sub(_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
  }
 
 
  function transferFrom(address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
    require(!LocklistAddressisListed(_to));
    require(_to != address(0));
    require(_value <= balances[_from]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
 
 
 


  


  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    balances[newOwner] = balances[owner];
    balances[owner] = 0;
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }
    

}