pragma solidity ^0.4.13;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract Ownable {
  address public owner;


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Crowdsale is Ownable {
  using SafeMath for uint256;

  ERC20 public token;

  // How many wei units a buyer gets per token
  uint256 public price;

  // Minimum wei
  uint256 public weiMinimum;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  bool public isFinalized = false;

  event Finalized();

  /**
   * @param _token Address of the token being sold
   * @param _price How many wei units a buyer gets per token
   * @param _minimum Minimal wei per transaction
   */
  constructor(ERC20 _token, uint256 _price, uint256 _minimum) public {
    require(_token != address(0));
    require(_price > 0);
    require(_minimum >= 0);
    token = _token;
    price = _price;
    weiMinimum = _minimum * (10 ** 18);
  }

  /**
   * Crowdsale token purchase logic
   */
  function () external payable {
    require(!isFinalized);

    address beneficiary = msg.sender;
    uint256 weiAmount = msg.value;

    require(beneficiary != address(0));
    require(weiAmount != 0);
    require(weiAmount >= weiMinimum);

    uint256 tokens = weiAmount.div(price);
    uint256 selfBalance = balance();
    require(tokens > 0);
    require(tokens <= selfBalance);

    // Get tokens to beneficiary
    token.transfer(beneficiary, tokens);

    emit TokenPurchase(
      beneficiary,
      weiAmount,
      tokens
    );

    // Transfet eth to owner
    owner.transfer(msg.value);

    // update state
    weiRaised = weiRaised.add(weiAmount);
  }


  /**
   * Self tokken ballance
   */
  function balance() public view returns (uint256) {
    address self = address(this);
    uint256 selfBalance = token.balanceOf(self);
    return selfBalance;
  }

  /**
   * Set new price
   * @param _price How many wei units a buyer gets per token
   */
  function setPrice(uint256 _price) onlyOwner public {
    require(_price > 0);
    price = _price;
  }

  /**
   * Set new minimum
   * @param _minimum Minimal wei per transaction
   */
  function setMinimum(uint256 _minimum) onlyOwner public {
    require(_minimum >= 0);
    weiMinimum = _minimum * (10 ** 18);
  }

  /**
   * Must be called after crowdsale ends, to do some extra finalization work.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);

    transferBallance();

    emit Finalized();
    isFinalized = true;
  }

  /**
   * Send all token ballance to owner
   */
  function transferBallance() onlyOwner public {
    uint256 selfBalance = balance();
    token.transfer(msg.sender, selfBalance);
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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