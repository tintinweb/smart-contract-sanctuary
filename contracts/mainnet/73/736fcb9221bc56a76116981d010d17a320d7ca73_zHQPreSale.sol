pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // how many token units a buyer gets per wei
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

  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate) {
    require(_endTime >= _startTime);
    require(_rate > 0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;

  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(msg.value >= 0.5 ether);

    uint256 weiAmount = msg.value;


    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract zHQPreSale is Crowdsale, Ownable {

  // number of participants in the SelfPay Pre-Sale
  uint256 public numberOfPurchasers = 0;

  //Who bought for how much
  mapping(address => uint256) bought;

  // Total zHQ
  uint256 public zHQNumber = 0;

  // Ensure the gold level bonus can only be used once
  bool public goldLevelBonusIsUsed = false;

  address dev;
  address public owner;

  function zHQPreSale()
    Crowdsale(1506837600, 1606837600, 300) public
  {
    // As goal needs to be met for a successful crowdsale the value needs to be less
    // than or equal than a cap which is limit for accepted funds
    owner = msg.sender;
    dev = msg.sender;

  }

  //Need to update sale params after publish because of UI bug
  //TODO: maybe get this reviewed by Josh
  function configSale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap) public {
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;

    owner = msg.sender;
  }

  //Refund when something goes wrong

  function refund(address _buyer, uint _weiAmount) onlyOwner public {
    if(msg.sender == owner) {
      if(bought[_buyer] > 0) {
        _buyer.send(_weiAmount);
        bought[_buyer] = bought[_buyer] - _weiAmount;
      }
    }
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(msg.value >= 0.5 ether);

    uint256 weiAmount = msg.value;

    bought[beneficiary] += weiAmount;
    // Calculate the number of tokens
    uint256 tokens = weiAmount.mul(rate);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    numberOfPurchasers = numberOfPurchasers + 1;
    zHQNumber = zHQNumber.add(tokens);

  }

  //end of sale withdrawl
  //don&#39;t keep our junk on blockchain
  function withdraw() public {
    if(msg.sender == dev) {
      selfdestruct(msg.sender);
    }
  }


}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20Basic, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


}


contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract zHQToken is MintableToken {
    string public constant name = "zHQ Token";
    string public constant symbol = "zHQ";
    uint256 public decimals = 18;

    /**
     * @dev Allows anyone to transfer the zHQ Token tokens once trading has started
     * @param _to the recipient address of the tokens.
     * @param _value number of tokens to be transfered.
     */
    function transfer(address _to, uint _value) public returns (bool){
        return super.transfer(_to, _value);
    }

}