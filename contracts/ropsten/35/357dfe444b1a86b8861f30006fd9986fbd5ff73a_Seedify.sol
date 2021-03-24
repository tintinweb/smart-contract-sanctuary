/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-23
*/

pragma solidity ^ 0.4 .19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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

contract ERC20 {
  uint256 public totalSupply;

  function balanceOf(address who) public constant returns(uint256);

  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function allowance(address owner, address spender) public constant returns(uint256);

  function transferFrom(address from, address to, uint256 value) public returns(bool);

  function approve(address spender, uint256 value) public returns(bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract BasicToken is ERC20 {
  using SafeMath
  for uint256;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  modifier nonZeroEth(uint _value) {
    require(_value > 0);
    _;
  }

  modifier onlyPayloadSize() {
    require(msg.data.length >= 68);
    _;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Allocate(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */

  function transfer(address _to, uint256 _value) public nonZeroEth(_value) onlyPayloadSize returns(bool) {
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */

  function transferFrom(address _from, address _to, uint256 _value) public nonZeroEth(_value) onlyPayloadSize returns(bool) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      uint256 _allowance = allowed[_from][msg.sender];
      allowed[_from][msg.sender] = _allowance.sub(_value);
      balances[_to] = balances[_to].add(_value);
      balances[_from] = balances[_from].sub(_value);
      Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */

  function balanceOf(address _owner) public constant returns(uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns(bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Seedify is BasicToken, Ownable {

  using SafeMath
  for uint256;
  //token attributes

  string public name = "Seedify"; //name of the token

  string public symbol = "SDF"; // symbol of the token

  uint8 public decimals = 18; // decimals

  uint256 public totalSupply = 220000000 * 10 ** uint256(decimals); // total supply of SDF Tokens

  uint256 private decimalFactor = 10 ** uint256(decimals);

  uint public maxCap = 1 * 10 ** 6;
  uint256 public tokeSaleStartTime;
  uint256 public tokenSaleEndTime;
  uint256 ethPrice = 1800; // in usd
  uint256 tokenPrice = 25; // 0.25 cent
  bool public isTokenSaleActive = false; // Flag to track the TokenSale active or not
  enum State {
    TokenSale
  }
  event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
  ///////////////////////////////////////// CONSTRUCTOR for Distribution //////////////////////////////////////////////////

  function Seedify() public {
    balances[msg.sender] = totalSupply;
  }

  // Returns current token Owner
  function tokenOwner() public view returns(address) {
    return owner;
  }

  // token transfer.
  function transfer(address _to, uint _value) public returns(bool success) {
    return super.transfer(_to, _value);
  }

  // transferFrom
  function transferFrom(address _from, address _to, uint _value) public returns(bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  // startTokenSale function use to start the TokenSale at the calling function time
  // _days No. of days to which TokenSale get active
  // return bool

  function startTokenSale(uint8 _days) public
  onlyOwner
  returns(bool) {
    tokeSaleStartTime = now;
    tokenSaleEndTime = tokeSaleStartTime + _days * 1 days;
    isTokenSaleActive = !isTokenSaleActive;
    return true;
  }

  // it transfers the remaining tokens to owner address
  function endTokenSale() public onlyOwner returns(bool) {
    if (isTokenSaleActive = true) {
      isTokenSaleActive = false;
      tokenSaleEndTime = now;
      return true;
    }
    return false;
  }

  // function to get the current state of the token sale
  function getState() internal constant returns(State) {
    if (isTokenSaleActive) {
      return State.TokenSale;
    }
  }
  // setEthPrice
  function setEthPrice(uint256 value)
  external
  onlyOwner {
    ethPrice = value;
  }
  //calculate tokens
  function calcToken(uint256 value)
  public view
  returns(uint256 amount) {
    amount = ethPrice.mul(100).mul(value).div(tokenPrice);
    return amount;
  }
  // Buy token function call only in duration of TokenSale active 
  function buyTokens(address beneficiary) public payable returns(bool) {
    if (isTokenSaleActive = true) {
     // require(now > tokeSaleStartTime);
      //require(now < tokenSaleEndTime);
      fundTransfer(msg.value);
      uint256 amount = calcToken(msg.value);

    //   if (transfer(beneficiary, amount)) {
    //   TokenPurchase(beneficiary, msg.value, amount);
    //   }
      return true;
    } else {
      revert();
    }

  }
//   function buyTokens(address beneficiary) public payable { 
// uint256 _amount = msg.value; 
// require(_receiver != address(0)); require(_amount > 0); 
// uint256 tokensToBuy = multiply(_amount, (10 * decimals)) / 1 ether tokenPrice;
// require(tokenContract.transfer(_receiver, tokensToBuy)); 
// tokensSold += _amount; 

// emit Sell(msg.sender, tokensToBuy); }
  

  // function to transfer the funds to founders account
  function fundTransfer(uint256 weiAmount) internal {
    owner.transfer(weiAmount);
  }

  // send ether to the contract address
  function () public payable {
    buyTokens(msg.sender);
  }
}