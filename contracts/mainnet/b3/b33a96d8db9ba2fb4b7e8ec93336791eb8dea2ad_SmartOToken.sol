pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract Ownable {

  address public owner;
  function Ownable() public { owner = msg.sender; }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {owner = newOwner;}
}

contract ERC20Interface {

  function totalSupply() public constant returns (uint256);

  function balanceOf(address _owner) public constant returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);

  function allowance(address _owner, address _spender) public constant returns (uint256);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

 }

contract SmartOToken is Ownable, ERC20Interface {

  using SafeMath for uint256;

  /* Public variables of the token */
  string public constant name = "STO";
  string public constant symbol = "STO";
  uint public constant decimals = 18;
  uint256 public constant initialSupply = 12000000000 * 1 ether;
  uint256 public totalSupply;

  /* This creates an array with all balances */
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  /* Events */
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);

  /* Constuctor: Initializes contract with initial supply tokens to the creator of the contract */
  function SmartOToken() public {
      balances[msg.sender] = initialSupply;              // Give the creator all initial tokens
      totalSupply = initialSupply;                        // Update total supply
  }


  /* Implementation of ERC20Interface */

  function totalSupply() public constant returns (uint256) { return totalSupply; }

  function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }

  /* Internal transfer, only can be called by this contract */
  function _transfer(address _from, address _to, uint _amount) internal {
      require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
      require (balances[_from] >= _amount);                // Check if the sender has enough
      balances[_from] = balances[_from].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      Transfer(_from, _to, _amount);

  }

  function transfer(address _to, uint256 _amount) public returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require (_value <= allowed[_from][msg.sender]);     // Check allowance
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _amount) public returns (bool) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return allowed[_owner][_spender];
  }

}


contract Crowdsale is Ownable {

  using SafeMath for uint256;

  // The token being sold
  SmartOToken public token;

  // Flag setting that investments are allowed (both inclusive)
  bool public saleIsActive;

  // address where funds are collected
  address public wallet;

  // Number of tokents for 1 ETH, i.e. 683 tokens for 1 ETH
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  /* -----------   A D M I N        F U N C T I O N S    ----------- */

  function Crowdsale(uint256 _initialRate, address _targetWallet) public {

    //Checks
    require(_initialRate > 0);
    require(_targetWallet != 0x0);

    //Init
    token = new SmartOToken();
    rate = _initialRate;
    wallet = _targetWallet;
    saleIsActive = true;

  }

  function close() public onlyOwner {
    selfdestruct(owner);
  }

  //Transfer token to
  function transferToAddress(address _targetWallet, uint256 _tokenAmount) public onlyOwner {
    token.transfer(_targetWallet, _tokenAmount * 1 ether);
  }


  //Setters
  function enableSale() public onlyOwner {
    saleIsActive = true;
  }

  function disableSale() public onlyOwner {
    saleIsActive = false;
  }

  function setRate(uint256 _newRate) public onlyOwner {
    rate = _newRate;
  }


  /* -----------   P U B L I C      C A L L B A C K       F U N C T I O N     ----------- */

  function () public payable {

    require(msg.sender != 0x0);
    require(saleIsActive);
    require(msg.value >= 0.1 * 1 ether);

    uint256 weiAmount = msg.value;

    //Update total wei counter
    weiRaised = weiRaised.add(weiAmount);

    //Calc number of tokents
    uint256 tokenAmount = weiAmount.mul(rate);

    //Forward wei to wallet account
    wallet.transfer(weiAmount);

    //Transfer token to sender
    token.transfer(msg.sender, tokenAmount);
    TokenPurchase(msg.sender, wallet, weiAmount, tokenAmount);

  }



}